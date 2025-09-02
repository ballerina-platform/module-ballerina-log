/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.log;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.IdentifierUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BFunctionPointer;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTable;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Date;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

    // Cache frequently used BString constants to avoid repeated allocations
    private static final BString STRATEGY_KEY = StringUtils.fromString("strategy");
    private static final BString REPLACEMENT_KEY = StringUtils.fromString("replacement");
    private static final BString EXCLUDE_VALUE = StringUtils.fromString("EXCLUDE");
    private static final String FIELD_PREFIX = "$field$.";
    private static final String LOG_ANNOTATION_PREFIX = "ballerina/log";
    private static final String SENSITIVE_DATA_SUFFIX = ":SensitiveData";

    // Cache error message to avoid repeated BString creation
    private static final BString CYCLIC_REFERENCE_ERROR = StringUtils.fromString("Cyclic value reference detected in the record");

    // Cache for SimpleDateFormat to avoid creating new instances (thread-safe)
    private static final ThreadLocal<SimpleDateFormat> DATE_FORMAT =
        ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX"));

    private Utils() {

    }

    /**
     * Get the name of the current module.
     *
     * @return module name
     */
    public static BString getModuleNameExtern() {
        String className = Thread.currentThread().getStackTrace()[5].getClassName();
        String[] pkgData = className.split("\\.");
        if (pkgData.length > 1) {
            String module = IdentifierUtils.decodeIdentifier(pkgData[1]);
            return StringUtils.fromString(pkgData[0] + "/" + module);
        }
        return StringUtils.fromString(".");
    }

    /**
     * Get the current local time.
     *
     * @return current local time in RFC3339 format
     */
    public static BString getCurrentTime() {
        return StringUtils.fromString(DATE_FORMAT.get().format(new Date()));
    }

    public static BString getMaskedString(Environment env, Object value) {
        // Use IdentityHashMap for much better memory efficiency
        // Only stores identity-based references, not hash-based ones
        IdentityHashMap<Object, Boolean> visitedValues = new IdentityHashMap<>();
        return StringUtils.fromString(getMaskedStringInternal(env.getRuntime(), value, visitedValues));
    }

    static String getMaskedStringInternal(Runtime runtime, Object value, IdentityHashMap<Object, Boolean> visitedValues) {
        if (isBasicType(value)) {
            return StringUtils.getStringValue(value);
        }

        // Use identity-based checking instead of hash-based
        if (visitedValues.put(value, Boolean.TRUE) != null) {
            throw ErrorCreator.createError(CYCLIC_REFERENCE_ERROR);
        }

        try {
            return processValue(runtime, value, visitedValues);
        } finally {
            visitedValues.remove(value);
        }
    }

    private static String processValue(Runtime runtime, Object value, IdentityHashMap<Object, Boolean> visitedValues) {
        Type type = TypeUtils.getType(value);

        // Use switch-like pattern for better performance
        return switch (value) {
            case BMap<?, ?> mapValue -> processMapValue(runtime, mapValue, type, visitedValues);
            case BTable<?, ?> tableValue -> processTableValue(runtime, tableValue, visitedValues);
            case BArray listValue -> processArrayValue(runtime, listValue, visitedValues);
            default -> StringUtils.getStringValue(value);
        };
    }

    private static String processMapValue(Runtime runtime, BMap<?, ?> mapValue, Type valueType, IdentityHashMap<Object, Boolean> visitedValues) {
        if (valueType.getTag() != TypeTags.RECORD_TYPE_TAG) {
            // For non-record maps, use default string representation
            return StringUtils.getStringValue(mapValue);
        }

        RecordType recType = (RecordType) valueType;
        Map<String, Field> fields = recType.getFields();
        if (fields.isEmpty()) {
            return "{}";
        }

        // More conservative and safer capacity estimation
        // Use adaptive sizing based on actual field count with reasonable bounds
        int fieldCount = fields.size();
        int baseCapacity = fieldCount <= 5 ? 64 :
                          fieldCount <= 20 ? 256 :
                          Math.min(fieldCount * 15, 2048); // Cap at 2KB for very large objects

        StringBuilder maskedString = new StringBuilder(baseCapacity);
        maskedString.append('{');

        Map<String, BMap<?, ?>> fieldAnnotations = extractFieldAnnotations(recType);
        boolean first = true;

        for (Map.Entry<String, Field> entry : fields.entrySet()) {
            String fieldName = entry.getKey();
            Object fieldValue = mapValue.get(StringUtils.fromString(fieldName));

            if (fieldValue == null) {
                continue;
            }

            Optional<BMap<?, ?>> annotation = getLogSensitiveDataAnnotation(fieldAnnotations, fieldName);
            Optional<String> fieldStringValue;

            if (annotation.isPresent()) {
                fieldStringValue = getStringValue(annotation.get(), fieldValue, runtime);
            } else {
                fieldStringValue = Optional.of(getMaskedStringInternal(runtime, fieldValue, visitedValues));
            }

            if (fieldStringValue.isPresent()) {
                if (!first) {
                    maskedString.append(',');
                }
                appendFieldToJson(maskedString, fieldName, fieldStringValue.get(),
                                annotation.isPresent(), fieldValue);
                first = false;
            }
        }

        maskedString.append('}');
        return maskedString.toString();
    }

    private static void appendFieldToJson(StringBuilder sb, String fieldName, String value,
                                        boolean hasAnnotation, Object fieldValue) {
        sb.append('"').append(fieldName).append("\":");
        if (hasAnnotation || fieldValue instanceof BString) {
            sb.append('"').append(value).append('"');
        } else {
            sb.append(value);
        }
    }

    private static String processTableValue(Runtime runtime, BTable<?, ?> tableValue, IdentityHashMap<Object, Boolean> visitedValues) {
        Collection<?> values = tableValue.values();
        if (values.isEmpty()) {
            return "[]";
        }

        // Safer capacity estimation with bounds checking
        int valueCount = values.size();
        int baseCapacity = valueCount <= 10 ? 128 :
                          valueCount <= 100 ? 512 :
                          Math.min(valueCount * 20, 4096); // Cap at 4KB

        StringBuilder tableString = new StringBuilder(baseCapacity);
        tableString.append('[');

        boolean first = true;
        for (Object row : values) {
            if (!first) {
                tableString.append(',');
            }
            appendValueToArray(tableString, getMaskedStringInternal(runtime, row, visitedValues), row);
            first = false;
        }

        tableString.append(']');
        return tableString.toString();
    }

    private static String processArrayValue(Runtime runtime, BArray listValue, IdentityHashMap<Object, Boolean> visitedValues) {
        long length = listValue.getLength();
        if (length == 0) {
            return "[]";
        }

        // Safe capacity calculation with overflow protection
        int safeLength = length > Integer.MAX_VALUE / 20 ? Integer.MAX_VALUE / 20 : (int) length;
        int baseCapacity = safeLength <= 20 ? 96 :
                          safeLength <= 200 ? 384 :
                          Math.min(safeLength * 12, 3072); // Cap at 3KB

        StringBuilder arrayString = new StringBuilder(baseCapacity);
        arrayString.append('[');

        for (long i = 0; i < length; i++) {
            if (i > 0) {
                arrayString.append(',');
            }
            Object element = listValue.get(i);
            String elementString = getMaskedStringInternal(runtime, element, visitedValues);
            appendValueToArray(arrayString, elementString, element);
        }

        arrayString.append(']');
        return arrayString.toString();
    }

    private static void appendValueToArray(StringBuilder sb, String value, Object originalValue) {
        if (originalValue instanceof BString) {
            sb.append('"').append(value).append('"');
        } else {
            sb.append(value);
        }
    }

    static boolean isBasicType(Object value) {
        return value == null || TypeUtils.getType(value).getTag() <= TypeTags.BOOLEAN_TAG;
    }

    static Optional<BMap<?, ?>> getLogSensitiveDataAnnotation(Map<String, BMap<?, ?>> fieldAnnotations, String fieldName) {
        BMap<?, ?> fieldAnnotationMap = fieldAnnotations.get(fieldName);
        if (fieldAnnotationMap == null) {
            return Optional.empty();
        }

        // Cache the keys array to avoid repeated calls
        Object[] keys = fieldAnnotationMap.getKeys();

        // Optimized search - most annotation maps are small, so linear search is efficient
        for (Object key : keys) {
            if (key instanceof BString bStringKey) {
                String keyValue = bStringKey.getValue();
                // Use more efficient string matching - check suffix first (likely to fail faster)
                if (keyValue.endsWith(SENSITIVE_DATA_SUFFIX) && keyValue.startsWith(LOG_ANNOTATION_PREFIX)) {
                    Object annotation = fieldAnnotationMap.get(key);
                    if (annotation instanceof BMap<?, ?> bMapAnnotation) {
                        return Optional.of(bMapAnnotation);
                    }
                    // Found the target annotation type, no need to continue
                    break;
                }
            }
        }
        return Optional.empty();
    }

    static Map<String, BMap<?, ?>> extractFieldAnnotations(RecordType recordType) {
        BMap<BString, Object> annotations = recordType.getAnnotations();
        if (annotations == null) {
            return Map.of();
        }

        // Use more efficient stream processing
        return annotations.entrySet().stream()
                .filter(entry -> {
                    String keyValue = entry.getKey().getValue();
                    return keyValue.startsWith(FIELD_PREFIX) && entry.getValue() instanceof BMap;
                })
                .collect(Collectors.toMap(
                        entry -> entry.getKey().getValue().substring(FIELD_PREFIX.length()),
                        entry -> (BMap<?, ?>) entry.getValue(),
                        (existing, replacement) -> existing // Handle potential duplicates
                ));
    }

    static Optional<String> getStringValue(BMap<?, ?> annotation, Object realValue, Runtime runtime) {
        Object strategy = annotation.get(STRATEGY_KEY);
        if (strategy instanceof BString strategyStr && EXCLUDE_VALUE.getValue().equals(strategyStr.getValue())) {
            return Optional.empty();
        }
        if (strategy instanceof BMap<?, ?> replacementMap) {
            Object replacement = replacementMap.get(REPLACEMENT_KEY);
            if (replacement instanceof BString replacementStr) {
                return Optional.of(replacementStr.getValue());
            }
            if (replacement instanceof BFunctionPointer replacer) {
                Object replacementString = replacer.call(runtime, StringUtils.fromString(StringUtils.getStringValue(realValue)));
                if (replacementString instanceof BString replacementStrVal) {
                    return Optional.of(replacementStrVal.getValue());
                }
            }
        }
        return Optional.of(StringUtils.getStringValue(realValue));
    }
}

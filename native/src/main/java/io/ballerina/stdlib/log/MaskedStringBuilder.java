/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BFunctionPointer;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTable;

import java.util.Collection;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * High-performance builder for creating masked string representations of Ballerina values.
 * Implements Closeable for proper resource management and memory efficiency.
 *
 * @since 2.14.0
 */
public class MaskedStringBuilder implements AutoCloseable {

    private static final BString STRATEGY_KEY = StringUtils.fromString("strategy");
    private static final BString REPLACEMENT_KEY = StringUtils.fromString("replacement");
    private static final BString EXCLUDE_VALUE = StringUtils.fromString("EXCLUDE");
    private static final String FIELD_PREFIX = "$field$.";
    private static final String LOG_ANNOTATION_PREFIX = "ballerina/log";
    private static final String SENSITIVE_DATA_SUFFIX = ":SensitiveData";

    private static final BString CYCLIC_REFERENCE_ERROR = StringUtils.fromString("Cyclic value reference detected in the record");

    private final Runtime runtime;
    private final IdentityHashMap<Object, Boolean> visitedValues;
    private StringBuilder stringBuilder;
    private boolean closed = false;

    // Initial capacity configuration
    private static final int DEFAULT_INITIAL_CAPACITY = 256;
    private static final int MAX_REUSABLE_CAPACITY = 8192; // 8KB threshold for reuse

    public MaskedStringBuilder(Runtime runtime) {
        this.runtime = runtime;
        this.visitedValues = new IdentityHashMap<>();
        this.stringBuilder = new StringBuilder(DEFAULT_INITIAL_CAPACITY);
    }

    public MaskedStringBuilder(Runtime runtime, int initialCapacity) {
        this.runtime = runtime;
        this.visitedValues = new IdentityHashMap<>();
        this.stringBuilder = new StringBuilder(Math.max(initialCapacity, DEFAULT_INITIAL_CAPACITY));
    }

    /**
     * Build a masked string representation of the given value.
     *
     * @param value the value to mask
     * @return the masked string representation
     */
    public String build(Object value) {
        if (closed) {
            throw new IllegalStateException("MaskedStringBuilder has been closed");
        }

        try {
            visitedValues.clear();
            stringBuilder.setLength(0);

            String result = buildInternal(value);

            // If the builder grew too large, replace it with a smaller one for future use
            if (stringBuilder.capacity() > MAX_REUSABLE_CAPACITY) {
                stringBuilder = new StringBuilder(DEFAULT_INITIAL_CAPACITY);
            }

            return result;
        } finally {
            visitedValues.clear();
        }
    }

    private String buildInternal(Object value) {
        if (isBasicType(value)) {
            return StringUtils.getStringValue(value);
        }

        // Use identity-based checking for cycle detection
        if (visitedValues.put(value, Boolean.TRUE) != null) {
            throw ErrorCreator.createError(CYCLIC_REFERENCE_ERROR);
        }

        try {
            return processValue(value);
        } finally {
            visitedValues.remove(value);
        }
    }

    private String processValue(Object value) {
        Type type = TypeUtils.getType(value);

        return switch (value) {
            // Processing only the structured types, since the basic types does not contain the
            // inherent type information unless they are part of a structured type.
            case BMap<?, ?> mapValue -> processMapValue(mapValue, type);
            case BTable<?, ?> tableValue -> processTableValue(tableValue);
            case BArray listValue -> processArrayValue(listValue);
            default -> StringUtils.getStringValue(value);
        };
    }

    private String processMapValue(BMap<?, ?> mapValue, Type valueType) {
        if (valueType.getTag() != TypeTags.RECORD_TYPE_TAG) {
            return StringUtils.getStringValue(mapValue);
        }

        RecordType recType = (RecordType) valueType;
        Map<String, Field> fields = recType.getFields();
        if (fields.isEmpty()) {
            return "{}";
        }

        int startPos = stringBuilder.length();
        stringBuilder.append('{');

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
                fieldStringValue = Optional.of(buildInternal(fieldValue));
            }

            if (fieldStringValue.isPresent()) {
                if (!first) {
                    stringBuilder.append(',');
                }
                appendFieldToJson(fieldName, fieldStringValue.get(), annotation.isPresent(), fieldValue);
                first = false;
            }
        }

        stringBuilder.append('}');

        String result = stringBuilder.substring(startPos);
        stringBuilder.setLength(startPos);
        return result;
    }

    private void appendFieldToJson(String fieldName, String value, boolean hasAnnotation, Object fieldValue) {
        stringBuilder.append('"').append(escapeJsonString(fieldName)).append("\":");
        if (hasAnnotation || fieldValue instanceof BString) {
            stringBuilder.append('"').append(escapeJsonString(value)).append('"');
        } else {
            stringBuilder.append(value);
        }
    }

    private String processTableValue(BTable<?, ?> tableValue) {
        Collection<?> values = tableValue.values();
        if (values.isEmpty()) {
            return "[]";
        }

        int startPos = stringBuilder.length();
        stringBuilder.append('[');

        boolean first = true;
        for (Object row : values) {
            if (!first) {
                stringBuilder.append(',');
            }
            String elementString = buildInternal(row);
            appendValueToArray(elementString, row);
            first = false;
        }

        stringBuilder.append(']');

        String result = stringBuilder.substring(startPos);
        stringBuilder.setLength(startPos);
        return result;
    }

    private String processArrayValue(BArray listValue) {
        long length = listValue.getLength();
        if (length == 0) {
            return "[]";
        }

        int startPos = stringBuilder.length();
        stringBuilder.append('[');

        // Using traditional for loop instead of for-each loop since BArray giving
        // this error: Cannot read the array length because "<local5>" is null
        for (long i = 0; i < length; i++) {
            if (i > 0) {
                stringBuilder.append(',');
            }
            Object element = listValue.get(i);
            String elementString = buildInternal(element);
            appendValueToArray(elementString, element);
        }

        stringBuilder.append(']');

        String result = stringBuilder.substring(startPos);
        stringBuilder.setLength(startPos);
        return result;
    }

    private void appendValueToArray(String value, Object originalValue) {
        if (originalValue instanceof BString) {
            stringBuilder.append('"').append(escapeJsonString(value)).append('"');
        } else {
            stringBuilder.append(value);
        }
    }

    /**
     * Escape characters in a string for safe JSON representation.
     * Handles quotes, backslashes, and control characters.
     *
     * @param input the input string to escape
     * @return the escaped string
     */
    private static String escapeJsonString(String input) {
        if (input == null) {
            return "null";
        }

        if (!needsEscaping(input)) {
            return input;
        }

        StringBuilder escaped = new StringBuilder(input.length() + 16);

        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            switch (c) {
                case '"' -> escaped.append("\\\"");
                case '\\' -> escaped.append("\\\\");
                case '\b' -> escaped.append("\\b");
                case '\f' -> escaped.append("\\f");
                case '\n' -> escaped.append("\\n");
                case '\r' -> escaped.append("\\r");
                case '\t' -> escaped.append("\\t");
                default -> {
                    if (c < 0x20 || c == 0x7F) {
                        escaped.append(String.format("\\u%04x", (int) c));
                    } else {
                        escaped.append(c);
                    }
                }
            }
        }

        return escaped.toString();
    }

    /**
     * Quick check if a string needs JSON escaping.
     * This avoids unnecessary StringBuilder allocation for clean strings.
     */
    private static boolean needsEscaping(String input) {
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            if (c == '"' || c == '\\' || c < 0x20 || c == 0x7F) {
                return true;
            }
        }
        return false;
    }

    private static boolean isBasicType(Object value) {
        return value == null || TypeUtils.getType(value).getTag() <= TypeTags.BOOLEAN_TAG;
    }

    /**
     * Get the current capacity of the internal StringBuilder.
     * Useful for monitoring memory usage.
     *
     * @return current capacity
     */
    public int getCapacity() {
        return stringBuilder.capacity();
    }

    /**
     * Reset the builder state for reuse while keeping the allocated memory.
     * This is more efficient than creating a new builder instance.
     */
    public void reset() {
        if (closed) {
            throw new IllegalStateException("MaskedStringBuilder has been closed");
        }
        visitedValues.clear();
        stringBuilder.setLength(0);
    }

    /**
     * Check if the builder has been closed.
     *
     * @return true if closed, false otherwise
     */
    public boolean isClosed() {
        return closed;
    }

    @Override
    public void close() {
        if (!closed) {
            visitedValues.clear();
            stringBuilder = null;
            closed = true;
        }
    }

    /**
     * Create a new MaskedStringBuilder instance with default settings.
     *
     * @param runtime the Ballerina runtime
     * @return a new MaskedStringBuilder instance
     */
    public static MaskedStringBuilder create(Runtime runtime) {
        return new MaskedStringBuilder(runtime);
    }

    /**
     * Create a new MaskedStringBuilder instance with specified initial capacity.
     *
     * @param runtime the Ballerina runtime
     * @param initialCapacity the initial capacity for the internal StringBuilder
     * @return a new MaskedStringBuilder instance
     */
    public static MaskedStringBuilder create(Runtime runtime, int initialCapacity) {
        return new MaskedStringBuilder(runtime, initialCapacity);
    }

    static Optional<BMap<?, ?>> getLogSensitiveDataAnnotation(Map<String, BMap<?, ?>> fieldAnnotations, String fieldName) {
        BMap<?, ?> fieldAnnotationMap = fieldAnnotations.get(fieldName);
        if (fieldAnnotationMap == null) {
            return Optional.empty();
        }

        Object[] keys = fieldAnnotationMap.getKeys();

        for (Object key : keys) {
            if (key instanceof BString bStringKey) {
                String keyValue = bStringKey.getValue();
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

        return annotations.entrySet().stream()
                .filter(entry -> {
                    String keyValue = entry.getKey().getValue();
                    return keyValue.startsWith(FIELD_PREFIX) && entry.getValue() instanceof BMap;
                })
                .collect(Collectors.toMap(
                        entry -> entry.getKey().getValue().substring(FIELD_PREFIX.length()),
                        entry -> (BMap<?, ?>) entry.getValue(),
                        (existing, replacement) -> existing
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

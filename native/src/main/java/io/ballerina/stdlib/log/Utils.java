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
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

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
        return StringUtils.fromString(
                new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX")
                        .format(new Date()));
    }

    public static BString getMaskedString(Environment env, Object value) {
        Set<Object> visitedValues = new HashSet<>();
        return StringUtils.fromString(getMaskedStringInternal(env.getRuntime(), value, visitedValues));
    }

    static String getMaskedStringInternal(Runtime runtime, Object value, Set<Object> visitedValues) {
        if (isBasicType(value)) {
            return StringUtils.getStringValue(value);
        }
        if (!visitedValues.add(value)) {
            throw ErrorCreator.createError(StringUtils.fromString("Cyclic value reference detected in the record"));
        }
        Type type = TypeUtils.getType(value);
        if (value instanceof BMap mapValue) {
            RecordType recType = (RecordType) type;
            Map<String, Field> fields = recType.getFields();
            StringBuilder maskedString = new StringBuilder("{");
            Map<String, BMap> fieldAnnotations = extractFieldAnnotations(recType);
            for (Map.Entry<String, Field> entry : fields.entrySet()) {
                String fieldName = entry.getKey();
                Optional<String> fieldStringValue;
                Optional<BMap> annotation = getLogSensitiveDataAnnotation(fieldAnnotations, fieldName);
                Object fieldValue = mapValue.get(StringUtils.fromString(fieldName));
                if (fieldValue == null) {
                    continue;
                }
                if (annotation.isPresent()) {
                    fieldStringValue = getStringValue(annotation.get(), fieldValue, runtime);
                } else {
                    fieldStringValue = Optional.of(getMaskedStringInternal(runtime, fieldValue, visitedValues));
                }
                fieldStringValue.ifPresent(s -> {
                    maskedString.append("\"").append(fieldName).append("\"")
                            .append(":");
                    if (annotation.isPresent() || fieldValue instanceof BString) {
                        maskedString.append("\"").append(s).append("\"");
                    } else {
                        maskedString.append(s);
                    }
                    maskedString.append(",");
                });
            }
            if (maskedString.length() > 1) {
                maskedString.setLength(maskedString.length() - 1);
            }
            maskedString.append("}");
            return maskedString.toString();
        }
        if (value instanceof BTable tableValue) {
            StringBuilder tableString = new StringBuilder("[");
            for (Object row : tableValue.values()) {
                String rowString = getMaskedStringInternal(runtime, row, visitedValues);
                if (row instanceof BString) {
                    tableString.append("\"").append(rowString).append("\"");
                } else {
                    tableString.append(rowString);
                }
                tableString.append(",");
            }
            if (tableString.length() > 1) {
                tableString.setLength(tableString.length() - 1);
            }
            tableString.append("]");
            visitedValues.remove(value);
            return tableString.toString();
        }
        if (value instanceof BArray listValue) {
            StringBuilder arrayString = new StringBuilder("[");
            long length = listValue.getLength();
            for (long i = 0; i < length; i++) {
                Object element = listValue.get(i);
                String elementString = getMaskedStringInternal(runtime, element, visitedValues);
                if (element instanceof BString) {
                    arrayString.append("\"").append(elementString).append("\"");
                } else {
                    arrayString.append(elementString);
                }
                arrayString.append(",");
            }
            if (arrayString.length() > 1) {
                arrayString.setLength(arrayString.length() - 1);
            }
            arrayString.append("]");
            visitedValues.remove(value);
            return arrayString.toString();
        }
        visitedValues.remove(value);
        return StringUtils.getStringValue(value);
    }

    static boolean isBasicType(Object value) {
        return value == null || TypeUtils.getType(value).getTag() <= 7;
    }

    static Optional<BMap> getLogSensitiveDataAnnotation(Map<String, BMap> fieldAnnotations, String fieldName) {
        if (!fieldAnnotations.containsKey(fieldName)) {
            return Optional.empty();
        }

        BMap fieldAnnotationMap = fieldAnnotations.get(fieldName);
        Object[] keys = fieldAnnotationMap.getKeys();
        Object targetKey = null;
        for (Object key : keys) {
            if (key instanceof BString bStringKey && bStringKey.getValue().startsWith("ballerina/log") &&
                    bStringKey.getValue().endsWith(":SensitiveData")) {
                targetKey = key;
                break;
            }
        }
        if (targetKey != null) {
            Object annotation = fieldAnnotationMap.get(targetKey);
            if (annotation instanceof BMap) {
                return Optional.of((BMap) annotation);
            }
        }
        return Optional.empty();
    }

    static Map<String, BMap> extractFieldAnnotations(RecordType recordType) {
        BMap<BString, Object> annotations = recordType.getAnnotations();
        if (annotations == null) {
            return Map.of();
        }
        return annotations.entrySet().stream()
                .filter(entry -> entry.getKey().getValue().startsWith("$field$."))
                .filter(entry -> entry.getValue() instanceof BMap)
                .collect(Collectors.toMap(
                        entry -> entry.getKey().getValue().substring(8),
                        entry -> (BMap) entry.getValue()
                ));
    }

    static Optional<String> getStringValue(BMap annotation, Object realValue, Runtime runtime) {
        Object strategy = annotation.get(StringUtils.fromString("strategy"));
        if (strategy instanceof BString excluded && excluded.getValue().equals("EXCLUDE")) {
            return Optional.empty();
        }
        if (strategy instanceof BMap replacementMap) {
            Object replacement = replacementMap.get(StringUtils.fromString("replacement"));
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

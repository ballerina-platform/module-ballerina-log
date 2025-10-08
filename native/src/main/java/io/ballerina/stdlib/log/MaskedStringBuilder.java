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
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ReferenceType;
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
import io.ballerina.runtime.api.values.BXml;

import java.util.Collection;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * High-performance builder for creating masked string representations of Ballerina values.
 * Implements AutoCloseable for proper resource management and memory efficiency.
 *
 * @since 2.14.0
 */
public class MaskedStringBuilder implements AutoCloseable {

    private static final BString STRATEGY_KEY = StringUtils.fromString("strategy");
    private static final BString REPLACEMENT_KEY = StringUtils.fromString("replacement");
    private static final BString EXCLUDE_VALUE = StringUtils.fromString("EXCLUDE");
    private static final String FIELD_PREFIX = "$field$.";
    private static final String LOG_ANNOTATION_PREFIX = "ballerina/log";
    private static final String SENSITIVE_SUFFIX = ":Sensitive";

    private static final BString CYCLIC_REFERENCE_ERROR = StringUtils.fromString("Cyclic value reference detected " +
            "in the record");
    public static final BString MASKED_STRING_BUILDER_HAS_BEEN_CLOSED = StringUtils.fromString("MaskedStringBuilder" +
            " has been closed");

    // Cache for field annotations to avoid repeated extraction
    private static final Map<RecordType, Map<String, BMap<?, ?>>> ANNOTATION_CACHE = new ConcurrentHashMap<>();
    private static final int MAX_CACHE_SIZE = 1000;

    // Pre-computed hex lookup table for efficient Unicode escaping
    private static final char[] HEX_CHARS = "0123456789abcdef".toCharArray();

    // JSON escape character arrays for efficient escaping
    private static final char[] QUOTE_ESCAPE = {'\\', '"'};
    private static final char[] BACKSLASH_ESCAPE = {'\\', '\\'};
    private static final char[] NEWLINE_ESCAPE = {'\\', 'n'};
    private static final char[] TAB_ESCAPE = {'\\', 't'};
    private static final char[] CARRIAGE_RETURN_ESCAPE = {'\\', 'r'};
    private static final char[] BACKSPACE_ESCAPE = {'\\', 'b'};
    private static final char[] FORM_FEED_ESCAPE = {'\\', 'f'};

    // Control character range constants for Unicode escaping
    private static final int ASCII_CONTROL_CHAR_LIMIT = 0x20; // Space character (32)
    private static final int ASCII_DEL_CHAR = 0x7F; // DEL character (127)

    private final Runtime runtime;
    private final IdentityHashMap<Object, Boolean> visitedValues;
    private StringBuilder stringBuilder;
    private StringBuilder escapeBuffer;
    private boolean closed = false;

    // Initial capacity configuration
    private static final int DEFAULT_INITIAL_CAPACITY = 256;
    private static final int MAX_REUSABLE_CAPACITY = 8192;
    private static final int ESCAPE_BUFFER_SIZE = 64;

    public MaskedStringBuilder(Runtime runtime) {
        this(runtime, DEFAULT_INITIAL_CAPACITY);
    }

    public MaskedStringBuilder(Runtime runtime, int initialCapacity) {
        this.runtime = runtime;
        this.visitedValues = new IdentityHashMap<>();
        this.stringBuilder = new StringBuilder(initialCapacity < 0 ? DEFAULT_INITIAL_CAPACITY : initialCapacity);
        this.escapeBuffer = new StringBuilder(ESCAPE_BUFFER_SIZE);
    }

    /**
     * Build a masked string representation of the given value.
     *
     * @param value the value to mask
     * @return the masked string representation
     */
    public String build(Object value) {
        if (this.closed) {
            throw ErrorCreator.createError(MASKED_STRING_BUILDER_HAS_BEEN_CLOSED);
        }

        try {
            this.visitedValues.clear();
            this.stringBuilder.setLength(0);

            String result = buildInternal(value);

            // If the builder grew too large, replace it with a smaller one for future use
            if (this.stringBuilder.capacity() > MAX_REUSABLE_CAPACITY) {
                this.stringBuilder = new StringBuilder(DEFAULT_INITIAL_CAPACITY);
            }

            // Reset escape buffer if it grew too large
            if (this.escapeBuffer.capacity() > ESCAPE_BUFFER_SIZE * 4) {
                this.escapeBuffer = new StringBuilder(ESCAPE_BUFFER_SIZE);
            }

            return result;
        } finally {
            this.visitedValues.clear();
        }
    }

    private String buildInternal(Object value) {
        if (value == null) {
            return "null";
        }
        if (isBasicType(value)) {
            return StringUtils.getStringValue(value);
        }

        // Use identity-based checking for cycle detection
        if (this.visitedValues.put(value, Boolean.TRUE) != null) {
            // Panics on cyclic value references
            throw ErrorCreator.createError(CYCLIC_REFERENCE_ERROR);
        }

        try {
            return processValue(value);
        } finally {
            this.visitedValues.remove(value);
        }
    }

    private String processValue(Object value) {
        // Getting implied type to handle intersection types with readonly
        Type type = getEffectiveType(TypeUtils.getType(value));

        return switch (value) {
            // Processing only the structured types, since the basic types does not contain the
            // inherent type information.
            case BMap<?, ?> mapValue -> processMapValue(mapValue, type);
            case BTable<?, ?> tableValue -> processTableValue(tableValue);
            case BArray listValue -> processArrayValue(listValue);
            default -> StringUtils.getStringValue(value);
        };
    }

    private Type getEffectiveType(Type type) {
        // For intersection types, get the first constituent type that is not readonly
        if (type.getTag() == TypeTags.INTERSECTION_TAG) {
            List<Type> constituentTypes = ((IntersectionType) type).getConstituentTypes();
            if (constituentTypes.size() == 2) {
                type = constituentTypes.get(0).getTag() == TypeTags.READONLY_TAG ? constituentTypes.get(1) :
                        constituentTypes.get(0);
                return getEffectiveType(type);
            }
        }

        // Record types can be intersection types, so unwrap them to get the actual record type
        if (type.getTag() == TypeTags.RECORD_TYPE_TAG) {
            Optional<IntersectionType> intersectionType = ((RecordType) type).getIntersectionType();
            if (intersectionType.isPresent()) {
                return getEffectiveType(intersectionType.get());
            }
        }

        // Unwrap reference types to get the actual referred type
        if (type.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            type = ((ReferenceType) type).getReferredType();
            return getEffectiveType(type);
        }
        return type;
    }

    private String processMapValue(BMap<?, ?> mapValue, Type valueType) {
        Map<String, Field> fields = Map.of();
        Map<String, BMap<?, ?>> fieldAnnotations = Map.of();

        if (valueType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            RecordType recType = (RecordType) valueType;
            fields = recType.getFields();
            // Use cached field annotations for better performance
            fieldAnnotations = getCachedFieldAnnotations(recType);
        }

        return processRecordValue(mapValue, fieldAnnotations, fields);
    }

    private String processRecordValue(BMap<?, ?> mapValue, Map<String, BMap<?, ?>> fieldAnnotations,
                                      Map<String, Field> fields) {
        int startPos = this.stringBuilder.length();

        this.stringBuilder.append('{');
        addRecordFields(mapValue, fields, fieldAnnotations);
        this.stringBuilder.append('}');

        String result = this.stringBuilder.substring(startPos);
        this.stringBuilder.setLength(startPos);
        return result;
    }

    private void addRecordFields(BMap<?, ?> mapValue, Map<String, Field> fields,
                                 Map<String, BMap<?, ?>> fieldAnnotations) {
        boolean first = true;

        for (Object key : mapValue.getKeys()) {
            if (!(key instanceof BString keyStr)) {
                continue;
            }
            Object fieldValue = mapValue.get(key);
            String fieldName = keyStr.getValue();
            first = fields.containsKey(fieldName) ?
                    addDefinedFieldValue(fieldAnnotations, fieldName, fieldValue, first) :
                    addDynamicFieldValue(fieldValue, first, fieldName);
        }
    }

    private boolean addDynamicFieldValue(Object fieldValue, boolean first, String fieldName) {
        String fieldStringValue = buildInternal(fieldValue);
        if (!first) {
            this.stringBuilder.append(',');
        }
        appendFieldToJson(fieldName, fieldStringValue, false, fieldValue);
        return false;
    }

    private boolean addDefinedFieldValue(Map<String, BMap<?, ?>> fieldAnnotations, String fieldName, Object fieldValue,
                                         boolean first) {
        Optional<BMap<?, ?>> annotation = getLogSensitiveDataAnnotation(fieldAnnotations, fieldName);
        Optional<String> fieldStringValue = annotation
                .map(fieldAnnotation -> getStringValue(fieldAnnotation, fieldValue, runtime))
                .orElseGet(() -> Optional.of(buildInternal(fieldValue)));

        if (fieldStringValue.isPresent()) {
            if (!first) {
                this.stringBuilder.append(',');
            }
            appendFieldToJson(fieldName, fieldStringValue.get(), annotation.isPresent(), fieldValue);
            first = false;
        }
        return first;
    }

    /**
     * Append field to JSON format by writing directly to StringBuilder
     * without creating intermediate String objects for better performance.
     */
    private void appendFieldToJson(String fieldName, String value, boolean hasAnnotation, Object fieldValue) {
        this.stringBuilder.append('"');
        appendEscapedString(fieldName);
        this.stringBuilder.append("\":");
        if (hasAnnotation || fieldValue instanceof BString || fieldValue instanceof BXml) {
            this.stringBuilder.append('"');
            appendEscapedString(value);
            this.stringBuilder.append('"');
        } else {
            this.stringBuilder.append(value);
        }
    }

    /**
     * Append escaped string directly to the main StringBuilder.
     * This avoids creating intermediate String objects for better performance.
     */
    private void appendEscapedString(String input) {
        if (input == null) {
            this.stringBuilder.append("null");
            return;
        }

        if (!needsEscaping(input)) {
            this.stringBuilder.append(input);
            return;
        }

        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            switch (c) {
                case '"' -> this.stringBuilder.append(QUOTE_ESCAPE);
                case '\\' -> this.stringBuilder.append(BACKSLASH_ESCAPE);
                case '\b' -> this.stringBuilder.append(BACKSPACE_ESCAPE);
                case '\f' -> this.stringBuilder.append(FORM_FEED_ESCAPE);
                case '\n' -> this.stringBuilder.append(NEWLINE_ESCAPE);
                case '\r' -> this.stringBuilder.append(CARRIAGE_RETURN_ESCAPE);
                case '\t' -> this.stringBuilder.append(TAB_ESCAPE);
                default -> {
                    // Escape ASCII control characters (0x00-0x1F) and DEL character (0x7F)
                    if (c < ASCII_CONTROL_CHAR_LIMIT || c == ASCII_DEL_CHAR) {
                        this.stringBuilder.append("\\u00");
                        this.stringBuilder.append(HEX_CHARS[(c >>> 4) & 0xF]);
                        this.stringBuilder.append(HEX_CHARS[c & 0xF]);
                    } else {
                        this.stringBuilder.append(c);
                    }
                }
            }
        }
    }

    /**
     * Get cached field annotations for better performance.
     * Implements simple cache eviction when cache grows too large.
     */
    private Map<String, BMap<?, ?>> getCachedFieldAnnotations(RecordType recordType) {
        Map<String, BMap<?, ?>> cached = ANNOTATION_CACHE.get(recordType);
        if (cached != null) {
            return cached;
        }

        // Implement simple cache size management
        if (ANNOTATION_CACHE.size() >= MAX_CACHE_SIZE) {
            // Clear half the cache when it gets too large (simple eviction strategy)
            ANNOTATION_CACHE.entrySet().removeIf(entry -> System.identityHashCode(entry.getKey()) % 2 == 0);
        }

        Map<String, BMap<?, ?>> annotations = extractFieldAnnotations(recordType);
        ANNOTATION_CACHE.put(recordType, annotations);
        return annotations;
    }

    private String processTableValue(BTable<?, ?> tableValue) {
        Collection<?> values = tableValue.values();
        if (values.isEmpty()) {
            return "[]";
        }

        int startPos = this.stringBuilder.length();
        this.stringBuilder.append('[');

        boolean first = true;
        for (Object row : values) {
            if (!first) {
                this.stringBuilder.append(',');
            }
            String elementString = buildInternal(row);
            appendValueToArray(elementString, row);
            first = false;
        }

        this.stringBuilder.append(']');

        String result = this.stringBuilder.substring(startPos);
        this.stringBuilder.setLength(startPos);
        return result;
    }

    private String processArrayValue(BArray listValue) {
        long length = listValue.getLength();
        if (length == 0) {
            return "[]";
        }

        int startPos = this.stringBuilder.length();
        this.stringBuilder.append('[');

        // Using traditional for loop instead of for-each loop since BArray giving
        // this error: Cannot read the array length because "<local5>" is null
        for (long i = 0; i < length; i++) {
            if (i > 0) {
                this.stringBuilder.append(',');
            }
            Object element = listValue.get(i);
            String elementString = buildInternal(element);
            appendValueToArray(elementString, element);
        }

        this.stringBuilder.append(']');

        String result = this.stringBuilder.substring(startPos);
        this.stringBuilder.setLength(startPos);
        return result;
    }

    private void appendValueToArray(String value, Object originalValue) {
        if (originalValue instanceof BString) {
            this.stringBuilder.append('"');
            appendEscapedString(value);
            this.stringBuilder.append('"');
        } else {
            this.stringBuilder.append(value);
        }
    }

    /**
     * Check if a value is a basic type that doesn't need complex processing.
     */
    private static boolean isBasicType(Object value) {
        return value == null || TypeUtils.getType(value).getTag() <= TypeTags.BOOLEAN_TAG;
    }

    /**
     * Quick check if a string needs JSON escaping.
     * This avoids unnecessary StringBuilder allocation for clean strings.
     */
    private static boolean needsEscaping(String input) {
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            // Check for quote, backslash, control characters (0x00-0x1F), or DEL character (0x7F)
            if (c == '"' || c == '\\' || (c & 0xFFE0) == 0 || c == ASCII_DEL_CHAR) {
                return true;
            }
        }
        return false;
    }

    /**
     * Get the current capacity of the internal StringBuilder.
     * Useful for monitoring memory usage.
     *
     * @return current capacity
     */
    public int getCapacity() {
        return this.stringBuilder.capacity();
    }

    /**
     * Reset the builder state for reuse while keeping the allocated memory.
     * This is more efficient than creating a new builder instance.
     */
    public void reset() {
        if (this.closed) {
            throw ErrorCreator.createError(MASKED_STRING_BUILDER_HAS_BEEN_CLOSED);
        }
        this.visitedValues.clear();
        this.stringBuilder.setLength(0);
        this.escapeBuffer.setLength(0);
    }

    /**
     * Check if the builder has been closed.
     *
     * @return true if closed, false otherwise
     */
    public boolean isClosed() {
        return this.closed;
    }

    @Override
    public void close() {
        if (!this.closed) {
            this.visitedValues.clear();
            this.stringBuilder = null;
            this.escapeBuffer = null;
            this.closed = true;
        }
    }

    /**
     * Clear the annotation cache to free memory.
     * Should be called periodically in long-running applications.
     */
    public static void clearAnnotationCache() {
        ANNOTATION_CACHE.clear();
    }

    /**
     * Get the size of the annotation cache for monitoring purposes.
     */
    public static int getAnnotationCacheSize() {
        return ANNOTATION_CACHE.size();
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

    static Optional<BMap<?, ?>> getLogSensitiveDataAnnotation(Map<String, BMap<?, ?>> fieldAnnotations,
                                                              String fieldName) {
        // In the value map keys are unescaped, but the annotation keys are escaped
        // Moreover runtime does not provide a way to unescape the annotation keys, so we need to escape the field name
        BMap<?, ?> fieldAnnotationMap = fieldAnnotations.get(IdentifierUtils.escapeSpecialCharacters(fieldName));
        if (fieldAnnotationMap == null) {
            return Optional.empty();
        }

        Object[] keys = fieldAnnotationMap.getKeys();

        for (Object key : keys) {
            if (key instanceof BString bStringKey) {
                String keyValue = bStringKey.getValue();
                if (keyValue.endsWith(SENSITIVE_SUFFIX) && keyValue.startsWith(LOG_ANNOTATION_PREFIX)) {
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
                Object replacementString = replacer.call(runtime,
                        StringUtils.fromString(StringUtils.getStringValue(realValue)));
                if (replacementString instanceof BString replacementStrVal) {
                    return Optional.of(replacementStrVal.getValue());
                }
            }
        }
        return Optional.of(StringUtils.getStringValue(realValue));
    }
}

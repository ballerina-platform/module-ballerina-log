/*
 * Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
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

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Provides logger ID generation and module-level log level storage.
 * Module log levels are stored in a ConcurrentHashMap so reads on the hot logging
 * path are lock-free (no Ballerina isolation lock required).
 *
 * @since 2.17.0
 */
public class LogConfigManager {

    private static final LogConfigManager INSTANCE = new LogConfigManager();

    // Per-function counters for auto-generated IDs: "module:function" -> counter
    private final ConcurrentHashMap<String, AtomicLong> functionCounters = new ConcurrentHashMap<>();

    // Module-level log level overrides: moduleName -> level string.
    // ConcurrentHashMap gives lock-free reads on the hot logging path.
    private final ConcurrentHashMap<String, String> moduleLogLevels = new ConcurrentHashMap<>();

    private LogConfigManager() {
    }

    /**
     * Get the singleton instance of LogConfigManager.
     *
     * @return the LogConfigManager instance
     */
    public static LogConfigManager getInstance() {
        return INSTANCE;
    }

    /**
     * Generate a readable logger ID based on the calling context.
     * Format: "module:function-counter" (e.g., "myorg/payment:processOrder-1")
     *
     * @param stackOffset the number of stack frames to skip to reach the caller
     * @return the generated logger ID
     */
    String generateLoggerId(int stackOffset) {
        StackWalker walker = StackWalker.getInstance(StackWalker.Option.RETAIN_CLASS_REFERENCE);
        StackWalker.StackFrame callerFrame = walker.walk(frames ->
                frames.skip(stackOffset).findFirst().orElse(null));

        String modulePart = "unknown";
        String functionPart = "unknown";
        if (callerFrame != null) {
            String className = callerFrame.getClassName();
            String methodName = callerFrame.getMethodName();
            // Extract module name from Ballerina class name convention.
            // Typical format: "org.module_name.version.file" (e.g., "demo.log_level.0.main")
            // We want: "org/module_name" (e.g., "demo/log_level")
            // The version segment (e.g., "0") and file name should be stripped.
            String[] parts = className.split("\\.");
            if (parts.length >= 3) {
                // parts[0] = org, parts[1] = module, parts[2] = version, parts[3..] = file/class
                modulePart = parts[0] + "/" + parts[1];
            } else if (parts.length == 2) {
                modulePart = parts[0] + "/" + parts[1];
            } else {
                modulePart = className;
            }
            functionPart = methodName;
        }

        String key = modulePart + ":" + functionPart;
        AtomicLong counter = functionCounters.computeIfAbsent(key, k -> new AtomicLong(0));
        long count = counter.incrementAndGet();
        if (count == 1) {
            return key;
        }
        return key + "-" + count;
    }

    /**
     * Generate a readable logger ID from Ballerina.
     *
     * @param stackOffset the number of stack frames to skip
     * @return the generated logger ID
     */
    public static BString generateLoggerId(long stackOffset) {
        return StringUtils.fromString(getInstance().generateLoggerId((int) stackOffset));
    }

    /**
     * Return the configured log level for a module, or null if no override is set.
     * Called on every log statement — no Ballerina isolation lock is acquired.
     *
     * @param moduleName the Ballerina module name (e.g. "myorg/payment")
     * @return a BString level value, or null if no override is registered
     */
    public static Object getModuleLevel(BString moduleName) {
        String level = getInstance().moduleLogLevels.get(moduleName.getValue());
        return level != null ? StringUtils.fromString(level) : null;
    }

    /**
     * Register or update the log level override for a module.
     *
     * @param moduleName the Ballerina module name
     * @param level      the log level string (DEBUG, INFO, WARN, ERROR)
     */
    public static void setModuleLevel(BString moduleName, BString level) {
        getInstance().moduleLogLevels.put(moduleName.getValue(), level.getValue());
    }
}

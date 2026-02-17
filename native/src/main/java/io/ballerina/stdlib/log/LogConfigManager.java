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

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTable;

import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Manages runtime log configuration for dynamic log level changes.
 * This class provides APIs to get and modify log levels at runtime without application restart.
 * <p>
 * All loggers — including module loggers, loggers created via fromConfig, and child loggers
 * created via withContext — are stored in a single unified registry.
 *
 * @since 2.17.0
 */
public class LogConfigManager {

    private static final LogConfigManager INSTANCE = new LogConfigManager();

    // Valid log levels
    private static final Set<String> VALID_LOG_LEVELS = Set.of("DEBUG", "INFO", "WARN", "ERROR");

    // Log level weights for comparison
    private static final Map<String, Integer> LOG_LEVEL_WEIGHT = Map.of(
            "ERROR", 1000,
            "WARN", 900,
            "INFO", 800,
            "DEBUG", 700
    );

    // Runtime root log level (atomic for thread-safety)
    private final AtomicReference<String> rootLogLevel = new AtomicReference<>("INFO");

    // Unified single-tier registry: all loggers are visible (loggerId -> logLevel)
    // This includes module loggers (ID = module name), fromConfig loggers, and withContext children.
    private final ConcurrentHashMap<String, String> loggerLevels = new ConcurrentHashMap<>();

    // Per-function counters for auto-generated IDs: "module:function" -> counter
    private final ConcurrentHashMap<String, AtomicLong> functionCounters = new ConcurrentHashMap<>();

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
     * Initialize the runtime configuration from configurable values.
     * This should be called during module initialization.
     * Module log levels are registered into the unified logger registry using the module name as the logger ID.
     *
     * @param rootLevel the root log level from configurable
     * @param modules   the modules table from configurable
     */
    public void initialize(BString rootLevel, BTable<BString, BMap<BString, Object>> modules) {
        // Set root log level
        rootLogLevel.set(rootLevel.getValue());

        // Register each configured module as a logger in the unified registry
        if (modules != null) {
            Object[] keys = modules.getKeys();
            for (Object key : keys) {
                BString moduleName = (BString) key;
                BMap<BString, Object> moduleConfig = modules.get(moduleName);
                BString level = (BString) moduleConfig.get(StringUtils.fromString("level"));
                loggerLevels.put(moduleName.getValue(), level.getValue());
            }
        }
    }

    /**
     * Get the current root log level.
     *
     * @return the root log level
     */
    public String getRootLogLevel() {
        return rootLogLevel.get();
    }

    /**
     * Set the root log level.
     *
     * @param level the new log level
     * @return null on success, error on invalid level
     */
    public Object setRootLogLevel(String level) {
        String upperLevel = level.toUpperCase(Locale.ROOT);
        if (!VALID_LOG_LEVELS.contains(upperLevel)) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Invalid log level: '" + level + "'. Valid levels are: DEBUG, INFO, WARN, ERROR"));
        }
        rootLogLevel.set(upperLevel);
        return null;
    }

    /**
     * Register a logger with a user-provided ID.
     * All registered loggers are visible in the registry.
     *
     * @param loggerId the user-provided logger ID
     * @param level    the initial log level of the logger
     * @return null on success, error if ID already exists
     */
    Object registerLoggerWithId(String loggerId, String level) {
        String upperLevel = level.toUpperCase(Locale.ROOT);
        String existing = loggerLevels.putIfAbsent(loggerId, upperLevel);
        if (existing != null) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Logger with ID '" + loggerId + "' already exists"));
        }
        return null;
    }

    /**
     * Register a logger with an auto-generated ID.
     * The logger is visible in the registry under its auto-generated ID.
     *
     * @param loggerId the auto-generated logger ID
     * @param level    the initial log level of the logger
     */
    void registerLoggerAuto(String loggerId, String level) {
        String upperLevel = level.toUpperCase(Locale.ROOT);
        loggerLevels.put(loggerId, upperLevel);
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
     * Get the log level for a registered logger.
     *
     * @param loggerId the logger ID
     * @return the logger's log level, or null if not found
     */
    public String getLoggerLevel(String loggerId) {
        return loggerLevels.get(loggerId);
    }

    /**
     * Set the log level for a registered logger.
     *
     * @param loggerId the logger ID
     * @param level    the new log level
     */
    public void setLoggerLevel(String loggerId, String level) {
        String upperLevel = level.toUpperCase(Locale.ROOT);
        loggerLevels.put(loggerId, upperLevel);
    }

    /**
     * Get all registered loggers and their levels.
     *
     * @return a map of logger IDs to log levels
     */
    public Map<String, String> getAllLoggerLevels() {
        return new ConcurrentHashMap<>(loggerLevels);
    }

    /**
     * Check if a log level is enabled.
     * Checks the unified logger registry for the given module name.
     * If found, uses the registered level; otherwise falls back to the provided logger level.
     *
     * @param loggerLogLevel the logger's configured log level (fallback)
     * @param logLevel       the log level to check
     * @param moduleName     the module name to look up in the registry
     * @return true if the log level is enabled
     */
    public boolean isLogLevelEnabled(String loggerLogLevel, String logLevel, String moduleName) {
        String effectiveLevel = loggerLogLevel;

        // Check if the module is registered as a logger in the unified registry
        String moduleLevel = loggerLevels.get(moduleName);
        if (moduleLevel != null) {
            effectiveLevel = moduleLevel;
        }

        // Compare log level weights
        int requestedWeight = LOG_LEVEL_WEIGHT.getOrDefault(logLevel.toUpperCase(Locale.ROOT), 0);
        int effectiveWeight = LOG_LEVEL_WEIGHT.getOrDefault(effectiveLevel.toUpperCase(Locale.ROOT), 800);

        return requestedWeight >= effectiveWeight;
    }

    /**
     * Check if a log level is enabled for a registered logger.
     * The effective level is passed from the Ballerina side (which handles inheritance).
     *
     * @param effectiveLogLevel the logger's effective log level (from Ballerina-side getLevel())
     * @param logLevel          the log level to check
     * @param moduleName        the module name (unused, kept for API compatibility)
     * @return true if the log level is enabled
     */
    public boolean isCustomLoggerLogLevelEnabled(String effectiveLogLevel, String logLevel, String moduleName) {
        // Use the effective level directly — Ballerina side handles inheritance via getLevel()
        int requestedWeight = LOG_LEVEL_WEIGHT.getOrDefault(logLevel.toUpperCase(Locale.ROOT), 0);
        int effectiveWeight = LOG_LEVEL_WEIGHT.getOrDefault(effectiveLogLevel.toUpperCase(Locale.ROOT), 800);
        return requestedWeight >= effectiveWeight;
    }

    // ========== Static methods for Ballerina interop ==========

    /**
     * Initialize the log configuration from Ballerina configurables.
     *
     * @param rootLevel the root log level
     * @param modules   the modules table
     */
    public static void initializeConfig(BString rootLevel, BTable<BString, BMap<BString, Object>> modules) {
        getInstance().initialize(rootLevel, modules);
    }

    /**
     * Get the current log configuration as a Ballerina map.
     * Returns a nested structure with all loggers in a unified registry:
     * {
     *   "rootLogger": {"level": "INFO"},
     *   "loggers": {"myorg/payment": {"level": "DEBUG"}, "payment-service": {"level": "INFO"}}
     * }
     *
     * @return a map containing rootLogger and loggers
     */
    public static BMap<BString, Object> getLogConfig() {
        LogConfigManager manager = getInstance();

        // Create a map type for map<anydata>
        MapType mapType = TypeCreator.createMapType(PredefinedTypes.TYPE_ANYDATA);
        BString levelKey = StringUtils.fromString("level");

        // Create the result map
        BMap<BString, Object> result = ValueCreator.createMapValue(mapType);

        // Add root logger as nested object {"level": "INFO"}
        BMap<BString, Object> rootLoggerMap = ValueCreator.createMapValue(mapType);
        rootLoggerMap.put(levelKey, StringUtils.fromString(manager.getRootLogLevel()));
        result.put(StringUtils.fromString("rootLogger"), rootLoggerMap);

        // Add all loggers (modules + fromConfig + withContext) as a unified map
        Map<String, String> loggers = manager.getAllLoggerLevels();
        BMap<BString, Object> loggersMap = ValueCreator.createMapValue(mapType);
        for (Map.Entry<String, String> entry : loggers.entrySet()) {
            BMap<BString, Object> loggerConfig = ValueCreator.createMapValue(mapType);
            loggerConfig.put(levelKey, StringUtils.fromString(entry.getValue()));
            loggersMap.put(StringUtils.fromString(entry.getKey()), loggerConfig);
        }
        result.put(StringUtils.fromString("loggers"), loggersMap);

        return result;
    }

    /**
     * Set the root log level from Ballerina.
     *
     * @param level the new log level
     * @return null on success, error on invalid level
     */
    public static Object setGlobalLogLevel(BString level) {
        return getInstance().setRootLogLevel(level.getValue());
    }

    /**
     * Get the root log level from Ballerina.
     *
     * @return the root log level
     */
    public static BString getGlobalLogLevel() {
        return StringUtils.fromString(getInstance().getRootLogLevel());
    }

    /**
     * Set a module's log level from Ballerina.
     * This is now equivalent to setting a logger level with the module name as the logger ID.
     *
     * @param moduleName the module name (used as logger ID)
     * @param level      the new log level
     * @return null on success, error on invalid level
     */
    public static Object setModuleLevel(BString moduleName, BString level) {
        LogConfigManager manager = getInstance();
        String name = moduleName.getValue();
        String upperLevel = level.getValue().toUpperCase(Locale.ROOT);
        if (!VALID_LOG_LEVELS.contains(upperLevel)) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Invalid log level: '" + level.getValue() + "'. Valid levels are: DEBUG, INFO, WARN, ERROR"));
        }
        // Register or update the module as a logger in the unified registry
        manager.loggerLevels.put(name, upperLevel);
        return null;
    }

    /**
     * Remove a module's log level configuration from Ballerina.
     * This removes the module logger from the unified registry.
     *
     * @param moduleName the module name
     * @return true if removed, false if not found
     */
    public static boolean removeModuleLevel(BString moduleName) {
        return getInstance().loggerLevels.remove(moduleName.getValue()) != null;
    }

    /**
     * Register a logger with a user-provided ID from Ballerina.
     *
     * @param loggerId the user-provided logger ID
     * @param level    the initial log level
     * @return null on success, error if ID already exists
     */
    public static Object registerLoggerWithId(BString loggerId, BString level) {
        return getInstance().registerLoggerWithId(loggerId.getValue(), level.getValue());
    }

    /**
     * Register a logger with an auto-generated ID from Ballerina.
     *
     * @param loggerId the auto-generated logger ID
     * @param level    the initial log level
     */
    public static void registerLoggerAuto(BString loggerId, BString level) {
        getInstance().registerLoggerAuto(loggerId.getValue(), level.getValue());
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
     * Set a logger's log level from Ballerina.
     *
     * @param loggerId the logger ID
     * @param level    the new log level
     */
    public static void setLoggerLevel(BString loggerId, BString level) {
        getInstance().setLoggerLevel(loggerId.getValue(), level.getValue());
    }

    /**
     * Check if a log level is enabled for a module from Ballerina.
     *
     * @param loggerLogLevel the logger's configured log level
     * @param logLevel       the log level to check
     * @param moduleName     the module name
     * @return true if enabled
     */
    public static boolean checkLogLevelEnabled(BString loggerLogLevel, BString logLevel, BString moduleName) {
        return getInstance().isLogLevelEnabled(
                loggerLogLevel.getValue(), logLevel.getValue(), moduleName.getValue());
    }

    /**
     * Check if a log level is enabled for a registered logger from Ballerina.
     *
     * @param loggerId   the logger ID
     * @param logLevel   the log level to check
     * @param moduleName the module name
     * @return true if enabled
     */
    public static boolean checkCustomLoggerLogLevelEnabled(BString loggerId, BString logLevel, BString moduleName) {
        return getInstance().isCustomLoggerLogLevelEnabled(
                loggerId.getValue(), logLevel.getValue(), moduleName.getValue());
    }
}

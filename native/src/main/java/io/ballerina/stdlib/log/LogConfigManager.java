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
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTable;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Manages runtime log configuration for dynamic log level changes.
 * This class provides APIs to get and modify log levels at runtime without application restart.
 *
 * @since 2.12.0
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

    // Runtime module log levels (thread-safe map)
    private final ConcurrentHashMap<String, String> moduleLogLevels = new ConcurrentHashMap<>();

    // Track custom loggers created via fromConfig with user-provided IDs (loggerId -> logLevel)
    // Only these loggers are visible to ICP and can have their levels modified
    private final ConcurrentHashMap<String, String> visibleCustomLoggerLevels = new ConcurrentHashMap<>();

    // Track all custom loggers including those without user-provided IDs (loggerId -> logLevel)
    // These are used internally for log level checking but not exposed to ICP
    private final ConcurrentHashMap<String, String> allCustomLoggerLevels = new ConcurrentHashMap<>();

    // Counter for generating unique internal logger IDs (for loggers without user-provided IDs)
    private final AtomicReference<Long> loggerIdCounter = new AtomicReference<>(0L);

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
     *
     * @param rootLevel the root log level from configurable
     * @param modules   the modules table from configurable
     */
    public void initialize(BString rootLevel, BTable<BString, BMap<BString, Object>> modules) {
        // Set root log level
        rootLogLevel.set(rootLevel.getValue());

        // Initialize module log levels from configurable table
        moduleLogLevels.clear();
        if (modules != null) {
            Object[] keys = modules.getKeys();
            for (Object key : keys) {
                BString moduleName = (BString) key;
                BMap<BString, Object> moduleConfig = modules.get(moduleName);
                BString level = (BString) moduleConfig.get(StringUtils.fromString("level"));
                moduleLogLevels.put(moduleName.getValue(), level.getValue());
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
        String upperLevel = level.toUpperCase();
        if (!VALID_LOG_LEVELS.contains(upperLevel)) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Invalid log level: '" + level + "'. Valid levels are: DEBUG, INFO, WARN, ERROR"));
        }
        rootLogLevel.set(upperLevel);
        return null;
    }

    /**
     * Get the log level for a specific module.
     *
     * @param moduleName the module name
     * @return the module's log level, or null if not configured
     */
    public String getModuleLogLevel(String moduleName) {
        return moduleLogLevels.get(moduleName);
    }

    /**
     * Get all configured module log levels.
     *
     * @return a map of module names to log levels
     */
    public Map<String, String> getAllModuleLogLevels() {
        return new ConcurrentHashMap<>(moduleLogLevels);
    }

    /**
     * Set the log level for a specific module.
     *
     * @param moduleName the module name
     * @param level      the new log level
     * @return null on success, error on invalid level
     */
    public Object setModuleLogLevel(String moduleName, String level) {
        String upperLevel = level.toUpperCase();
        if (!VALID_LOG_LEVELS.contains(upperLevel)) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Invalid log level: '" + level + "'. Valid levels are: DEBUG, INFO, WARN, ERROR"));
        }
        moduleLogLevels.put(moduleName, upperLevel);
        return null;
    }

    /**
     * Remove the log level configuration for a specific module.
     *
     * @param moduleName the module name
     * @return true if the module was removed, false if it didn't exist
     */
    public boolean removeModuleLogLevel(String moduleName) {
        return moduleLogLevels.remove(moduleName) != null;
    }

    /**
     * Register a custom logger with a user-provided ID (visible to ICP).
     *
     * @param loggerId the user-provided logger ID
     * @param level    the initial log level of the logger
     * @return null on success, error if ID already exists
     */
    public Object registerCustomLoggerWithId(String loggerId, String level) {
        String upperLevel = level.toUpperCase();
        if (visibleCustomLoggerLevels.containsKey(loggerId)) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Logger with ID '" + loggerId + "' already exists"));
        }
        visibleCustomLoggerLevels.put(loggerId, upperLevel);
        allCustomLoggerLevels.put(loggerId, upperLevel);
        return null;
    }

    /**
     * Register a custom logger without a user-provided ID (not visible to ICP).
     * Generates an internal ID for log level checking purposes.
     *
     * @param level the initial log level of the logger
     * @return the generated internal logger ID
     */
    public String registerCustomLoggerInternal(String level) {
        String loggerId = "_internal_logger_" + loggerIdCounter.updateAndGet(n -> n + 1);
        String upperLevel = level.toUpperCase();
        allCustomLoggerLevels.put(loggerId, upperLevel);
        return loggerId;
    }

    /**
     * Get the log level for a custom logger (checks all loggers).
     *
     * @param loggerId the logger ID
     * @return the logger's log level, or null if not found
     */
    public String getCustomLoggerLevel(String loggerId) {
        return allCustomLoggerLevels.get(loggerId);
    }

    /**
     * Set the log level for a custom logger (only visible loggers can be modified).
     *
     * @param loggerId the logger ID
     * @param level    the new log level
     * @return null on success, error on invalid level or logger not found/not visible
     */
    public Object setCustomLoggerLevel(String loggerId, String level) {
        if (!visibleCustomLoggerLevels.containsKey(loggerId)) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Custom logger not found or not configurable: '" + loggerId + "'"));
        }
        String upperLevel = level.toUpperCase();
        if (!VALID_LOG_LEVELS.contains(upperLevel)) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Invalid log level: '" + level + "'. Valid levels are: DEBUG, INFO, WARN, ERROR"));
        }
        visibleCustomLoggerLevels.put(loggerId, upperLevel);
        allCustomLoggerLevels.put(loggerId, upperLevel);
        return null;
    }

    /**
     * Get all visible custom loggers and their levels (only user-named loggers).
     *
     * @return a map of logger IDs to log levels
     */
    public Map<String, String> getAllCustomLoggerLevels() {
        return new ConcurrentHashMap<>(visibleCustomLoggerLevels);
    }

    /**
     * Check if a log level is enabled for a module.
     *
     * @param loggerLogLevel the logger's configured log level
     * @param logLevel       the log level to check
     * @param moduleName     the module name
     * @return true if the log level is enabled
     */
    public boolean isLogLevelEnabled(String loggerLogLevel, String logLevel, String moduleName) {
        String effectiveLevel = loggerLogLevel;

        // Check module-specific level first
        String moduleLevel = moduleLogLevels.get(moduleName);
        if (moduleLevel != null) {
            effectiveLevel = moduleLevel;
        }

        // Compare log level weights
        int requestedWeight = LOG_LEVEL_WEIGHT.getOrDefault(logLevel.toUpperCase(), 0);
        int effectiveWeight = LOG_LEVEL_WEIGHT.getOrDefault(effectiveLevel.toUpperCase(), 800);

        return requestedWeight >= effectiveWeight;
    }

    /**
     * Check if a log level is enabled for a custom logger.
     *
     * @param loggerId   the custom logger ID
     * @param logLevel   the log level to check
     * @param moduleName the module name
     * @return true if the log level is enabled
     */
    public boolean isCustomLoggerLogLevelEnabled(String loggerId, String logLevel, String moduleName) {
        String loggerLevel = allCustomLoggerLevels.get(loggerId);
        if (loggerLevel == null) {
            // Logger not registered, use default
            loggerLevel = rootLogLevel.get();
        }
        return isLogLevelEnabled(loggerLevel, logLevel, moduleName);
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
     *
     * @return a map containing rootLevel and modules
     */
    public static BMap<BString, Object> getLogConfig() {
        LogConfigManager manager = getInstance();

        // Create the result map
        BMap<BString, Object> result = ValueCreator.createMapValue();

        // Add root level
        result.put(StringUtils.fromString("rootLevel"), StringUtils.fromString(manager.getRootLogLevel()));

        // Add modules as a map (module name -> level)
        Map<String, String> moduleLevels = manager.getAllModuleLogLevels();
        BMap<BString, Object> modulesMap = ValueCreator.createMapValue();
        for (Map.Entry<String, String> entry : moduleLevels.entrySet()) {
            modulesMap.put(StringUtils.fromString(entry.getKey()), StringUtils.fromString(entry.getValue()));
        }
        result.put(StringUtils.fromString("modules"), modulesMap);

        // Add custom loggers as a map (logger id -> level)
        Map<String, String> customLoggers = manager.getAllCustomLoggerLevels();
        BMap<BString, Object> customLoggersMap = ValueCreator.createMapValue();
        for (Map.Entry<String, String> entry : customLoggers.entrySet()) {
            customLoggersMap.put(StringUtils.fromString(entry.getKey()), StringUtils.fromString(entry.getValue()));
        }
        result.put(StringUtils.fromString("customLoggers"), customLoggersMap);

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
     *
     * @param moduleName the module name
     * @param level      the new log level
     * @return null on success, error on invalid level
     */
    public static Object setModuleLevel(BString moduleName, BString level) {
        return getInstance().setModuleLogLevel(moduleName.getValue(), level.getValue());
    }

    /**
     * Remove a module's log level configuration from Ballerina.
     *
     * @param moduleName the module name
     * @return true if removed, false if not found
     */
    public static boolean removeModuleLevel(BString moduleName) {
        return getInstance().removeModuleLogLevel(moduleName.getValue());
    }

    /**
     * Register a custom logger with a user-provided ID from Ballerina (visible to ICP).
     *
     * @param loggerId the user-provided logger ID
     * @param level    the initial log level
     * @return null on success, error if ID already exists
     */
    public static Object registerLoggerWithId(BString loggerId, BString level) {
        return getInstance().registerCustomLoggerWithId(loggerId.getValue(), level.getValue());
    }

    /**
     * Register a custom logger without ID from Ballerina (not visible to ICP).
     *
     * @param level the initial log level
     * @return the generated internal logger ID
     */
    public static BString registerLoggerInternal(BString level) {
        return StringUtils.fromString(getInstance().registerCustomLoggerInternal(level.getValue()));
    }

    /**
     * Set a custom logger's log level from Ballerina.
     *
     * @param loggerId the logger ID
     * @param level    the new log level
     * @return null on success, error on invalid level or logger not found
     */
    public static Object setLoggerLevel(BString loggerId, BString level) {
        return getInstance().setCustomLoggerLevel(loggerId.getValue(), level.getValue());
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
     * Check if a log level is enabled for a custom logger from Ballerina.
     *
     * @param loggerId   the custom logger ID
     * @param logLevel   the log level to check
     * @param moduleName the module name
     * @return true if enabled
     */
    public static boolean checkCustomLoggerLogLevelEnabled(BString loggerId, BString logLevel, BString moduleName) {
        return getInstance().isCustomLoggerLogLevelEnabled(
                loggerId.getValue(), logLevel.getValue(), moduleName.getValue());
    }
}

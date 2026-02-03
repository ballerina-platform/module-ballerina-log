/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org).
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

package io.ballerina.stdlib.log.testutils.nativeimpl;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.log.LogConfigManager;

/**
 * Test utility functions for LogConfigManager.
 * These functions expose the LogConfigManager APIs for testing purposes.
 *
 * @since 2.12.0
 */
public class LogConfigTestUtils {

    private LogConfigTestUtils() {
    }

    /**
     * Get the current log configuration for testing.
     *
     * @return BMap containing rootLevel, modules, and customLoggers
     */
    public static BMap<BString, Object> getLogConfig() {
        return LogConfigManager.getLogConfig();
    }

    /**
     * Get the current global log level for testing.
     *
     * @return the root log level
     */
    public static BString getGlobalLogLevel() {
        return LogConfigManager.getGlobalLogLevel();
    }

    /**
     * Set the global log level for testing.
     *
     * @param level the new log level
     * @return null on success, error on failure
     */
    public static Object setGlobalLogLevel(BString level) {
        return LogConfigManager.setGlobalLogLevel(level);
    }

    /**
     * Set a module's log level for testing.
     *
     * @param moduleName the module name
     * @param level the log level
     * @return null on success, error on failure
     */
    public static Object setModuleLogLevel(BString moduleName, BString level) {
        return LogConfigManager.setModuleLevel(moduleName, level);
    }

    /**
     * Remove a module's log level configuration for testing.
     *
     * @param moduleName the module name
     * @return true if removed, false if not found
     */
    public static boolean removeModuleLogLevel(BString moduleName) {
        return LogConfigManager.removeModuleLevel(moduleName);
    }

    /**
     * Set a custom logger's log level for testing.
     *
     * @param loggerId the logger ID
     * @param level the log level
     * @return null on success, error on failure
     */
    public static Object setCustomLoggerLevel(BString loggerId, BString level) {
        return LogConfigManager.setLoggerLevel(loggerId, level);
    }

    /**
     * Get the number of visible custom loggers for testing.
     *
     * @return count of visible custom loggers
     */
    public static long getVisibleCustomLoggerCount() {
        BMap<BString, Object> config = LogConfigManager.getLogConfig();
        BMap<BString, Object> customLoggers = (BMap<BString, Object>) config.get(
                StringUtils.fromString("customLoggers"));
        return customLoggers.size();
    }

    /**
     * Check if a custom logger is visible (has user-provided ID).
     *
     * @param loggerId the logger ID to check
     * @return true if visible, false otherwise
     */
    public static boolean isCustomLoggerVisible(BString loggerId) {
        BMap<BString, Object> config = LogConfigManager.getLogConfig();
        BMap<BString, Object> customLoggers = (BMap<BString, Object>) config.get(
                StringUtils.fromString("customLoggers"));
        return customLoggers.containsKey(loggerId);
    }
}

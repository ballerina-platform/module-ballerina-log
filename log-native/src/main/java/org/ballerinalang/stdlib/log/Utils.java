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

package org.ballerinalang.stdlib.log;

import io.ballerina.runtime.api.utils.IdentifierUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

import static java.lang.System.err;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

    public static final String GLOBAL_PACKAGE_PATH = ".";
    private static final Map<String, BLogLevel> loggerLevels = new HashMap<>();
    private static BLogLevel ballerinaUserLogLevel = BLogLevel.INFO; // default to INFO

    /**
     * Prints the log message in json format.
     *
     * @param msg log message
     */
    public static void printJsonExtern(BString msg) {
        err.println(msg.toString());
    }

    /**
     * Prints the log message in logFmt format.
     *
     * @param logRecord log record
     */
    public static void printLogFmtExtern(BMap<BString, Object> logRecord) {
        StringBuilder message = new StringBuilder();
        for (Map.Entry<BString, Object> entry : logRecord.entrySet()) {
            String key = entry.getKey().toString();
            String value;
            switch (entry.getKey().toString()) {
                case "time":
                    value = entry.getValue().toString();
                    break;
                case "level":
                    value = entry.getValue().toString();
                    if (value.equals("INFO") || value.equals("WARN")) {
                        value = value + " ";
                    }
                    break;
                case "module":
                    value = entry.getValue().toString();
                    if (value.equals("")) {
                        value = "\"" + value + "\"";
                    }
                    break;
                default:
                    if (entry.getValue() instanceof BString) {
                        value = "\"" + escape(entry.getValue().toString()) + "\"";
                    } else {
                        value = entry.getValue().toString();
                    }
                    break;
            }
            message.append(key).append(" = ").append(value).append(" ");
        }
        err.println(message);
    }

    /**
     * Sets the global log level.
     *
     * @param logLevel log level
     */
    public static void setGlobalLogLevelExtern(BString logLevel) {
        ballerinaUserLogLevel = BLogLevel.toBLogLevel(logLevel.getValue());
        loggerLevels.put(GLOBAL_PACKAGE_PATH, BLogLevel.toBLogLevel(logLevel.getValue()));
    }

    /**
     * Sets the module log level.
     *
     * @param module module
     * @param logLevel log level
     */
    public static void setModuleLogLevelExtern(BString module, BString logLevel) {
        loggerLevels.put(module.getValue(), BLogLevel.toBLogLevel(logLevel.getValue()));
    }

    /**
     * Checks if the given log level is enabled.
     *
     * @param logLevel log level
     * @return true if log level is enabled, false otherwise
     */
    public static boolean isLogLevelEnabledExtern(BString logLevel) {
        if (isModuleLogLevelEnabled()) {
            String moduleName = getModuleName().toString();
            return getPackageLogLevel(moduleName).value() <=
                    BLogLevel.toBLogLevel(logLevel.getValue()).value();
        } else {
            return getPackageLogLevel(GLOBAL_PACKAGE_PATH).value() <=
                    BLogLevel.toBLogLevel(logLevel.getValue()).value();
        }
    }

    /**
     * Get the name of the current module.
     *
     * @return module name
     */
    public static BString getModuleName() {
        String className = Thread.currentThread().getStackTrace()[5].getClassName();
        String[] pkgData = className.split("\\.");
        if (pkgData.length > 1) {
            String module = IdentifierUtils.decodeIdentifier(pkgData[1]);
            return StringUtils.fromString(pkgData[0] + "/" + module);
        }
        return StringUtils.fromString(".");
    }

    /**
     * Get the current time.
     *
     * @return current time in yyyy-MM-dd HH:mm:ss format
     */
    public static BString getCurrentTime() {
        LocalDateTime localDateTime = LocalDateTime.now();
        DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        return StringUtils.fromString(localDateTime.format(dateTimeFormatter));
    }

    private static String escape(String s) {
        return s.replace("\\", "\\\\")
                .replace("\t", "\\t")
                .replace("\b", "\\b")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\f", "\\f")
                .replace("'", "\\'")
                .replace("\"", "\\\"");
    }

    private static boolean isModuleLogLevelEnabled() {
        return loggerLevels.size() > 1;
    }

    private static BLogLevel getPackageLogLevel(String pkg) {
        return loggerLevels.containsKey(pkg) ? loggerLevels.get(pkg) : ballerinaUserLogLevel;
    }

    enum BLogLevel {
        ERROR(1000),
        WARN(900),
        INFO(800),
        DEBUG(700);

        private final int levelValue;

        BLogLevel(int levelValue) {
            this.levelValue = levelValue;
        }

        public int value() {
            return this.levelValue;
        }

        public static BLogLevel toBLogLevel(String logLevel) {
            try {
                return valueOf(logLevel);
            } catch (IllegalArgumentException var3) {
                throw new RuntimeException("invalid log level: " + logLevel);
            }
        }
    }
}

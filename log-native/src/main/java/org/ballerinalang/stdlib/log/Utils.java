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
import org.ballerinalang.logging.util.BLogLevel;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

    public static final String GLOBAL_PACKAGE_PATH = ".";
    private static String packagePath = GLOBAL_PACKAGE_PATH;
    private static Map<String, BLogLevel> loggerLevels = new HashMap<>();
    private static BLogLevel ballerinaUserLogLevel = BLogLevel.INFO; // default to INFO

    /**
     * Prints the log message.
     *
     * @param msg log message
     */
    public static void printJsonExtern(BString msg) {
        System.err.println(msg.toString());
    }

    public static void printLogFmtExtern(BMap<BString, Object> msg) {
        String message = "";
        for (Map.Entry<BString, Object> entry : msg.entrySet()) {
            String key = entry.getKey().toString();
            String value = "";
            if (entry.getKey().toString().equals("time")) {
                value = entry.getValue().toString();
            } else if (entry.getKey().toString().equals("level")) {
                value = entry.getValue().toString();
                if (value.equals("INFO") || value.equals("WARN")) {
                    value = value + " ";
                }
            } else if (entry.getKey().toString().equals("module")) {
                value = entry.getValue().toString();
                if (value.equals("")) {
                    value = "\"" + value + "\"";
                }
            } else {
                if (entry.getValue() instanceof BString) {
                    value = "\"" + escape(entry.getValue().toString()) + "\"";
                } else {
                    value = entry.getValue().toString();
                }
            }
            message = message + key + " = " + value + " ";
        }
        System.err.println(message);
    }

    /**
     * Checks if the given log level is enabled.
     *
     * @param logLevel log level
     * @return true if log level is enabled, false otherwise
     */
    public static boolean isLogLevelEnabledExtern(BString logLevel) {
        if (isModuleLogLevelEnabled()) {
            packagePath = getModuleName().toString();
            return getPackageLogLevel(packagePath).value() <= BLogLevel.toBLogLevel(logLevel.getValue())
                    .value();
        } else {
            if (getPackageLogLevel(GLOBAL_PACKAGE_PATH).value() <=
                    BLogLevel.toBLogLevel(logLevel.getValue()).value()) {
                packagePath = getModuleName().toString();
                return true;
            } else {
                return false;
            }
        }
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
     * Checks if module log level has been enabled.
     *
     * @return true if module log level has been enabled, false if not.
     */
    private static boolean isModuleLogLevelEnabled() {
        return loggerLevels.size() > 1;
    }

    /**
     * Get the log level of a given package.
     *
     * @param pkg package name
     * @return the log level
     */
    private static BLogLevel getPackageLogLevel(String pkg) {
        return loggerLevels.containsKey(pkg) ? loggerLevels.get(pkg) : ballerinaUserLogLevel;
    }

    public static BString getModuleName() {
        String className = Thread.currentThread().getStackTrace()[5].getClassName();
        String[] pkgData = className.split("\\.");
        if (pkgData.length > 1) {
            String module = IdentifierUtils.decodeIdentifier(pkgData[1]);
            return StringUtils.fromString(pkgData[0] + "/" + module);
        }
        return StringUtils.fromString(".");
    }

    public static BString getCurrentTime() {
        LocalDateTime localDateTime = LocalDateTime.now();
        DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        return StringUtils.fromString(localDateTime.format(dateTimeFormatter));
    }

    private static String escape(String s){
        return s.replace("\\", "\\\\")
                .replace("\t", "\\t")
                .replace("\b", "\\b")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\f", "\\f")
                .replace("\'", "\\'")
                .replace("\"", "\\\"");
    }

}

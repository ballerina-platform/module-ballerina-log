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

import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.logging.BLogManager;
import org.ballerinalang.logging.util.BLogLevel;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils extends AbstractLogFunction {

    private static String packagePath = BLogManager.GLOBAL_PACKAGE_PATH;

    /**
     * Prints the log message.
     *
     * @param logLevel log level
     * @param msg log message
     * @param format output format
     */
    public static void printExtern(BString logLevel, BString msg, BString format) {
        switch (BLogLevel.toBLogLevel(logLevel.getValue())) {
            case DEBUG:
                logMessage(msg, packagePath,
                        (pkg, message) -> {
                            getLogger(pkg).debug(message);
                        },
                        format.toString());
                break;
            case INFO:
                logMessage(msg, packagePath,
                        (pkg, message) -> {
                            getLogger(pkg).info(message);
                        },
                        format.toString());
                break;
            case ERROR:
                logMessage(msg, packagePath,
                        (pkg, message) -> {
                            getLogger(pkg).error(message);
                        },
                        format.toString());
                break;
            case WARN:
                logMessage(msg, packagePath,
                        (pkg, message) -> {
                            getLogger(pkg).warn(message);
                        },
                        format.toString());
                break;
            default:
                break;
        }
    }

    /**
     * Checks if the given log level is enabled.
     *
     * @param logLevel log level
     * @return true if log level is enabled, false otherwise
     */
    public static boolean isLogLevelEnabledExtern(BString logLevel) {
        if (LOG_MANAGER.isModuleLogLevelEnabled()) {
            packagePath = getPackagePath();
            return LOG_MANAGER.getPackageLogLevel(packagePath).value() <= BLogLevel.toBLogLevel(logLevel.getValue())
                    .value();
        } else {
            if (LOG_MANAGER.getPackageLogLevel(BLogManager.GLOBAL_PACKAGE_PATH).value() <=
                    BLogLevel.toBLogLevel(logLevel.getValue()).value()) {
                packagePath = getPackagePath();
                return true;
            } else {
                return false;
            }
        }
    }

    /**
     * Sets the module log level.
     *
     * @param logLevel log level
     */
    public static void setGlobalLogLevelExtern(BString logLevel) {
        LOG_MANAGER.setGlobalLogLevel(BLogLevel.toBLogLevel(logLevel.getValue()));
    }

    /**
     * Sets the log level.
     * @param module module
     * @param logLevel log level
     */
    public static void setModuleLogLevelExtern(BString module, BString logLevel) {
        LOG_MANAGER.setModuleLogLevel(BLogLevel.toBLogLevel(logLevel.getValue()), module.getValue());
    }
}

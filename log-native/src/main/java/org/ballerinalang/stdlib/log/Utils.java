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
import org.ballerinalang.logging.util.BLogLevel;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils extends AbstractLogFunction {

    public static boolean isLogLevelEnabled(BString logLevel) {
        if (LOG_MANAGER.isModuleLogLevelEnabled()) {
            return LOG_MANAGER.getPackageLogLevel(getPackagePath()).value() <= BLogLevel.toBLogLevel(logLevel.getValue()).value();
        } else {
            return LOG_MANAGER.getPackageLogLevel(".").value() <= BLogLevel.toBLogLevel(logLevel.getValue()).value();
        }
    }

    public static void logMessage(BString logLevel, Object msg) {
        switch (BLogLevel.toBLogLevel(logLevel.getValue())) {
            case WARN:
                logMessage(msg, BLogLevel.toBLogLevel(logLevel.getValue()), getPackagePath(),
                        (pkg, message) -> {
                            getLogger(pkg).warn(message);
                        });
                break;
            case INFO:
                logMessage(msg, BLogLevel.toBLogLevel(logLevel.getValue()), getPackagePath(),
                        (pkg, message) -> {
                            getLogger(pkg).info(message);
                        });
                break;
            case DEBUG:
                logMessage(msg, BLogLevel.toBLogLevel(logLevel.getValue()), getPackagePath(),
                        (pkg, message) -> {
                            getLogger(pkg).debug(message);
                        });
                break;
            case TRACE:
                logMessage(msg, BLogLevel.toBLogLevel(logLevel.getValue()), getPackagePath(),
                        (pkg, message) -> {
                            getLogger(pkg).trace(message);
                        });
                break;
            default:
                break;
        }
    }

    public static void logMessageWithError(BString logLevel, Object msg, Object err) {
        logMessage(msg, BLogLevel.ERROR, getPackagePath(),
                (pkg, message) -> {
                    String errorMsg = (err == null) ? "" : " : " + err.toString();
                    getLogger(pkg).error(message + errorMsg);
                });
    }

    public static void setModuleLogLevel(BString logLevel, Object moduleName) {
        String module;
        if (moduleName == null) {
            String className = Thread.currentThread().getStackTrace()[3].getClassName();
            String[] pkgData = className.split("\\.");
            if (pkgData.length > 1) {
                module = pkgData[0] + "/" + pkgData[1];
            } else {
                module =".";
            }
        } else {
            module = moduleName.toString();
        }
        String level = logLevel.getValue();
        LOG_MANAGER.setModuleLogLevel(BLogLevel.toBLogLevel(level), module);
    }
}

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

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

import static java.lang.System.err;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

    /**
     * Prints the log message in logFmt format.
     *
     * @param logRecord log record
     */
    public static BString printLogFmtExtern(BMap<BString, Object> logRecord) {
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
        return StringUtils.fromString(String.valueOf(message));
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
     * Get the current local time.
     *
     * @return current local time in RFC3339 format
     */
    public static BString getCurrentTime() {
        return StringUtils.fromString(
                new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX")
                        .format(new Date()));
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

    /**
     * Escapes a String.
     *
     * @param s String to escape
     * @return escaped String
     */
    public static BString escapeExtern(BString s) {
        return StringUtils.fromString(escape(s.getValue()));
    }
}

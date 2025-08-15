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

package io.ballerina.stdlib.log;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.IdentifierUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

    public static final String SIMPLE_DATA_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX";
    public static final String DOT_REGEX = "\\.";
    public static final String SLASH = "/";
    public static final String EMPTY_STRING = "";
    public static final String OFFSET_VALIDATION_ERROR = "Offset must be greater or equal to zero";
    public static final String BALLERINA_LOG_CLASS_NAME = "ballerina.log";
    public static final String INVOKED_FUNCTION_NAME = "getInvokedModuleName";

    private Utils() {

    }

    public static BString getInvokedModuleName(long offset) {
        if (offset < 0) {
            throw ErrorCreator.createError(StringUtils.fromString(OFFSET_VALIDATION_ERROR));
        }
        return StackWalker.getInstance()
                .walk(stackFrameStream -> {
                    // Skip frames until we find the Ballerina log natives frame
                    return stackFrameStream
                            .dropWhile(frame -> {
                                String className = frame.getClassName();
                                String methodName = frame.getMethodName();
                                return !(className.startsWith(BALLERINA_LOG_CLASS_NAME) &&
                                        methodName.matches(INVOKED_FUNCTION_NAME));
                            })
                            .skip(offset + 1)
                            .findFirst() // Get the next frame (caller)
                            .map(frame -> {
                                String className = frame.getClassName();
                                String[] pkgData = className.split(DOT_REGEX);
                                if (pkgData.length > 1) {
                                    String module = IdentifierUtils.decodeIdentifier(pkgData[1]);
                                    return StringUtils.fromString(pkgData[0] + SLASH + module);
                                }
                                return StringUtils.fromString(EMPTY_STRING);
                            })
                            .orElse(StringUtils.fromString(EMPTY_STRING));
                });
    }

    /**
     * Get the current local time.
     *
     * @return current local time in RFC3339 format
     */
    public static BString getCurrentTime() {
        return StringUtils.fromString(
                new SimpleDateFormat(SIMPLE_DATA_FORMAT)
                        .format(new Date()));
    }
}

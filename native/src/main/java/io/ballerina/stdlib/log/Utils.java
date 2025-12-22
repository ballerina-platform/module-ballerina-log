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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.IdentifierUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

    public static final String SIMPLE_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX";
    public static final String DOT_REGEX = "\\.";
    public static final String SLASH = "/";
    public static final String EMPTY_STRING = "";
    public static final String OFFSET_VALIDATION_ERROR = "Offset must be greater than or equal to zero";
    public static final String BALLERINA_LOG_CLASS_NAME = "ballerina.log";
    public static final String INVOKED_FUNCTION_NAME = "getInvokedModuleName";

    private Utils() {

    }

    // This method is used to traverse through the thread stacktrace to find the trace which invoked
    // the method: INVOKED_FUNCTION_NAME. The offset is to move up in the stacktrace.
    // This is implemented since we do not have a proper way to extract such information from
    // Ballerina runtime
    // Related issue: https://github.com/ballerina-platform/ballerina-lang/issues/35083
    // The proposed solution is to use a code modifier to add the module information, but it caused
    // performance issue in compilation. We may need to revisit that implementation or get
    // an API from runtime
    /**
     * Get the module name of the caller of the log native function.
     *
     * @param offset The offset to move up in the stack trace
     * @return The module name of the caller
     */
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
                                        methodName.equals(INVOKED_FUNCTION_NAME));
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
                new SimpleDateFormat(SIMPLE_DATE_FORMAT)
                        .format(new Date()));
    }

    public static BString toMaskedString(Environment env, Object value) {
        // Use try-with-resources for automatic cleanup
        try (MaskedStringBuilder builder = MaskedStringBuilder.create(env.getRuntime())) {
            return StringUtils.fromString(builder.build(value));
        }
    }

    /**
     * Get the current file size for a log file.
     * Called from Ballerina to check if size-based rotation is needed.
     * This method directly checks the file size without using LogRotationManager
     * to avoid caching issues with manager instances.
     *
     * @param filePath The log file path
     * @return File size in bytes
     */
    public static long getCurrentFileSize(BString filePath) {
        File file = new File(filePath.getValue());
        return file.exists() ? file.length() : 0;
    }

    /**
     * Get milliseconds since last rotation.
     * Called from Ballerina to check if time-based rotation is needed.
     *
     * @param filePath The log file path
     * @param rotationPolicy The rotation policy
     * @param maxFileSize Maximum file size in bytes
     * @param maxAgeInMillis Maximum age in milliseconds
     * @param maxBackupFiles Maximum number of backup files
     * @return Milliseconds since last rotation
     */
    public static long getTimeSinceLastRotation(BString filePath, BString rotationPolicy,
                                                  long maxFileSize, long maxAgeInMillis, long maxBackupFiles) {
        LogRotationManager manager = LogRotationManager.getInstance(
                filePath.getValue(), rotationPolicy.getValue(), maxFileSize, maxAgeInMillis, (int) maxBackupFiles);
        return manager.getTimeSinceLastRotation();
    }

    /**
     * Perform log rotation.
     * Called from Ballerina after determining rotation is needed.
     *
     * @param filePath The log file path
     * @param rotationPolicy The rotation policy
     * @param maxFileSize Maximum file size in bytes
     * @param maxAgeInMillis Maximum age in milliseconds
     * @param maxBackupFiles Maximum number of backup files
     * @return Error if rotation fails, null otherwise
     */
    public static Object rotateLog(BString filePath, BString rotationPolicy,
                                    long maxFileSize, long maxAgeInMillis, long maxBackupFiles) {
        LogRotationManager manager = LogRotationManager.getInstance(
                filePath.getValue(), rotationPolicy.getValue(), maxFileSize, maxAgeInMillis, (int) maxBackupFiles);
        return manager.rotate();
    }
}

// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/observe;

# Configuration for the Ballerina logger
public type Config record {|
    # Log format to use. Default is the logger format configured in the module level
    LogFormat format = format;
    # Log level to use. Default is the logger level configured in the module level
    Level level = level;
    # List of destinations to log to. Default is the logger destinations configured in the module level
    readonly & OutputDestination[] destinations = destinations;
    # Additional key-value pairs to include in the log messages. Default is the key-values configured in the module level
    readonly & AnydataKeyValues keyValues = {...keyValues};
    # Enable sensitive data masking. Default is the module level configuration
    boolean enableSensitiveDataMasking = enableSensitiveDataMasking;
|};

type ConfigInternal record {|
    LogFormat format = format;
    Level level = level;
    readonly & OutputDestination[] destinations = destinations;
    readonly & KeyValues keyValues = {...keyValues};
    boolean enableSensitiveDataMasking = enableSensitiveDataMasking;
|};

final string ICP_RUNTIME_ID_KEY = "icp.runtimeId";

final RootLogger rootLogger;

# Returns the root logger instance.
#
# + return - The root logger instance
public isolated function root() returns Logger => rootLogger;

# Creates a new logger with the given configuration.
#
# + config - The configuration to use for the new logger
# + return - The newly created logger
public isolated function fromConfig(*Config config) returns Logger|Error {
    check validateDestinations(config.destinations);
    // Copy the initial context from the global configs
    // Only the key value pair
    AnydataKeyValues newKeyValues = {...keyValues};
    foreach [string, Value] [k, v] in config.keyValues.entries() {
        newKeyValues[k] = v;
    }
    Config newConfig = {
        format: config.format,
        level: config.level,
        destinations: config.destinations,
        keyValues: newKeyValues.cloneReadOnly(),
        enableSensitiveDataMasking: config.enableSensitiveDataMasking
    };
    return new RootLogger(newConfig);
}

isolated class RootLogger {
    *Logger;

    private final LogFormat format;
    private final Level level;
    private final readonly & OutputDestination[] destinations;
    private final readonly & KeyValues keyValues;
    private final boolean enableSensitiveDataMasking;

    public isolated function init(Config|ConfigInternal config = <Config>{}) {
        self.format = config.format;
        self.level = config.level;
        self.destinations = config.destinations;
        self.keyValues = config.keyValues;
        self.enableSensitiveDataMasking = config.enableSensitiveDataMasking;
    }

    public isolated function printDebug(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        string moduleName = getModuleName(keyValues, 3);
        self.print(DEBUG, moduleName, msg, 'error, stackTrace, keyValues);
    }

    public isolated function printError(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        string moduleName = getModuleName(keyValues, 3);
        self.print(ERROR, moduleName, msg, 'error, stackTrace, keyValues);
    }

    public isolated function printInfo(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        string moduleName = getModuleName(keyValues, 3);
        self.print(INFO, moduleName, msg, 'error, stackTrace, keyValues);
    }

    public isolated function printWarn(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        string moduleName = getModuleName(keyValues, 3);
        self.print(WARN, moduleName, msg, 'error, stackTrace, keyValues);
    }

    public isolated function withContext(*KeyValues keyValues) returns Logger {
        KeyValues newKeyValues = {...self.keyValues};
        foreach [string, Value] [k, v] in keyValues.entries() {
            newKeyValues[k] = v;
        }
        ConfigInternal config = {
            format: self.format,
            level: self.level,
            destinations: self.destinations,
            keyValues: newKeyValues.cloneReadOnly(),
            enableSensitiveDataMasking: self.enableSensitiveDataMasking
        };
        return new RootLogger(config);
    }

    isolated function print(string logLevel, string moduleName, string|PrintableRawTemplate msg, error? err = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
        if !isLogLevelEnabled(self.level, logLevel, moduleName) {
            return;
        }
        LogRecord logRecord = {
            time: getCurrentTime(),
            level: logLevel,
            module: moduleName,
            message: processMessage(msg, self.enableSensitiveDataMasking)
        };
        if err is error {
            logRecord.'error = getFullErrorDetails(err);
        }
        if stackTrace is error:StackFrame[] {
            logRecord["stackTrace"] = from var element in stackTrace
                select element.toString();
        }
        foreach [string, Value] [k, v] in keyValues.entries() {
            logRecord[k] = v is Valuer ? v() : 
                (v is PrintableRawTemplate ? evaluateTemplate(v, self.enableSensitiveDataMasking) : v);
        }
        if observe:isTracingEnabled() {
            map<string> spanContext = observe:getSpanContext();
            foreach [string, string] [k, v] in spanContext.entries() {
                logRecord[k] = v;
            }
        }
        if observe:isObservabilityEnabled() {
            string? runtimeId = observe:getTagValue(ICP_RUNTIME_ID_KEY);
            if runtimeId is string {
                logRecord[ICP_RUNTIME_ID_KEY] = runtimeId;
            }
        }

        foreach [string, Value] [k, v] in self.keyValues.entries() {
            logRecord[k] = v is Valuer ? v() : 
                (v is PrintableRawTemplate ? evaluateTemplate(v, self.enableSensitiveDataMasking) : v);
        }

        string logOutput = self.format == JSON_FORMAT ?
            (self.enableSensitiveDataMasking ? toMaskedString(logRecord) : logRecord.toJsonString()) :
            printLogFmt(logRecord, self.enableSensitiveDataMasking);

        lock {
            if outputFilePath is string {
                fileWrite(logOutput);
            }
        }

        foreach OutputDestination destination in self.destinations {
            if destination is StandardDestination {
                if destination.'type == STDERR {
                    io:fprintln(io:stderr, logOutput);
                } else {
                    io:fprintln(io:stdout, logOutput);
                }
            } else {
                // File destination
                RotationConfig? rotationConfig = destination.rotation;
                if rotationConfig is () {
                    // No rotation configured, write directly without lock
                    writeLogToFile(destination.path, logOutput);
                } else {
                    // Rotation configured, use lock to ensure thread-safe rotation and writing
                    // This prevents writes from happening during rotation
                    lock {
                        error? rotationResult = checkAndPerformRotation(destination.path, rotationConfig);
                        if rotationResult is error {
                            io:fprintln(io:stderr, string `warning: log rotation failed: ${rotationResult.message()}`);
                        }
                        writeLogToFile(destination.path, logOutput);
                    }
                }
            }
        }
    }
}

// Helper function to check if rotation is needed and perform it
// This implements the rotation checking logic in Ballerina, calling Java only for the actual rotation
isolated function checkAndPerformRotation(string filePath, RotationConfig rotationConfig) returns error? {
    // Rotation parameters are already validated during initialization
    RotationPolicy policy = rotationConfig.policy;
    int maxFileSize = rotationConfig.maxFileSize;
    int maxAge = rotationConfig.maxAge;
    int maxBackupFiles = rotationConfig.maxBackupFiles;

    // Check if rotation is needed
    boolean shouldRotate = false;

    // Check size-based rotation
    if policy == SIZE_BASED || policy == BOTH {
        int currentSize = getCurrentFileSize(filePath);
        if currentSize >= maxFileSize {
            shouldRotate = true;
        }
    }

    // Check time-based rotation
    if policy == TIME_BASED || policy == BOTH {
        // Convert maxAge from seconds to milliseconds
        int maxAgeInMillis = maxAge * 1000;
        int timeSinceRotation = getTimeSinceLastRotation(filePath, policy, maxFileSize, maxAgeInMillis, maxBackupFiles);
        if timeSinceRotation >= maxAgeInMillis {
            shouldRotate = true;
        }
    }

    // Perform rotation if needed
    if shouldRotate {
        // Convert maxAge to milliseconds for Java
        int maxAgeInMillis = maxAge * 1000;
        return rotateLog(filePath, policy, maxFileSize, maxAgeInMillis, maxBackupFiles);
    }
}

// Helper function to write log output to a file
isolated function writeLogToFile(string filePath, string logOutput) {
    io:Error? result = io:fileWriteString(filePath, logOutput + "\n", io:APPEND);
    if result is error {
        io:fprintln(io:stderr, string `error: failed to write log output to the file: ${result.message()}`);
    }
}

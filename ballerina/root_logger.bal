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
    # Optional unique identifier for this logger.
    # All loggers are registered and can be discovered via `getLoggerRegistry()`.
    # If provided, this value is used as the logger's runtime ID (prefixed with the module name);
    # otherwise, an ID is auto-generated from the calling context.
    string id?;
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

// Ballerina-side logger registry: loggerId -> Logger
isolated map<Logger> loggerRegistry = {};


# Provides access to the logger registry for discovering and managing registered loggers.
public type LoggerRegistry isolated object {
    # Returns the IDs of all registered loggers.
    #
    # + return - An array of logger IDs
    public isolated function getIds() returns string[];

    # Returns a logger by its registered ID.
    #
    # + id - The logger ID to look up
    # + return - The Logger instance if found, nil otherwise
    public isolated function getById(string id) returns Logger?;
};

isolated class LoggerRegistryImpl {
    *LoggerRegistry;

    public isolated function getIds() returns string[] {
        lock {
            return loggerRegistry.keys().clone();
        }
    }

    public isolated function getById(string id) returns Logger? {
        lock {
            return loggerRegistry[id];
        }
    }
}

final LoggerRegistry loggerRegistryInstance = new LoggerRegistryImpl();

# Returns the logger registry for discovering and managing registered loggers.
#
# + return - The LoggerRegistry instance
public isolated function getLoggerRegistry() returns LoggerRegistry => loggerRegistryInstance;

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

    readonly & ConfigInternal newConfig = {
        format: config.format,
        level: config.level,
        destinations: config.destinations,
        keyValues: newKeyValues.cloneReadOnly(),
        enableSensitiveDataMasking: config.enableSensitiveDataMasking
    };

    if config.id is string {
        // Explicit user ID — module-prefix it: <module>:<user_id>.
        // getInvokedModuleName(3): skip getInvokedModuleName -> fromConfig -> caller
        string moduleName = getInvokedModuleName(3);
        string loggerId = moduleName.length() > 0 ? moduleName + ":" + <string>config.id : <string>config.id;
        RootLogger logger = new RootLogger(newConfig, loggerId);
        lock {
            if loggerRegistry.hasKey(loggerId) {
                return error Error("Logger with ID '" + loggerId + "' already exists");
            }
            loggerRegistry[loggerId] = logger;
        }
        return logger;
    }

    // No user ID — auto-generate a readable ID and guarantee uniqueness inside the lock.
    // Stack offset 4: skip generateLoggerId (Java) -> generateLoggerIdNative -> fromConfig -> caller
    string baseId = generateLoggerIdNative(4);
    lock {
        string loggerId = baseId;
        int suffix = 2;
        while loggerRegistry.hasKey(loggerId) {
            loggerId = baseId + "-" + suffix.toString();
            suffix += 1;
        }
        RootLogger logger = new RootLogger(newConfig, loggerId);
        loggerRegistry[loggerId] = logger;
        return logger;
    }
}

isolated class RootLogger {
    *Logger;

    private final LogFormat format;
    private Level currentLevel;
    private final readonly & OutputDestination[] destinations;
    private final readonly & KeyValues keyValues;
    private final boolean enableSensitiveDataMasking;
    // Unique ID for loggers registered with LogConfigManager
    private final string? loggerId;

    public isolated function init(Config|ConfigInternal config = <Config>{}, string? loggerId = ()) {
        self.format = config.format;
        self.currentLevel = config.level;
        self.destinations = config.destinations;
        self.keyValues = config.keyValues;
        self.enableSensitiveDataMasking = config.enableSensitiveDataMasking;
        self.loggerId = loggerId;
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
        return new ChildLogger(self, newKeyValues.cloneReadOnly());
    }

    public isolated function getLevel() returns Level {
        lock {
            return self.currentLevel;
        }
    }

    public isolated function setLevel(Level level) returns error? {
        lock {
            self.currentLevel = level;
        }
    }

    isolated function print(string logLevel, string moduleName, string|PrintableRawTemplate msg, error? err = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
        Level effectiveLevel = self.getLevel();
        if moduleName.length() > 0 {
            Level? moduleLevel = getModuleLevelNative(moduleName);
            if moduleLevel is Level {
                effectiveLevel = moduleLevel;
            }
        }
        if !isLevelEnabled(effectiveLevel, logLevel) {
            return;
        }
        printLog(logLevel, moduleName, msg, self.format, self.destinations, self.keyValues,
                self.enableSensitiveDataMasking, err, stackTrace, keyValues);
    }
}

isolated class ChildLogger {
    *Logger;

    private final Logger parent;
    private final readonly & KeyValues keyValues;

    public isolated function init(Logger parent, readonly & KeyValues keyValues) {
        self.parent = parent;
        self.keyValues = keyValues;
    }

    public isolated function printDebug(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        KeyValues merged = self.mergeKeyValues(keyValues);
        if !merged.hasKey("module") {
             merged["module"] = getInvokedModuleName(2);
        }
        self.parent.printDebug(msg, 'error, stackTrace, merged);
    }

    public isolated function printError(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        KeyValues merged = self.mergeKeyValues(keyValues);
        if !merged.hasKey("module") {
             merged["module"] = getInvokedModuleName(2);
        }
        self.parent.printError(msg, 'error, stackTrace, merged);
    }

    public isolated function printInfo(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        KeyValues merged = self.mergeKeyValues(keyValues);
        if !merged.hasKey("module") {
             merged["module"] = getInvokedModuleName(2);
        }
        self.parent.printInfo(msg, 'error, stackTrace, merged);
    }

    public isolated function printWarn(string|PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *KeyValues keyValues) {
        KeyValues merged = self.mergeKeyValues(keyValues);
        if !merged.hasKey("module") {
             merged["module"] = getInvokedModuleName(2);
        }
        self.parent.printWarn(msg, 'error, stackTrace, merged);
    }

    public isolated function withContext(*KeyValues keyValues) returns Logger {
        KeyValues newKeyValues = {...self.keyValues};
        foreach [string, Value] [k, v] in keyValues.entries() {
            newKeyValues[k] = v;
        }
        return new ChildLogger(self, newKeyValues.cloneReadOnly());
    }

    public isolated function getLevel() returns Level {
        return self.parent.getLevel();
    }

    public isolated function setLevel(Level level) returns error? {
        return error Error("Unsupported operation: cannot set log level on a child logger. " +
                "Child loggers inherit their level from the parent logger.");
    }

    private isolated function mergeKeyValues(KeyValues callSiteKeyValues) returns KeyValues {
        KeyValues merged = {};
        foreach [string, Value] [k, v] in callSiteKeyValues.entries() {
            merged[k] = v;
        }
        foreach [string, Value] [k, v] in self.keyValues.entries() {
            if !merged.hasKey(k) {
                merged[k] = v;
            }
        }
        string? runtimeId = observe:getTagValue(ICP_RUNTIME_ID_KEY);
        if runtimeId is string {
            merged[ICP_RUNTIME_ID_KEY] = runtimeId;
        }
        return merged;
    }
}

isolated function printLog(string logLevel, string moduleName, string|PrintableRawTemplate msg,
        LogFormat format, readonly & OutputDestination[] destinations, readonly & KeyValues contextKeyValues,
        boolean enableSensitiveDataMasking, error? err = (), error:StackFrame[]? stackTrace = (),
        KeyValues callSiteKeyValues = {}) {
    LogRecord logRecord = {
        time: getCurrentTime(),
        level: logLevel,
        module: moduleName,
        message: processMessage(msg, enableSensitiveDataMasking)
    };
    if err is error {
        logRecord.'error = getFullErrorDetails(err);
    }
    if stackTrace is error:StackFrame[] {
        logRecord["stackTrace"] = from var element in stackTrace
            select element.toString();
    }
    // Apply in ascending priority order: context < call-site < tracing/observe.
    // For child loggers, contextKeyValues is the parent's own context; callSiteKeyValues
    // carries the already-merged {child context + call-site} result, so child wins over parent.
    foreach [string, Value] [k, v] in contextKeyValues.entries() {
        logRecord[k] = v is Valuer ? v() :
            (v is PrintableRawTemplate ? evaluateTemplate(v, enableSensitiveDataMasking) : v);
    }
    foreach [string, Value] [k, v] in callSiteKeyValues.entries() {
        logRecord[k] = v is Valuer ? v() :
            (v is PrintableRawTemplate ? evaluateTemplate(v, enableSensitiveDataMasking) : v);
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

    string logOutput = format == JSON_FORMAT ?
        (enableSensitiveDataMasking ? toMaskedString(logRecord) : logRecord.toJsonString()) :
        printLogFmt(logRecord, enableSensitiveDataMasking);

    lock {
        if outputFilePath is string {
            fileWrite(logOutput);
        }
    }

    foreach OutputDestination destination in destinations {
        if destination is StandardDestination {
            if destination.'type == STDERR {
                io:fprintln(io:stderr, logOutput);
            } else {
                io:fprintln(io:stdout, logOutput);
            }
        } else {
            RotationConfig? rotationConfig = destination.rotation;
            if rotationConfig is () {
                writeLogToFile(destination.path, logOutput);
            } else {
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

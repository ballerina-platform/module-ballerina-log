// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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
import ballerina/jballerina.java;
import ballerina/lang.value;

# Represents log level types.
public enum Level {
    DEBUG,
    ERROR,
    INFO,
    WARN
}

# A value of `anydata` type or a function pointer or raw template.
public type Value anydata|Valuer|PrintableRawTemplate;

# Represents raw templates for logging.
#
# e.g: `The input value is ${val}`
# + strings - String values of the template as an array
# + insertions - Parameterized values/expressions after evaluations as an array
public type PrintableRawTemplate readonly & object {
    *object:RawTemplate;
    public string[] & readonly strings;
    public Value[] insertions;
};

# A function, which returns `anydata` type.
public type Valuer isolated function () returns anydata;

# Key-Value pairs that needs to be displayed in the log.
#
# + msg - msg which cannot be a key
# + message - message which cannot be a key
# + 'error - 'error which cannot be a key
# + stackTrace - stackTrace which cannot be a key
public type KeyValues record {|
    never msg?;
    never message?;
    never 'error?;
    never stackTrace?;
    Value...;
|};

# Anydata key-value pairs that needs to be displayed in the log.
public type AnydataKeyValues record {
    # msg which cannot be a key
    never msg?;
    # message which cannot be a key
    never message?;
    # 'error which cannot be a key
    never 'error?;
    # stackTrace which cannot be a key
    never stackTrace?;
    # module name which cannot be a key
    never module?;
};

type Module record {
    readonly string name;
    readonly Level level;
};

# Represents supported log formats.
public enum LogFormat {
    # JSON log format.
    JSON_FORMAT = "json",
    # Logfmt log format.
    LOGFMT = "logfmt"
};

# Root logger default log format.
public configurable LogFormat format = LOGFMT;

# Root logger default log level.
public configurable Level level = INFO;

# Modules with their log levels.
public configurable table<Module> key(name) & readonly modules = table [];

# Default key-values to add to the root logger.
public configurable AnydataKeyValues & readonly keyValues = {};

# Output destination types.
public enum DestinationType {
    # Standard error output as destination
    STDERR = "stderr",
    # Standard output as destination
    STDOUT = "stdout",
    # File output as destination
    FILE = "file"
};

# Standard destination.
public type StandardDestination record {|
    # Type of the standard destination. Allowed values are "stderr" and "stdout"
    readonly STDERR|STDOUT 'type = STDERR;
|};

# File output modes.
public enum FileOutputMode {
    # Truncates the file before writing. This mode creates a new file if one doesn't exist. 
    # If the file already exists, its contents are cleared, and new data is written 
    # from the beginning.
    TRUNCATE,
    # Appends to the existing content. This mode creates a new file if one doesn't exist. 
    # If the file already exists, new data is appended to the end of its current contents.
    APPEND
};

// Defined as an open record to allow for future extensions
# File output destination
public type FileOutputDestination record {
    # Type of the file destination. Allowed value is "file".
    readonly FILE 'type = FILE;
    # File path(only files with .log extension are supported)
    string path;
    # File output mode
    FileOutputMode mode = APPEND;
};

# Log output destination.
public type OutputDestination StandardDestination|FileOutputDestination;

# Destinations is a list of file destinations or standard output/error.
public configurable readonly & OutputDestination[] destinations = [{'type: STDERR}];

type LogRecord record {
    string time;
    string level;
    string module;
    string message;
    FullErrorDetails 'error?;
};

final map<int> & readonly logLevelWeight = {
    ERROR: 1000,
    WARN: 900,
    INFO: 800,
    DEBUG: 700
};

isolated string? outputFilePath = ();

# Represents file opening options for writing.
#
# + OVERWRITE - Overwrite(truncate the existing content)
# + APPEND - Append to the existing content
public enum FileWriteOption {
    OVERWRITE,
    APPEND
}

# Process the raw template and return the processed string.
#
# + template - The raw template to be processed
# + return - The processed string
# 
# # Deprecated
# The `processTemplate` function is deprecated. Use `evaluateTemplate` instead.
@deprecated
public isolated function processTemplate(PrintableRawTemplate template) returns string {
    string[] templateStrings = template.strings;
    Value[] insertions = template.insertions;
    string result = templateStrings[0];

    foreach int i in 1 ..< templateStrings.length() {
        Value insertion = insertions[i - 1];
        string insertionStr = insertion is PrintableRawTemplate ?
            processTemplate(insertion) :
                insertion is Valuer ?
                insertion().toString() :
                insertion.toString();
        result += insertionStr + templateStrings[i];
    }
    return result;
}

# Evaluates the raw template and returns the evaluated string.
# 
# + template - The raw template to be evaluated
# + enableSensitiveDataMasking - Flag to indicate if sensitive data masking is enabled
# + return - The evaluated string
public isolated function evaluateTemplate(PrintableRawTemplate template, boolean enableSensitiveDataMasking = false) returns string {
    string[] templateStrings = template.strings;
    Value[] insertions = template.insertions;
    string result = templateStrings[0];

    foreach int i in 1 ..< templateStrings.length() {
        Value insertion = insertions[i - 1];
        string insertionStr = insertion is PrintableRawTemplate ?
            evaluateTemplate(insertion, enableSensitiveDataMasking) :
                insertion is Valuer ?
                (enableSensitiveDataMasking ? toMaskedString(insertion()) : insertion().toString()) :
                (enableSensitiveDataMasking ? toMaskedString(insertion) : insertion.toString());
        result += insertionStr + templateStrings[i];
    }
    return result;
}

isolated function processMessage(string|PrintableRawTemplate msg, boolean enableSensitiveDataMasking) returns string =>
    msg !is string ? evaluateTemplate(msg, enableSensitiveDataMasking) : msg;

# Prints debug logs.
# ```ballerina
# log:printDebug("debug message", id = 845315)
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + stackTrace - The error stack trace to be logged
# + keyValues - The key-value pairs to be logged
public isolated function printDebug(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    // Added `stackTrace` as an optional param due to https://github.com/ballerina-platform/ballerina-lang/issues/34572
    string moduleName = getModuleName(keyValues);
    rootLogger.print(DEBUG, moduleName, msg, 'error, stackTrace, keyValues);
}

# Prints error logs.
# ```ballerina
# error e = error("error occurred");
# log:printError("error log with cause", 'error = e, id = 845315);
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + stackTrace - The error stack trace to be logged
# + keyValues - The key-value pairs to be logged
public isolated function printError(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    string moduleName = getModuleName(keyValues);
    rootLogger.print(ERROR, moduleName, msg, 'error, stackTrace, keyValues);
}

# Prints info logs.
# ```ballerina
# log:printInfo("info message", id = 845315)
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + stackTrace - The error stack trace to be logged
# + keyValues - The key-value pairs to be logged
public isolated function printInfo(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    string moduleName = getModuleName(keyValues);
    rootLogger.print(INFO, moduleName, msg, 'error, stackTrace, keyValues);
}

# Prints warn logs.
# ```ballerina
# log:printWarn("warn message", id = 845315)
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + stackTrace - The error stack trace to be logged
# + keyValues - The key-value pairs to be logged
public isolated function printWarn(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    string moduleName = getModuleName(keyValues);
    rootLogger.print(WARN, moduleName, msg, 'error, stackTrace, keyValues);
}

# Set the log output to a file. Note that all the subsequent logs of the entire application will be written to this file.
# ```ballerina
# var result = log:setOutputFile("./resources/myfile.log");
# var result = log:setOutputFile("./resources/myfile.log", log:OVERWRITE);
# ```
#
# + path - The path of the file
# + option - To indicate whether to overwrite or append the log output
#
# + return - A `log:Error` if an invalid file path was provided
# # Deprecated
# Setting output file destination using this method is deprecated. 
# Add the output file path as part of the `destinations` configurable instead.
@deprecated
public isolated function setOutputFile(string path, FileWriteOption option = APPEND) returns Error? {
    // Deprecated usage warning. The default option is STDERR
    if destinations != [{'type: STDERR}] {
        io:fprintln(io:stderr, "warning: deprecated `setOutputFile` function is being called along with the destinations configurations. Consider adding the file path set by the `setOutputFile` function to the destinations list.");
    }
    if !path.endsWith(".log") {
        return error Error("The given path is not valid. Should be a file with .log extension.");
    }
    if option == OVERWRITE {
        io:Error? result = io:fileWriteString(path, "");
        if result is error {
            return error Error("Failed to set log output file", result);
        }
    }
    lock {
        outputFilePath = path;
    }
}

type StackFrame record {|
    string callableName;
    string? moduleName;
    string fileName;
    int lineNumber;
|};

type ErrorDetail record {|
    json|string message;
    json|string detail;
    StackFrame[] stackTrace;
|};

type FullErrorDetails record {|
    *ErrorDetail;
    ErrorDetail[] causes;
|};

isolated function getFullErrorDetails(error err) returns FullErrorDetails {
    ErrorDetail[] causes = [];
    error? errCause = err.cause();

    while errCause != () {
        causes.push({message: parseErrorMessage(errCause.message()), stackTrace: parseStackTrace(errCause.stackTrace()), detail: parseErrorDetail(errCause.detail())});
        errCause = errCause.cause();
    }

    return {message: parseErrorMessage(err.message()), stackTrace: parseStackTrace(err.stackTrace()), detail: parseErrorDetail(err.detail()), causes};
}

isolated function parseStackTrace(error:StackFrame[] stackTrace) returns StackFrame[] {
    StackFrame[] stackFrames = [];
    foreach error:StackFrame item in stackTrace {
        java:StackFrameImpl stackFrameImpl = <java:StackFrameImpl>item;
        StackFrame stackFrame = {
            callableName: stackFrameImpl.callableName,
            fileName: stackFrameImpl.fileName,
            moduleName: stackFrameImpl.moduleName,
            lineNumber: stackFrameImpl.lineNumber
        };
        stackFrames.push(stackFrame);
    }
    return stackFrames;
}

isolated function parseErrorMessage(string message) returns json|string {
    json|error errMessage = value:fromJsonString(message);
    if errMessage is json {
        return errMessage;
    } else {
        return message;
    }
}

isolated function parseErrorDetail(error:Detail detail) returns json|string {
    return detail is anydata ? detail.toJson() : detail.toBalString();
}

isolated function fileWrite(string logOutput) {
    string output = logOutput;
    string? path = ();
    lock {
        path = outputFilePath;
        if path is string {
            io:Error? result = io:fileWriteString(path, output + "\n", io:APPEND);
            if result is error {
                printError("failed to write log output to the file", 'error = result);
            }
        }
    }
}

isolated function printLogFmt(LogRecord logRecord, boolean enableSensitiveDataMasking = false) returns string {
    string message = "";
    foreach [string, anydata] [k, v] in logRecord.entries() {
        string value;
        match k {
            "time"|"level" => {
                value = v.toString();
            }
            "module" => {
                value = v.toString();
                if value == "" {
                    value = "\"\"";
                }
            }
            "error" => {
                value = v.toBalString();
            }
            _ => {
                string strValue = enableSensitiveDataMasking ? toMaskedString(v) : v.toString();
                value = v is string ? string `${escape(strValue)}` : strValue;
            }
        }
        if message == "" {
            message = message + string `${k}=${value}`;
        } else {
            message = message + string ` ${k}=${value}`;
        }
    }
    return message;
}

isolated function escape(string msg) returns string {
    handle temp = replaceString(java:fromString(msg), java:fromString("\\"), java:fromString("\\\\"));
    temp = replaceString(temp, java:fromString("\t"), java:fromString("\\t"));
    temp = replaceString(temp, java:fromString("\n"), java:fromString("\\n"));
    temp = replaceString(temp, java:fromString("\r"), java:fromString("\\r"));
    temp = replaceString(temp, java:fromString("'"), java:fromString("\\'"));
    temp = replaceString(temp, java:fromString("\""), java:fromString("\\\""));
    string? updatedString = java:toString(temp);
    return updatedString.toBalString();
}

isolated function replaceString(handle receiver, handle target, handle replacement) returns handle = @java:Method {
    'class: "java.lang.String",
    name: "replace",
    paramTypes: ["java.lang.CharSequence", "java.lang.CharSequence"]
} external;

isolated function isLogLevelEnabled(string loggerLogLevel, string logLevel, string moduleName) returns boolean {
    string moduleLogLevel = loggerLogLevel;
    if modules.length() > 0 {
        if modules.hasKey(moduleName) {
            moduleLogLevel = modules.get(moduleName).level;
        }
    }
    return logLevelWeight.get(logLevel) >= logLevelWeight.get(moduleLogLevel);
}

isolated function getModuleName(KeyValues keyValues, int offset = 2) returns string {
    Value module = keyValues["module"];
    return module is () ? getInvokedModuleName(offset) : (module is string ? module : "");
}

isolated function getInvokedModuleName(int offset = 0) returns string = @java:Method {'class: "io.ballerina.stdlib.log.Utils"} external;

isolated function getCurrentTime() returns string = @java:Method {'class: "io.ballerina.stdlib.log.Utils"} external;

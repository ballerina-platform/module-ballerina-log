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

# Represents a value that can be of type `anydata`, a function pointer, or a raw template.
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

# Represents a function that returns a value of type `anydata`.
# It is particularly useful in scenarios where there is a computation required to retrieve the value.
# This function is executed only if the specific log level is enabled.
public type Valuer isolated function () returns anydata;

# Represents key-value pairs that need to be displayed in the log.
#
# + msg - The message, which cannot be used as a key
# + 'error - The error, which cannot be used as a key
# + stackTrace - The error stack trace, which cannot be used as a key
public type KeyValues record {|
    never msg?;
    never 'error?;
    never stackTrace?;
    Value...;
|};

# Represents anydata key-value pairs that need to be displayed in the log.
public type AnydataKeyValues record {
    # The message, which cannot be used as a key
    never msg?;
    # The error, which cannot be used as a key
    never 'error?;
    # The error stack trace, which cannot be used as a key
    never stackTrace?;
    # The module name, which cannot be used as a key
    never module?;
};

type Module record {
    readonly string name;
    readonly Level level;
};

# Represents supported log formats.
public enum LogFormat {
    # The JSON log format.
    JSON_FORMAT = "json",
    # The Logfmt log format.
    LOGFMT = "logfmt"
};

# Represents root logger default log format.
public configurable LogFormat format = LOGFMT;

# Represents root logger default log level.
public configurable Level level = INFO;

# Represents modules with their log levels.
public configurable table<Module> key(name) & readonly modules = table [];

# Represents default key-values to add to the root logger.
public configurable AnydataKeyValues & readonly keyValues = {};

# Represents output destination types.
public enum DestinationType {
    # Standard error output as the destination
    STDERR = "stderr",
    # Standard output as the destination
    STDOUT = "stdout",
    # File output as the destination
    FILE = "file"
};

# Represents a standard destination.
public type StandardDestination record {|
    # Type of the standard destination. Allowed values are "stderr" and "stdout"
    readonly STDERR|STDOUT 'type = STDERR;
|};

# Represents file output modes.
public enum FileOutputMode {
    # Truncates the file before writing. Creates a new file if one doesn't exist.
    # If the file already exists, its contents are cleared, and new data is written
    # from the beginning.
    TRUNCATE,
    # Appends to the existing content. Creates a new file if one doesn't exist.
    # If the file already exists, new data is appended to the end of its current contents.
    APPEND
};

// Defined as an open record to allow for future extensions
# Represents a file output destination.
public type FileOutputDestination record {
    # The type of the file destination. The allowed value is "file"
    readonly FILE 'type = FILE;
    # The file path. Only files with a `.log` extension are supported
    string path;
    # The file output mode. The default value is `APPEND`
    FileOutputMode mode = APPEND;
};

# Represents the log output destination.
public type OutputDestination StandardDestination|FileOutputDestination;

# Represents a list of file destinations or standard output/error.
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
# + OVERWRITE - Overwrites the file by truncating the existing content
# + APPEND - Appends new content to the existing file
public enum FileWriteOption {
    OVERWRITE,
    APPEND
}

# Processes the raw template and returns the processed string.
#
# + template - The raw template to be processed
# + return - The resulting string after processing the template
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

isolated function processMessage(string|PrintableRawTemplate msg) returns string =>
    msg !is string ? processTemplate(msg) : msg;

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

# Sets the log output to a file. All subsequent logs of the entire application will be written to this file.
# ```ballerina
# var result = log:setOutputFile("./resources/myfile.log");
# var result = log:setOutputFile("./resources/myfile.log", log:OVERWRITE);
# ```
#
# + path - The file path to write the logs. Should be a file with `.log` extension
# + option - The file write option. Default is `APPEND`
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

isolated function printLogFmt(LogRecord logRecord) returns string {
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
                value = v is string ? string `${escape(v.toString())}` : v.toString();
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

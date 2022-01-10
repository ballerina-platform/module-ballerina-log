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
import ballerina/observe;
import ballerina/lang.'value;
import ballerina/jballerina.java;

# Represents log level types.
enum LogLevel {
    DEBUG,
    ERROR,
    INFO,
    WARN
}

# A value of anydata type, or a function pointer.
public type Value anydata|Valuer;

# A function that returns anydata type.
public type Valuer isolated function () returns anydata;

# Key-Value pairs that needs to be displayed in the log.
#
# + msg - msg which cannot be a key
# + 'error - 'error which cannot be a key
# + stackTrace - error stack trace which cannot be a key
public type KeyValues record {|
    never msg?;
    never 'error?;
    never stackTrace?;
    Value...;
|};

type Module record {
    readonly string name;
    string level;
};

configurable string format = "logfmt";
configurable string level = "INFO";
configurable table<Module> key(name) & readonly modules = table [];

const string JSON_OUTPUT_FORMAT = "json";

type LogRecord record {
    string time;
    string level;
    string module;
    string message;
};

final map<int> & readonly logLevelWeight = {
    "ERROR": 1000,
    "WARN": 900,
    "INFO": 800,
    "DEBUG": 700
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

# Prints debug logs.
# ```ballerina
# log:printDebug("debug message", id = 845315)
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + keyValues - The key-value pairs to be logged
# + stackTrace - The error stack trace to be logged
public isolated function printDebug(string msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    if isLogLevelEnabled(DEBUG) {
        print(DEBUG, msg, 'error, stackTrace, keyValues);
    }
}

# Prints error logs.
# ```ballerina
# error e = error("error occurred");
# log:printError("error log with cause", 'error = e, id = 845315);
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + keyValues - The key-value pairs to be logged
# + stackTrace - The error stack trace to be logged
public isolated function printError(string msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    if isLogLevelEnabled(ERROR) {
        print(ERROR, msg, 'error, stackTrace, keyValues);
    }
}

# Prints info logs.
# ```ballerina
# log:printInfo("info message", id = 845315)
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + keyValues - The key-value pairs to be logged
# + stackTrace - The error stack trace to be logged
public isolated function printInfo(string msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    if isLogLevelEnabled(INFO) {
        print(INFO, msg, 'error, stackTrace, keyValues);
    }
}

# Prints warn logs.
# ```ballerina
# log:printWarn("warn message", id = 845315)
# ```
#
# + msg - The message to be logged
# + 'error - The error struct to be logged
# + keyValues - The key-value pairs to be logged
# + stackTrace - The error stack trace to be logged
public isolated function printWarn(string msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    if isLogLevelEnabled(WARN) {
        print(WARN, msg, 'error, stackTrace, keyValues);
    }
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
public isolated function setOutputFile(string path, FileWriteOption option = APPEND) returns Error? {
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

isolated function print(string logLevel, string msg, error? err = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues) {
    LogRecord logRecord = {
        time: getCurrentTime(),
        level: logLevel,
        module: getModuleName() == "." ? "" : getModuleName(),
        message: msg
    };
    if err is error {
        json|error errMessage = value:fromJsonString(err.message());
        if errMessage is json {
            logRecord["error"] = errMessage;
        } else {
            logRecord["error"] = err.message();
        }
    }
    if stackTrace is error:StackFrame[] {
        json[] stackTraceArray = [];
        foreach var element in stackTrace {
            stackTraceArray.push(element.toString());
        }
        logRecord["stackTrace"] = stackTraceArray;
    }
    foreach [string, Value] [k, v] in keyValues.entries() {
        anydata value = v is Valuer ? v() : v;
        logRecord[k] = value;
    }
    if observe:isTracingEnabled() {
        map<string> spanContext = observe:getSpanContext();
        foreach [string, string] [k, v] in spanContext.entries() {
            logRecord[k] = v;
        }
    }
    string logOutput = format == JSON_OUTPUT_FORMAT ? logRecord.toJsonString() : printLogFmt(logRecord);
    string? path = ();
    lock {
        path = outputFilePath;
        if path is string {
            fileWrite(logOutput);
        } else {
            io:fprintln(io:stderr, logOutput);
        }
    }
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
            _ => {
                value = v is string ? string `${escape(v.toString())}` : v.toString();
            }
        }
        if message == "" {
            message = message + string `${k} = ${value}`;
        } else {
            message = message + string ` ${k} = ${value}`;
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
    name: "replace"
} external;

isolated function isLogLevelEnabled(string logLevel) returns boolean {
    string moduleLogLevel = level;
    if modules.length() > 0 {
        string moduleName = getModuleName();
        if modules.hasKey(moduleName) {
            moduleLogLevel = modules.get(moduleName).level;
        }
    }
    return logLevelWeight.get(logLevel) >= logLevelWeight.get(moduleLogLevel);
}

isolated function getModuleName() returns string = @java:Method {'class: "io.ballerina.stdlib.log.Utils"} external;

isolated function getCurrentTime() returns string = @java:Method {'class: "io.ballerina.stdlib.log.Utils"} external;

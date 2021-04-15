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
import ballerina/jballerina.java;

# Represents log level types.
enum LogLevel {
    DEBUG,
    ERROR,
    INFO,
    WARN
}

# A value of anydata type
public type Value anydata|Valuer;

# A function that returns anydata type
public type Valuer isolated function () returns anydata;

# Key-Value pairs that needs to be desplayed in the log.
#
# + msg - msg which cannot be a key
# + 'error - 'error which cannot be a key
public type KeyValues record {|
    never msg?;
    never 'error?;
    Value...;
|};

type Module record {
    readonly string name;
    string level;
};

final configurable string format = "logfmt";
final configurable string level = "INFO";
final configurable table<Module> key(name) & readonly modules = table [];

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

# Prints debug logs.
# ```ballerina
# log:printDebug("debug message", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
# + 'error - The error struct to be logged
public isolated function printDebug(string msg, *KeyValues keyValues, error? 'error = ()) {
    if (isLogLevelEnabled(DEBUG)) {
        print(DEBUG, msg, keyValues, 'error);
    }
}

# Prints error logs.
# ```ballerina
# error e = error("error occurred");
# log:printError("error log with cause", 'error = e, id = 845315);
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
# + 'error - The error struct to be logged
public isolated function printError(string msg, *KeyValues keyValues, error? 'error = ()) {
    if (isLogLevelEnabled(ERROR)) {
        print(ERROR, msg, keyValues, 'error);
    }
}

# Prints info logs.
# ```ballerina
# log:printInfo("info message", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
# + 'error - The error struct to be logged
public isolated function printInfo(string msg, *KeyValues keyValues, error? 'error = ()) {
    if (isLogLevelEnabled(INFO)) {
        print(INFO, msg, keyValues, 'error);
    }
}

# Prints warn logs.
# ```ballerina
# log:printWarn("warn message", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
# + 'error - The error struct to be logged
public isolated function printWarn(string msg, *KeyValues keyValues, error? 'error = ()) {
    if (isLogLevelEnabled(WARN)) {
        print(WARN, msg, keyValues, 'error);
    }
}

isolated function print(string logLevel, string msg, *KeyValues keyValues, error? err = ()) {
    LogRecord logRecord = {
        time: getCurrentTime(),
        level: logLevel,
        module: getModuleName() == "." ? "" : getModuleName(),
        message: msg
    };
    if err is error {
        logRecord["error"] = err.message();
    }
    foreach [string, Value] [k, v] in keyValues.entries() {
        anydata value;
        if (v is Valuer) {
            value = v();
        } else {
            value = v;
        }
        logRecord[k] = value;
    }
    if format == "json" {
        println(stderrStream(), java:fromString(logRecord.toJsonString()));
    } else {
        printLogFmtExtern(logRecord);
    }
}

isolated function println(handle receiver, handle msg) = @java:Method {
    name: "println",
    'class: "java.io.PrintStream",
    paramTypes: ["java.lang.String"]
} external;

isolated function stderrStream() returns handle = @java:FieldGet {
    name: "err",
    'class: "java/lang/System"
} external;

isolated function printLogFmtExtern(LogRecord logRecord) = @java:Method {'class: "org.ballerinalang.stdlib.log.Utils"} external;

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

isolated function getModuleName() returns string = @java:Method {'class: "org.ballerinalang.stdlib.log.Utils"} external;

isolated function getCurrentTime() returns string = @java:Method {'class: "org.ballerinalang.stdlib.log.Utils"} external;

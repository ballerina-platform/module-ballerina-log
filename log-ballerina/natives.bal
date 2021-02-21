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
public type Value anydata|error:CallStack|Valuer;

# A function that returns anydata type
public type Valuer isolated function() returns anydata;

# Key-Value pairs that needs to be desplayed in the log.
#
# + msg - msg which cannot be a key
# + err - err which cannot be a key
public type KeyValues record {|
    never msg?;
    never err?;
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

# Prints debug logs.
# ```ballerina
# log:printDebug("debug message", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
public isolated function printDebug(string msg, *KeyValues keyValues) {
    if (isLogLevelEnabledExtern(DEBUG)) {
        print(DEBUG, msg, keyValues);
    }
}

# Prints error logs.
# ```ballerina
# log:printError("error message", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
# + err - The error struct to be logged
public isolated function printError(string msg, *KeyValues keyValues, error? err = ()) {
    if (isLogLevelEnabledExtern(ERROR)) {
        print(ERROR, msg, keyValues, err);
    }
}

# Prints info logs.
# ```ballerina
# log:printInfo("info message", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
public isolated function printInfo(string msg, *KeyValues keyValues) {
    if (isLogLevelEnabledExtern(INFO)) {
        print(INFO, msg, keyValues);
    }
}

# Prints warn logs.
# ```ballerina
# log:printWarn("warn message", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
public isolated function printWarn(string msg, *KeyValues keyValues) {
    if (isLogLevelEnabledExtern(WARN)) {
        print(WARN, msg, keyValues);
    }
}

isolated function print(string logLevel, string msg, *KeyValues keyValues, error? err = ()) {
    string keyValuesString = "";
    foreach [string, Value] [k, v] in keyValues.entries() {
        anydata value;
        if (v is error:CallStack) {
            value = v.callStack;
        } else if (v is Valuer) {
            value = v();
        } else {
           value = v;
        }
        keyValuesString += appendKeyValue(k, value);
    }
    printExtern(logLevel, getOutput(msg, keyValuesString, err), format);
}

isolated function printExtern(string logLevel, string msg, string outputFormat) = @java:Method {
    'class: "org.ballerinalang.stdlib.log.Utils"
} external;

isolated function appendKeyValue(string key, anydata value) returns string {
    string k;
    string v;
    if (format == JSON_OUTPUT_FORMAT) {
        k = ", \"" + key + "\": ";
    } else {
        k = " " + key + " = ";
    }
    if (value is string) {
        v = "\"" + value + "\"";
    } else {
        v = value.toString();
    }
    return k + v;
}

isolated function getOutput(string msg, string keyValues, error? err = ()) returns string {
    string output = "";
    if (format == JSON_OUTPUT_FORMAT) {
        output = "\"message\": " + getMessage(msg, err) + keyValues;
    } else {
        output = "message = " + getMessage(msg, err) + keyValues;
    }
    return output;
}

isolated function getMessage(string msg, error? err = ()) returns string {
    string message =  "\"" + msg + "\"";
    if (err is error) {
        if (format == JSON_OUTPUT_FORMAT) {
            message += ", \"error\": \"" + err.message() + "\"";
        } else {
            message += " error = \"" + err.message() + "\"" ;
        }
    }
    return message;
}

isolated function initializeLogLevels() {
    var globalLevel = setGlobalLogLevelExtern(level);
    modules.forEach(isolated function(Module module) {
        var moduleLevel = setModuleLogLevelExtern(module.name, module.level);
    });
}

isolated function setGlobalLogLevelExtern(string logLevel) = @java:Method {
    'class: "org.ballerinalang.stdlib.log.Utils"
} external;

isolated function setModuleLogLevelExtern(string module, string level) = @java:Method {
    'class: "org.ballerinalang.stdlib.log.Utils"
} external;

isolated function isLogLevelEnabledExtern(LogLevel logLevel) returns boolean = @java:Method {
    'class: "org.ballerinalang.stdlib.log.Utils"
} external;

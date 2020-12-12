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

import ballerina/java;

# A value of anydata type
public type Value anydata|Valuer;

# A function that returns anydata type
public type Valuer isolated function() returns anydata;

# Key-Value pairs that needs to be desplayed in the log.
#
# + msg - msg which cannot be a key
public type KeyValues record {|
    never msg?;
    Value...;
|};

# Key-Value pairs that needs to be desplayed in the error log.
#
# + msg - msg which cannot be a key
# + err - error
public type ErrorKeyValues record {|
    never msg?;
    never err?;
    Value...;
|};

# Prints logs.
# ```ballerina
# log:print("something went wrong", id = 845315)
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
public isolated function print(string msg, *KeyValues keyValues) {
    string keyValuesString = "";
    foreach [string, Value] [k, v] in keyValues.entries() {
        anydata value;
        if (v is Valuer) {
           value = v();
        } else {
           value = v;
        }
        keyValuesString = appendKeyValue(keyValuesString, k, value);
    }
    printExtern("message = " + "\"" + msg + "\"" + keyValuesString);
}

# Prints error logs.
# ```ballerina
# error e = error("error occurred");
# log:printError("error log with cause", err = e, id = 845315);
# ```
#
# + msg - The message to be logged
# + keyValues - The key-value pairs to be logged
# + err - The error struct to be logged
public isolated function printError(string msg, *ErrorKeyValues keyValues, error? err = ()) {
    string keyValuesString = "";
    foreach [string, Value] [k, v] in keyValues.entries() {
        anydata value;
        if (v is Valuer) {
           value = v();
        } else {
           value = v;
        }
        keyValuesString = appendKeyValue(keyValuesString, k, value);
    }
    if (err is error) {
        printErrorExtern("message = " + "\"" + msg + "\"" + " error = " + "\"" + err.message() + "\"" +
        keyValuesString);
    } else {
        printErrorExtern("message = " + "\"" + msg + "\"" + keyValuesString);
    }
}

isolated function printExtern(string msg) = @java:Method {
    'class: "org.ballerinalang.stdlib.log.Utils"
} external;

isolated function printErrorExtern(string msg) = @java:Method {
    'class: "org.ballerinalang.stdlib.log.Utils"
} external;

isolated function appendKeyValue(string keyValueString, string key, anydata value) returns string {
    string keyValuesString = "";
    if (value is string) {
        keyValuesString = keyValuesString + " " + key + " = " + "\"" + value + "\"";
    } else {
        keyValuesString = keyValuesString + " " + key + " = " + value.toString();
    }
    return keyValuesString;
}

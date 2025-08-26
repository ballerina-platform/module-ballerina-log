// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

function init() returns error? {
    rootLogger = new RootLogger();
    check validateDestinations(destinations);
    setModule();
}

isolated function validateDestinations(OutputDestination[] destinations) returns Error? {
    if destinations.length() == 0 {
        return error("At least one log destination must be specified.");
    }
    foreach OutputDestination destination in destinations {
        if destination !is FileOutputDestination {
            continue;
        }
        if !destination.path.endsWith(".log") {
            return error Error(string `The given file destination path: '${destination.path}' is not valid. File destination path should be a valid file with .log extension.`);
        }
        if destination.clearOnStartup {
            io:Error? result = io:fileWriteString(destination.path, "");
            if result is error {
                return error Error(string `Failed to clear the destination log file: '${destination.path}'`, result);
            }
        }
    }
}

isolated function setModule() = @java:Method {
    'class: "io.ballerina.stdlib.log.ModuleUtils"
} external;

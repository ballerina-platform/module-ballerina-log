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

import ballerina/jballerina.java;

function init() returns error? {
    rootLogger = new RootLogger();
    check validateDestinations();
    setModule();
}

function validateDestinations() returns error? {
    foreach string destination in destinations {
        if destination != STDERR && destination != STDOUT && !destination.endsWith(".log") {
            return error(string `The given destination path: '${destination}' is not valid. Log destination should be either 'stderr', 'stdout' or a valid file with .log extension.`);
        }
    }
}

isolated function setModule() = @java:Method {
    'class: "io.ballerina.stdlib.log.ModuleUtils"
} external;

// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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

import ballerina/log;
import ballerina/log as lg;

public function main() {
    log:printInfo(password);
    log:printError(string `Error: ${password}`);
    log:printWarn(`Error: ${password}`);
    log:printError("Error " + password);
    log:printWarn("Warning", password = password);
    log:printError("Error", password = password, user = user);
    lg:printError(password, user = user);
}

function log() {
    log:printInfo("Info");
}

configurable string password = ?;
configurable string user = ?;

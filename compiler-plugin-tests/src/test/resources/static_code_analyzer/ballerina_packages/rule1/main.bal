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
import ballerina/http;
import ballerina/file;

public function main() {
    log:printInfo(password);
    log:printError(string `Error: ${password}`);
    log:printError("Error " + password);
    log:printWarn("Warning", password = password);
}

function log() {
    log:printInfo("Info");
}

service on new http:Listener(9090) {
    resource function get test() {
        log:printInfo("Info", password = password);
    }
}

service  on new file:Listener({path: "/tmp", recursive: true}) {
    remote function onCreate(file:FileEvent event) {
        log:printInfo("File created: ", path = event.name);
    }
}

configurable string password = ?;

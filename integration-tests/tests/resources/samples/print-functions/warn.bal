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

import ballerina/log;

type HttpError error<map<anydata>>;

public function main() {
    error e = error("bad sad");
    log:printWarn("warn log");
    log:printWarn("warn log", username = "Alex92", id = 845315, foo = true);
    log:printWarn("warn log", username = isolated function() returns string { return "Alex92";}, id = isolated function() returns int { return 845315;});
    log:printWarn("warn log", 'error = e);
    log:printWarn("warn log", 'error = e, username = "Alex92", id = 845315, foo = true);
    log:printWarn("warn log\t\n\r\\\"", username = "Alex92\t\n\r\\\"");
    f1();

    map<anydata> httpError = {
        "code": 403,
        "details": "Authentication failed"
    };
    HttpError err = error(httpError.toJsonString());
    log:printWarn("warn log", 'error = err);
}

function f1() {
    f2();
}

function f2() {
    f3();
}

function f3() {
    error e = error("bad sad");
    log:printWarn("warn log", stackTrace = e.stackTrace(), username = "Alex92", id = 845315);
}

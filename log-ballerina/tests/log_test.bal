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
import ballerina/test;

string logMessage = "";

@test:Mock {
    moduleName: "ballerina/log",
    functionName: "println"
}
test:MockFunction mock_println= new();

function mockPrintln(handle receiver, handle msg) {
    logMessage = "something went wrong";
}

@test:Config {}
function testPrintLog() {
    test:when(mock_println).call("mockPrintln");

    main();
    test:assertEquals(logMessage, "something went wrong");
}

@test:Config {}
isolated function testGetModuleName() {
    test:assertEquals(getModuleName(), "jdk/internal");
}

@test:Config {}
isolated function testGetCurrentTime() {
    test:assertTrue(isValidDateTime(getCurrentTime()));
}

@test:Config {}
isolated function testPrintLogFmtExtern() {
    LogRecord logRecord1 = {
        time: "2021-05-04T10:32:13.220+05:30",
        level: "DEBUG",
        module: "foo/bar",
        message: "debug message"
    };
    test:assertEquals(printLogFmt(logRecord1),
    "time = 2021-05-04T10:32:13.220+05:30 level = DEBUG module = foo/bar message = \"debug message\"");
    LogRecord logRecord2 = {
        time: "2021-05-04T10:32:13.220+05:30",
        level: "INFO",
        module: "foo/bar",
        message: "debug message"
    };
    test:assertEquals(printLogFmt(logRecord2),
    "time = 2021-05-04T10:32:13.220+05:30 level = INFO module = foo/bar message = \"debug message\"");
    LogRecord logRecord3 = {
        time: "2021-05-04T10:32:13.220+05:30",
        level: "DEBUG",
        module: "",
        message: "debug message"
    };
    test:assertEquals(printLogFmt(logRecord3),
    "time = 2021-05-04T10:32:13.220+05:30 level = DEBUG module = \"\" message = \"debug message\"");
    LogRecord logRecord4 = {
        time: "2021-05-04T10:32:13.220+05:30",
        level: "DEBUG",
        module: "foo/bar",
        message: "debug message",
        "username": "Alex",
        "id": 845315
    };
    test:assertEquals(printLogFmt(logRecord4),
    "time = 2021-05-04T10:32:13.220+05:30 level = DEBUG module = foo/bar message = \"debug message\" username = \"Alex\" id = 845315");
}

public isolated function main() {
    error err = error("bad sad");
    printDebug("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int { return 3;});
    printError("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int { return 3;});
    printInfo("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int { return 3;});
    printWarn("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int { return 3;});
}

isolated function isValidDateTime(string dateTime) returns boolean = @java:Method {'class: "org.ballerinalang.stdlib.log.testutils.utils.OSUtils"} external;

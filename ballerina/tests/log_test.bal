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
import ballerina/test;

string logMessage = "";

@test:Mock {
    moduleName: "ballerina/io",
    functionName: "fprintln"
}
test:MockFunction mock_fprintln = new ();

function mockFprintln(io:FileOutputStream fileOutputStream, io:Printable... values) {
    logMessage = "something went wrong";
}

@test:Config {}
function testPrintLog() {
    test:when(mock_fprintln).call("mockFprintln");

    main();
    test:assertEquals(logMessage, "something went wrong");
}

@test:Config {}
isolated function testGetModuleName() {
    test:assertEquals(getModuleName(), "jdk/internal");
}

@test:Config {}
isolated function testGetCurrentTime() {
    string|error currentTime = getCurrentTime();
    test:assertTrue(currentTime is string);
    if currentTime is string {
        test:assertTrue(isValidDateTime(currentTime));    
    }
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
    printDebug("something went wrong", 'error = err, stackTrace = err.stackTrace(), username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int {
        return 3;
    });
    printError("something went wrong", 'error = err, stackTrace = err.stackTrace(), username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int {
        return 3;
    });
    printInfo("something went wrong", 'error = err, stackTrace = err.stackTrace(), username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int {
        return 3;
    });
    printWarn("something went wrong", 'error = err, stackTrace = err.stackTrace(), username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int {
        return 3;
    });

    var result1 = setOutputFile("./foo/bar.log");
    test:assertFalse(result1 is error);
    printInfo("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315,
    attempts = isolated function() returns int {
        return 3;
    });
    var result2 = setOutputFile("./foo/bar.log", APPEND);
    test:assertFalse(result2 is error);
    printInfo("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315,
        attempts = isolated function() returns int {
        return 3;
    });
    var result3 = setOutputFile("./foo/bar.log", OVERWRITE);
    test:assertFalse(result3 is error);
    printInfo("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315,
        attempts = isolated function() returns int {
        return 3;
    });

    var result4 = setOutputFile("./foo/bar.bal", OVERWRITE);
    test:assertTrue(result4 is error);
}

isolated function isValidDateTime(string dateTime) returns boolean = @java:Method {'class: "io.ballerina.stdlib.log.testutils.utils.OSUtils"} external;

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

@test:Config {
    dependsOn: [testRootLogger]
}
function testPrintLog() {
    test:when(mock_fprintln).call("mockFprintln");
    test();
    test:assertEquals(logMessage, "something went wrong");
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
    "time=2021-05-04T10:32:13.220+05:30 level=DEBUG module=foo/bar message=\"debug message\"");
    LogRecord logRecord2 = {
        time: "2021-05-04T10:32:13.220+05:30",
        level: "INFO",
        module: "foo/bar",
        message: "debug message"
    };
    test:assertEquals(printLogFmt(logRecord2),
    "time=2021-05-04T10:32:13.220+05:30 level=INFO module=foo/bar message=\"debug message\"");
    LogRecord logRecord3 = {
        time: "2021-05-04T10:32:13.220+05:30",
        level: "DEBUG",
        module: "",
        message: "debug message"
    };
    test:assertEquals(printLogFmt(logRecord3),
    "time=2021-05-04T10:32:13.220+05:30 level=DEBUG module=\"\" message=\"debug message\"");
    LogRecord logRecord4 = {
        time: "2021-05-04T10:32:13.220+05:30",
        level: "DEBUG",
        module: "foo/bar",
        message: "debug message",
        "username": "Alex",
        "id": 845315
    };
    test:assertEquals(printLogFmt(logRecord4),
    "time=2021-05-04T10:32:13.220+05:30 level=DEBUG module=foo/bar message=\"debug message\" username=\"Alex\" id=845315");
}

function test() {
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

@test:Config {}
function testInvalidDestination() returns error? {
    OutputDestination[] destinations = [{path: "foo"}];
    Error? result = validateDestinations(destinations);
    if result is () {
        test:assertFail("Expected an error but found none");
    }
    test:assertEquals(result.message(), "The given file destination path: 'foo' is not valid. File destination path should be a valid file with .log extension.");
}

@test:Config {}
function testEmptyDestinationValidation() returns error? {
    Error? result = validateDestinations([]);
    test:assertTrue(result is Error, "Should return an error for empty destinations");
    if result is Error {
        test:assertEquals(result.message(), "At least one log destination must be specified.");
    }
}

@test:Config {}
function testValidateRotationConfigErrors() returns error? {
    // maxFileSize <= 0 with SIZE_BASED policy
    Error? result = validateRotationConfig({policy: SIZE_BASED, maxFileSize: 0, maxAge: 3600, maxBackupFiles: 5});
    test:assertTrue(result is Error, "Should error when maxFileSize <= 0 with SIZE_BASED");
    if result is Error {
        test:assertTrue(result.message().includes("maxFileSize must be positive"));
    }

    // maxAge <= 0 with TIME_BASED policy
    result = validateRotationConfig({policy: TIME_BASED, maxFileSize: 1000, maxAge: 0, maxBackupFiles: 5});
    test:assertTrue(result is Error, "Should error when maxAge <= 0 with TIME_BASED");
    if result is Error {
        test:assertTrue(result.message().includes("maxAge must be positive"));
    }

    // maxBackupFiles < 0
    result = validateRotationConfig({policy: SIZE_BASED, maxFileSize: 1000, maxAge: 3600, maxBackupFiles: -1});
    test:assertTrue(result is Error, "Should error when maxBackupFiles < 0");
    if result is Error {
        test:assertTrue(result.message().includes("maxBackupFiles cannot be negative"));
    }
}

@test:Config {}
function testProcessTemplateDeprecated() {
    // Test with a plain string insertion
    string name = "world";
    string result = processTemplate(`Hello ${name}!`);
    test:assertEquals(result, "Hello world!");

    // Test with a Valuer (function) insertion
    string result2 = processTemplate(`count: ${isolated function() returns int => 42}`);
    test:assertEquals(result2, "count: 42");

    // Test with a nested PrintableRawTemplate insertion
    string inner = "inner";
    string result3 = processTemplate(`outer: ${`nested-${inner}`}`);
    test:assertEquals(result3, "outer: nested-inner");
}

@test:Config {
    dependsOn: [testPrintLog]
}
function testPrintErrorWithCause() {
    test:when(mock_fprintln).call("mockFprintln");
    error cause = error("root cause");
    error chained = error("top level", cause);
    printError("chained error test", 'error = chained);
    test:assertEquals(logMessage, "something went wrong");
}

@test:Config {
    dependsOn: [testPrintErrorWithCause]
}
function testPrintErrorWithJsonMessage() {
    test:when(mock_fprintln).call("mockFprintln");
    // An error whose message is a valid JSON string — parseErrorMessage returns json
    error jsonMsgError = error("{\"type\":\"NotFound\",\"code\":404}");
    printError("json message error", 'error = jsonMsgError);
    test:assertEquals(logMessage, "something went wrong");
}

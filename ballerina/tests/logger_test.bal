// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
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

import ballerina/io;
import ballerina/test;

configurable Config loggerConfig1 = {};
configurable Config loggerConfig2 = {};

type Context record {|
    string id;
    string msg;
|};

isolated function getCtx() returns Context => {id: "ctx-1234", msg: "Sample Context Message"};

string[] stdErrLogs = [];
string[] stdOutLogs = [];

function addLogs(io:FileOutputStream fileOutputStream, io:Printable... values) {
    var firstValue = values[0];
    if firstValue is string {
        if fileOutputStream == io:stderr {
            stdErrLogs.push(firstValue);
        } else if fileOutputStream == io:stdout {
            stdOutLogs.push(firstValue);
        }
    }
}

function createInitialLoggerFiles() returns error? {
    check io:fileWriteString("target/tmp/output/logger1.log", "test\n");
    check io:fileWriteString("target/tmp/output/logger2.log", "test\n");
}

@test:Config {
    before: createInitialLoggerFiles,
    groups: ["logger"]
}
function testBasicLoggingFunctions() returns error? {
    test:when(mock_fprintln).call("addLogs");
    Logger logger1 = check fromConfig(loggerConfig1);
    final readonly & string value2 = "value2";
    logger1.printInfo(`This is an info message`, key1 = "value1", key2 = `val:${value2}`, ctx = getCtx);
    logger1.printDebug("This is a debug message");
    PrintableRawTemplate value2Temp = `val:${value2}`;
    logger1.printError("This is an error message", error("An error ocurred"), key2 = `${value2Temp}`);
    logger1.printWarn("This is a warning message");
    string expectedMsg1 = string `, "level":"INFO", "module":"ballerina/log$test", "message":"This is an info message", "key1":"value1", "key2":"val:value2", "ctx":{"id":"ctx-1234", "msg":"Sample Context Message"}, "env":"prod", "name":"logger1"}`;
    string expectedMsg21 = string `, "level":"ERROR", "module":"ballerina/log$test", "message":"This is an error message", "error":{"causes":[], "message":"An error ocurred", "detail":{}, "stackTrace":`;
    string expectedMsg22 = string `, "key2":"val:value2", "env":"prod", "name":"logger1"}`;
    string expectedMsg3 = string `, "level":"WARN", "module":"ballerina/log$test", "message":"This is a warning message", "env":"prod", "name":"logger1"}`;

    test:assertEquals(stdErrLogs.length(), 3);
    test:assertTrue(stdErrLogs[0].endsWith(expectedMsg1));
    test:assertTrue(stdErrLogs[1].includes(expectedMsg21));
    test:assertTrue(stdErrLogs[1].endsWith(expectedMsg22));
    test:assertTrue(stdErrLogs[2].endsWith(expectedMsg3));
    stdErrLogs.removeAll();

    test:assertTrue(stdOutLogs.length() == 0);

    string[] logger1FileLogs = check io:fileReadLines("target/tmp/output/logger1.log");
    test:assertEquals(logger1FileLogs.length(), 4);
    test:assertEquals(logger1FileLogs[0], "test");
    test:assertTrue(logger1FileLogs[1].endsWith(expectedMsg1));
    test:assertTrue(logger1FileLogs[2].includes(expectedMsg21));
    test:assertTrue(logger1FileLogs[2].endsWith(expectedMsg22));
    test:assertTrue(logger1FileLogs[3].endsWith(expectedMsg3));
    _ = check io:fileWriteString("target/tmp/output/logger1.log", "");

    Logger logger2 = check fromConfig(loggerConfig2);
    logger2.printInfo("This is an info message");
    logger2.printError("This is an error message", error("An error occurred"));
    var value2Provider = isolated function() returns string => value2;
    logger2.printDebug(`This is a debug message`, key1 = "value1", key2 = `val:${value2Provider}`, ctx = getCtx);
    logger2.printWarn("This is a warning message");
    string expectedMsg4 = string ` level=INFO module=ballerina/log$test message="This is an info message" env="dev" name="logger2"`;
    string expectedMsg51 = string ` level=ERROR module=ballerina/log$test message="This is an error message" error={"causes":[],"message":"An error occurred","detail":{},"stackTrace":`;
    string expectedMsg52 = string ` env="dev" name="logger2"`;
    string expectedMsg6 = string ` level=DEBUG module=ballerina/log$test message="This is a debug message" key1="value1" key2="val:value2" ctx={"id":"ctx-1234","msg":"Sample Context Message"} env="dev" name="logger2"`;
    string expectedMsg7 = string ` level=WARN module=ballerina/log$test message="This is a warning message" env="dev" name="logger2"`;

    test:assertTrue(stdErrLogs.length() == 0);

    test:assertEquals(stdOutLogs.length(), 4);
    test:assertTrue(stdOutLogs[0].endsWith(expectedMsg4));
    test:assertTrue(stdOutLogs[1].includes(expectedMsg51));
    test:assertTrue(stdOutLogs[1].endsWith(expectedMsg52));
    test:assertTrue(stdOutLogs[2].endsWith(expectedMsg6));
    test:assertTrue(stdOutLogs[3].endsWith(expectedMsg7));
    stdOutLogs.removeAll();

    string[] logger2FileLogs = check io:fileReadLines("target/tmp/output/logger2.log");
    test:assertEquals(logger2FileLogs.length(), 4);
    test:assertTrue(logger2FileLogs[0].endsWith(expectedMsg4));
    test:assertTrue(logger2FileLogs[1].includes(expectedMsg51));
    test:assertTrue(logger2FileLogs[1].endsWith(expectedMsg52));
    test:assertTrue(logger2FileLogs[2].endsWith(expectedMsg6));
    test:assertTrue(logger2FileLogs[3].endsWith(expectedMsg7));
    _ = check io:fileWriteString("target/tmp/output/logger2.log", "");
}

configurable Config newLoggerConfig = {};

@test:Config {
    groups: ["logger"],
    dependsOn: [testBasicLoggingFunctions]
}
function testRootLogger() returns error? {
    Logger logger = root();
    test:assertExactEquals(logger, rootLogger);

    test:when(mock_fprintln).call("addLogs");
    logger.printInfo("This is an info message");

    test:assertTrue(stdOutLogs.length() == 0);

    test:assertEquals(stdErrLogs.length(), 1);
    test:assertTrue(stdErrLogs[0].endsWith(string ` "level":"INFO", "module":"ballerina/log$test", "message":"This is an info message", "env":"test"}`));
    stdErrLogs.removeAll();

    Logger newLogger = check fromConfig(newLoggerConfig);
    newLogger.printDebug("This is a debug message");

    test:assertTrue(stdErrLogs.length() == 0);

    test:assertEquals(stdOutLogs.length(), 1);
    test:assertTrue(stdOutLogs[0].endsWith(string ` level=DEBUG module=ballerina/log$test message="This is a debug message" env="test" name="newLogger"`));
    stdOutLogs.removeAll();
}

@test:Config {
    groups: ["logger"],
    dependsOn: [testRootLogger]
}
function testChildLogger() {
    Logger childLogger = rootLogger.withContext(child = true, name = `child-logger`, key = isolated function() returns string => "value");
    test:when(mock_fprintln).call("addLogs");
    childLogger.printInfo("This is an info message");

    test:assertTrue(stdOutLogs.length() == 0);

    test:assertEquals(stdErrLogs.length(), 1);
    test:assertTrue(stdErrLogs[0].endsWith(string `, "level":"INFO", "module":"ballerina/log$test", "message":"This is an info message", "env":"test", "child":true, "name":"child-logger", "key":"value"}`));
    stdErrLogs.removeAll();
}

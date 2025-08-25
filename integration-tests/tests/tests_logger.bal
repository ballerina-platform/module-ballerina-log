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

const CONFIG_ROOT_LOGGER = "tests/resources/config/json/root-logger/Config.toml";
const CHILD_LOGGERS_SRC_FILE = "tests/resources/samples/logger/child-loggers/main.bal";
const CUSTOM_LOGGER_SRC_FILE = "tests/resources/samples/logger/custom-logger/main.bal";
const LOGGER_FROM_CONFIG_CONFIG_FILE = "tests/resources/samples/logger/logger-from-config/Config.toml";

@test:Config {
    groups: ["logger"]
}
function testRootLoggerWithConfig() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_ROOT_LOGGER}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel errStreamResult = result.stderr();
    io:ReadableCharacterChannel errCharStreamResult = new (errStreamResult, UTF_8);
    string outErrText = check errCharStreamResult.read(100000);
    string[] errorLogLines = re `\n`.split(outErrText.trim());
    test:assertEquals(errorLogLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(errorLogLines[5].includes(string `"level":"ERROR", "module":"", "message":"error log", "env":"prod", "nodeId":"test-svc-001"`));
    check errCharStreamResult.close();

    io:ReadableByteChannel outStreamResult = result.stdout();
    io:ReadableCharacterChannel outCharStreamResult = new (outStreamResult, UTF_8);
    string outTextStdout = check outCharStreamResult.read(100000);
    string[] outLogLines = re `\n`.split(outTextStdout.trim());
    test:assertEquals(outLogLines.length(), 1, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(outLogLines[0].includes(string `"level":"ERROR", "module":"", "message":"error log", "env":"prod", "nodeId":"test-svc-001"`));
    check outCharStreamResult.close();

    string[] fileLogs = check io:fileReadLines("build/tmp/output/root-logger.log");
    test:assertEquals(fileLogs.length(), 1, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(fileLogs[0].includes(string `"level":"ERROR", "module":"", "message":"error log", "env":"prod", "nodeId":"test-svc-001"`));
}

@test:Config {
    groups: ["logger"]
}
function testChildLoggers() returns error? {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", CHILD_LOGGERS_SRC_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes(string `level=INFO module="" message="This is a root logger message" logger="root"`));
    test:assertTrue(logLines[6].includes(string `level=ERROR module="" message="This is a logger 1 message" logger="logger1" id="abcde" correlationId="12345"`));
    test:assertTrue(logLines[7].includes(string `level=WARN module="" message="This is a logger 2 message" logger="logger2" id="fghij" workerId="value2" loggerInfo="logger with id: log-123" ctx={"id":"ctx-1234","ctxMsg":"Contextual message","additionalInfo":{"key1":"value1","key2":"value2"}}`));
    check sc.close();
}

@test:Config {
    groups: ["logger"]
}
function testLoggerFromConfig() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: LOGGER_FROM_CONFIG_CONFIG_FILE}, (), "run", string `${temp_dir_path}/logger-from-config`);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes(string `level=INFO module=myorg/myproject message="Hello World from the root logger!" env="prod" nodeId="test-svc-001"`));
    check sc.close();

    string[] fileLogs = check io:fileReadLines("./build/tmp/output/audit.log");
    test:assertEquals(fileLogs.length(), 1, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(fileLogs[0].includes(string `"level":"INFO", "module":"myorg/myproject", "message":"Hello World from the audit logger!", "env":"prod", "nodeId":"test-svc-001", "org":"example.org", "version":"1.0.0"}`));
}

@test:Config {
    groups: ["logger"]
}
function testCustomLogger() returns error? {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", CUSTOM_LOGGER_SRC_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 4, INCORRECT_NUMBER_OF_LINES);
    check sc.close();

    string[] fileInfoLogs = check io:fileReadLines("build/tmp/output/custom-logger-info.log");
    test:assertEquals(fileInfoLogs.length(), 6, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(fileInfoLogs[0].endsWith(string `] {INFO} "This is an info message"  mode="info"`));
    test:assertTrue(fileInfoLogs[1].endsWith(string `] {ERROR} "This is an error message" error="An error occurred" mode="info"`));
    test:assertTrue(fileInfoLogs[2].endsWith(string `] {WARN} "This is a warning message"  mode="info"`));
    test:assertTrue(fileInfoLogs[3].endsWith(string `] {INFO} "This is an info message"  mode="info" child="true"`));
    test:assertTrue(fileInfoLogs[4].endsWith(string `] {ERROR} "This is an error message" error="An error occurred" mode="info" child="true"`));
    test:assertTrue(fileInfoLogs[5].endsWith(string `] {WARN} "This is a warning message"  mode="info" child="true"`));

    string[] fileDebugLogs = check io:fileReadLines("build/tmp/output/custom-logger-debug.log");
    test:assertEquals(fileDebugLogs.length(), 4, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(fileDebugLogs[0].endsWith(string `] {INFO} "This is an info message"  mode="debug"`));
    test:assertTrue(fileDebugLogs[1].endsWith(string `] {ERROR} "This is an error message" error="An error occurred" mode="debug"`));
    test:assertTrue(fileDebugLogs[2].endsWith(string `] {WARN} "This is a warning message"  mode="debug"`));
    test:assertTrue(fileDebugLogs[3].endsWith(string `] {DEBUG} "This is a debug message"  mode="debug"`));
}

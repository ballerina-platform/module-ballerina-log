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

import ballerina/lang.'value;
import ballerina/io;
import ballerina/regex;
import ballerina/test;

const string CONFIG_DEBUG_JSON = "tests/resources/config/json/log-levels/debug/Config.toml";
const string CONFIG_ERROR_JSON = "tests/resources/config/json/log-levels/error/Config.toml";
const string CONFIG_INFO_JSON = "tests/resources/config/json/log-levels/info/Config.toml";
const string CONFIG_WARN_JSON = "tests/resources/config/json/log-levels/warn/Config.toml";
const string CONFIG_PROJECT_WITHOUT_LEVEL_JSON = "tests/resources/config/json/log-project/no-level/Config.toml";
const string CONFIG_PROJECT_GLOBAL_LEVEL_JSON = "tests/resources/config/json/log-project/global/Config.toml";
const string CONFIG_PROJECT_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL_JSON = "tests/resources/config/json/log-project/default/Config.toml";
const string CONFIG_PROJECT_GLOBAL_AND_MODULE_LEVEL_JSON = "tests/resources/config/json/log-project/global-and-module/Config.toml";
const string CONFIG_OBSERVABILITY_PROJECT_JSON = "tests/resources/config/json/observability-project/Config.toml";

const string MESSAGE_ERROR_JSON = "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\"}";
const string MESSAGE_WARN_JSON = "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\"}";
const string MESSAGE_INFO_JSON = "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\"}";
const string MESSAGE_DEBUG_JSON = "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\"}";

const string MESSAGE_ERROR_MAIN_JSON = "\", \"level\":\"ERROR\", \"module\":\"myorg/myproject\", \"message\":\"error log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_WARN_MAIN_JSON = "\", \"level\":\"WARN\", \"module\":\"myorg/myproject\", \"message\":\"warn log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_INFO_MAIN_JSON = "\", \"level\":\"INFO\", \"module\":\"myorg/myproject\", \"message\":\"info log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_DEBUG_MAIN_JSON = "\", \"level\":\"DEBUG\", \"module\":\"myorg/myproject\", \"message\":\"debug log\\t\\n\\r\\\\\\\"\"}";

const string MESSAGE_ERROR_FOO_JSON = "\", \"level\":\"ERROR\", \"module\":\"myorg/myproject.foo\", \"message\":\"error log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_WARN_FOO_JSON = "\", \"level\":\"WARN\", \"module\":\"myorg/myproject.foo\", \"message\":\"warn log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_INFO_FOO_JSON = "\", \"level\":\"INFO\", \"module\":\"myorg/myproject.foo\", \"message\":\"info log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_DEBUG_FOO_JSON = "\", \"level\":\"DEBUG\", \"module\":\"myorg/myproject.foo\", \"message\":\"debug log\\t\\n\\r\\\\\\\"\"}";

const string MESSAGE_ERROR_BAR_JSON = "\", \"level\":\"ERROR\", \"module\":\"myorg/myproject.bar\", \"message\":\"error log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_WARN_BAR_JSON = "\", \"level\":\"WARN\", \"module\":\"myorg/myproject.bar\", \"message\":\"warn log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_INFO_BAR_JSON = "\", \"level\":\"INFO\", \"module\":\"myorg/myproject.bar\", \"message\":\"info log\\t\\n\\r\\\\\\\"\"}";
const string MESSAGE_DEBUG_BAR_JSON = "\", \"level\":\"DEBUG\", \"module\":\"myorg/myproject.bar\", \"message\":\"debug log\\t\\n\\r\\\\\\\"\"}";

@test:Config {}
public function testPrintDebugJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run", PRINT_DEBUG_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[7], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[8], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"error\":\"bad sad\"}");
    validateLogJson(logLines[9], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"error\":\"bad sad\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[10], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"stackTrace\":[{\"callableName\":\"f3\", \"moduleName\":\"debug\", \"fileName\":\"debug.bal\", \"lineNumber\":39}, {\"callableName\":\"f2\", \"moduleName\":\"debug\", \"fileName\":\"debug.bal\", \"lineNumber\":35}, {\"callableName\":\"f1\", \"moduleName\":\"debug\", \"fileName\":\"debug.bal\", \"lineNumber\":31}, {\"callableName\":\"main\", \"moduleName\":\"debug\", \"fileName\":\"debug.bal\", \"lineNumber\":27}], \"id\":845315, \"username\":\"Alex92\"}");
}

@test:Config {}
public function testPrintErrorJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_ERROR_JSON}, (), "run", PRINT_ERROR_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[7], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[8], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"error\":\"bad sad\"}");
    validateLogJson(logLines[9], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"error\":\"bad sad\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[10], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"stackTrace\":[{\"callableName\":\"f3\", \"moduleName\":\"error\", \"fileName\":\"error.bal\", \"lineNumber\":39}, {\"callableName\":\"f2\", \"moduleName\":\"error\", \"fileName\":\"error.bal\", \"lineNumber\":35}, {\"callableName\":\"f1\", \"moduleName\":\"error\", \"fileName\":\"error.bal\", \"lineNumber\":31}, {\"callableName\":\"main\", \"moduleName\":\"error\", \"fileName\":\"error.bal\", \"lineNumber\":27}], \"id\":845315, \"username\":\"Alex92\"}");
}

@test:Config {}
public function testPrintInfoJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INFO_JSON}, (), "run", PRINT_INFO_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[7], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[8], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"error\":\"bad sad\"}");
    validateLogJson(logLines[9], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"error\":\"bad sad\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[10], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"stackTrace\":[{\"callableName\":\"f3\", \"moduleName\":\"info\", \"fileName\":\"info.bal\", \"lineNumber\":39}, {\"callableName\":\"f2\", \"moduleName\":\"info\", \"fileName\":\"info.bal\", \"lineNumber\":35}, {\"callableName\":\"f1\", \"moduleName\":\"info\", \"fileName\":\"info.bal\", \"lineNumber\":31}, {\"callableName\":\"main\", \"moduleName\":\"info\", \"fileName\":\"info.bal\", \"lineNumber\":27}], \"id\":845315, \"username\":\"Alex92\"}");
}

@test:Config {}
public function testPrintWarnJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_WARN_JSON}, (), "run", PRINT_WARN_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[7], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[8], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"error\":\"bad sad\"}");
    validateLogJson(logLines[9], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"error\":\"bad sad\", \"foo\":true, \"id\":845315, \"username\":\"Alex92\"}");
    validateLogJson(logLines[10], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"stackTrace\":[{\"callableName\":\"f3\", \"moduleName\":\"warn\", \"fileName\":\"warn.bal\", \"lineNumber\":39}, {\"callableName\":\"f2\", \"moduleName\":\"warn\", \"fileName\":\"warn.bal\", \"lineNumber\":35}, {\"callableName\":\"f1\", \"moduleName\":\"warn\", \"fileName\":\"warn.bal\", \"lineNumber\":31}, {\"callableName\":\"main\", \"moduleName\":\"warn\", \"fileName\":\"warn.bal\", \"lineNumber\":27}], \"id\":845315, \"username\":\"Alex92\"}");
}

@test:Config {}
public function testErrorLevelJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_ERROR_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
}

@test:Config {}
public function testWarnLevelJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_WARN_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 7, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_JSON);
}

@test:Config {}
public function testInfoLevelJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INFO_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_JSON);
    validateLogJson(logLines[7], MESSAGE_INFO_JSON);
}

@test:Config {}
public function testDebugLevelJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_JSON);
    validateLogJson(logLines[7], MESSAGE_INFO_JSON);
    validateLogJson(logLines[8], MESSAGE_DEBUG_JSON);
}

@test:Config {}
public function testProjectWithoutLogLevelJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_WITHOUT_LEVEL_JSON}, (), "run", temp_dir_path
    + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 14, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_MAIN_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_MAIN_JSON);
    validateLogJson(logLines[7], MESSAGE_INFO_MAIN_JSON);
    validateLogJson(logLines[8], MESSAGE_ERROR_FOO_JSON);
    validateLogJson(logLines[9], MESSAGE_WARN_FOO_JSON);
    validateLogJson(logLines[10], MESSAGE_INFO_FOO_JSON);
    validateLogJson(logLines[11], MESSAGE_ERROR_BAR_JSON);
    validateLogJson(logLines[12], MESSAGE_WARN_BAR_JSON);
    validateLogJson(logLines[13], MESSAGE_INFO_BAR_JSON);
}

@test:Config {}
public function testProjectWithGlobalLogLevelJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_LEVEL_JSON}, (),
    "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 11, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_MAIN_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_MAIN_JSON);
    validateLogJson(logLines[7], MESSAGE_ERROR_FOO_JSON);
    validateLogJson(logLines[8], MESSAGE_WARN_FOO_JSON);
    validateLogJson(logLines[9], MESSAGE_ERROR_BAR_JSON);
    validateLogJson(logLines[10], MESSAGE_WARN_BAR_JSON);
}

@test:Config {}
public function testProjectWithGlobalAndDefualtPackageLogLevelJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL_JSON},
     (), "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_MAIN_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_MAIN_JSON);
    validateLogJson(logLines[7], MESSAGE_INFO_MAIN_JSON);
    validateLogJson(logLines[8], MESSAGE_DEBUG_MAIN_JSON);
    validateLogJson(logLines[9], MESSAGE_ERROR_FOO_JSON);
    validateLogJson(logLines[10], MESSAGE_ERROR_BAR_JSON);
    validateLogJson(logLines[11], MESSAGE_WARN_BAR_JSON);
}

@test:Config {}
public function testProjectWithGlobalAndModuleLogLevelsJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_AND_MODULE_LEVEL_JSON}, (),
    "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_MAIN_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_MAIN_JSON);
    validateLogJson(logLines[7], MESSAGE_ERROR_FOO_JSON);
    validateLogJson(logLines[8], MESSAGE_WARN_FOO_JSON);
    validateLogJson(logLines[9], MESSAGE_INFO_FOO_JSON);
    validateLogJson(logLines[10], MESSAGE_DEBUG_FOO_JSON);
    validateLogJson(logLines[11], MESSAGE_ERROR_BAR_JSON);
}

@test:Config {}
public function testObservabilityJson() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_OBSERVABILITY_PROJECT_JSON}, (),
    "run", temp_dir_path + "/observability-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);

    io:ReadableByteChannel readableOutResult = result.stdout();
    io:ReadableCharacterChannel sc2 = new (readableOutResult, UTF_8);
    string outText2 = checkpanic sc2.read(100000);
    string[] ioLines = regex:split(outText2, "\n");
    io:println(logLines[5]);
    io:println("\", \"level\":\"ERROR\", \"module\":\"myorg/myproject\", \"message\":\"error log\", \"traceId\":\"" + ioLines[1] + "\", \"spanId\":\"" + ioLines[2] + "\"}");
    validateLogJson(logLines[5], string `", "level":"ERROR", "module":"myorg/myproject", "message":"error log", "traceId":"${ioLines[1]}", "spanId":"${ioLines[2]}"}`);
    validateLogJson(logLines[6], string `", "level":"WARN", "module":"myorg/myproject", "message":"warn log", "traceId":"${ioLines[1]}", "spanId":"${ioLines[2]}"}`);
    validateLogJson(logLines[7], string `", "level":"INFO", "module":"myorg/myproject", "message":"info log", "traceId":"${ioLines[1]}", "spanId":"${ioLines[2]}"}`);
    validateLogJson(logLines[8], string `", "level":"DEBUG", "module":"myorg/myproject", "message":"debug log", "traceId":"${ioLines[1]}", "spanId":"${ioLines[2]}"}`);
}

isolated function validateLogJson(string log, string output) {
    test:assertTrue(isValidJsonString(log), "log output is not a valid json string");
    test:assertTrue(log.includes("{\"time\":\""), "log does not contain the time");
    test:assertTrue(log.includes(output), "log does not contain the required output");
}

isolated function isValidJsonString(string log) returns boolean {
    json|error j = value:fromJsonString(log);
    return j is json ? true : false;
}

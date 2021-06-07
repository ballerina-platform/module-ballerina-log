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
import ballerina/io;
import ballerina/regex;
import ballerina/test;

const string UTF_8 = "UTF-8";
const string INCORRECT_NUMBER_OF_LINES = "incorrect number of lines in output";

const string PRINT_INFO_FILE = "tests/resources/samples/print-functions/info.bal";
const string PRINT_WARN_FILE = "tests/resources/samples/print-functions/warn.bal";
const string PRINT_DEBUG_FILE = "tests/resources/samples/print-functions/debug.bal";
const string PRINT_ERROR_FILE = "tests/resources/samples/print-functions/error.bal";
const string LOG_LEVEL_FILE = "tests/resources/samples/log-levels/main.bal";

const string CONFIG_DEBUG_LOGFMT = "tests/resources/config/logfmt/log-levels/debug/Config.toml";
const string CONFIG_ERROR_LOGFMT = "tests/resources/config/logfmt/log-levels/error/Config.toml";
const string CONFIG_INFO_LOGFMT = "tests/resources/config/logfmt/log-levels/info/Config.toml";
const string CONFIG_WARN_LOGFMT = "tests/resources/config/logfmt/log-levels/warn/Config.toml";
const string CONFIG_PROJECT_GLOBAL_LEVEL_LOGFMT = "tests/resources/config/logfmt/log-project/global/Config.toml";
const string CONFIG_PROJECT_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL_LOGFMT = "tests/resources/config/logfmt/log-project/default/Config.toml";
const string CONFIG_PROJECT_GLOBAL_AND_MODULE_LEVEL_LOGFMT = "tests/resources/config/logfmt/log-project/global-and-module/Config.toml";

const string MESSAGE_ERROR_LOGFMT = " level = ERROR module = \"\" message = \"error log\"";
const string MESSAGE_WARN_LOGFMT = " level = WARN module = \"\" message = \"warn log\"";
const string MESSAGE_INFO_LOGFMT = " level = INFO module = \"\" message = \"info log\"";
const string MESSAGE_DEBUG_LOGFMT = " level = DEBUG module = \"\" message = \"debug log\"";

const string MESSAGE_ERROR_MAIN_LOGFMT = " level = ERROR module = myorg/myproject message = \"error log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_WARN_MAIN_LOGFMT = " level = WARN module = myorg/myproject message = \"warn log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_INFO_MAIN_LOGFMT = " level = INFO module = myorg/myproject message = \"info log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_DEBUG_MAIN_LOGFMT = " level = DEBUG module = myorg/myproject message = \"debug log\\t\\n\\r\\\\\\\"\"";

const string MESSAGE_ERROR_FOO_LOGFMT = " level = ERROR module = myorg/myproject.foo message = \"error log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_WARN_FOO_LOGFMT = " level = WARN module = myorg/myproject.foo message = \"warn log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_INFO_FOO_LOGFMT = " level = INFO module = myorg/myproject.foo message = \"info log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_DEBUG_FOO_LOGFMT = " level = DEBUG module = myorg/myproject.foo message = \"debug log\\t\\n\\r\\\\\\\"\"";

const string MESSAGE_ERROR_BAR_LOGFMT = " level = ERROR module = myorg/myproject.bar message = \"error log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_WARN_BAR_LOGFMT = " level = WARN module = myorg/myproject.bar message = \"warn log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_INFO_BAR_LOGFMT = " level = INFO module = myorg/myproject.bar message = \"info log\\t\\n\\r\\\\\\\"\"";
const string MESSAGE_DEBUG_BAR_LOGFMT = " level = DEBUG module = myorg/myproject.bar message = \"debug log\\t\\n\\r\\\\\\\"\"";

configurable string bal_exec_path = ?;
configurable string temp_dir_path = ?;

@test:Config {}
public function testPrintDebugLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run", PRINT_DEBUG_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], " level = DEBUG module = \"\" message = \"debug log\"");
    validateLog(logLines[6], " level = DEBUG module = \"\" message = \"debug log\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[7], " level = DEBUG module = \"\" message = \"debug log\" id = 845315 username = \"Alex92\"");
    validateLog(logLines[8], " level = DEBUG module = \"\" message = \"debug log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = DEBUG module = \"\" message = \"debug log\" error = \"bad sad\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[10], " level = DEBUG module = \"\" message = \"debug log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = DEBUG module = \"\" message = \"debug log\" stackTrace = [{\"callableName\":\"f3\",\"moduleName\":\"debug\",\"fileName\":\"debug.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"moduleName\":\"debug\",\"fileName\":\"debug.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"moduleName\":\"debug\",\"fileName\":\"debug.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"moduleName\":\"debug\",\"fileName\":\"debug.bal\",\"lineNumber\":27}] id = 845315 username = \"Alex92\"");
}

@test:Config {}
public function testPrintErrorLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_ERROR_LOGFMT}, (), "run", PRINT_ERROR_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], " level = ERROR module = \"\" message = \"error log\"");
    validateLog(logLines[6], " level = ERROR module = \"\" message = \"error log\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[7], " level = ERROR module = \"\" message = \"error log\" id = 845315 username = \"Alex92\"");
    validateLog(logLines[8], " level = ERROR module = \"\" message = \"error log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = ERROR module = \"\" message = \"error log\" error = \"bad sad\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[10], " level = ERROR module = \"\" message = \"error log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = ERROR module = \"\" message = \"error log\" stackTrace = [{\"callableName\":\"f3\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":27}] id = 845315 username = \"Alex92\"");
}

@test:Config {}
public function testPrintInfoLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INFO_LOGFMT}, (), "run", PRINT_INFO_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], " level = INFO module = \"\" message = \"info log\"");
    validateLog(logLines[6], " level = INFO module = \"\" message = \"info log\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[7], " level = INFO module = \"\" message = \"info log\" id = 845315 username = \"Alex92\"");
    validateLog(logLines[8], " level = INFO module = \"\" message = \"info log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = INFO module = \"\" message = \"info log\" error = \"bad sad\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[10], " level = INFO module = \"\" message = \"info log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = INFO module = \"\" message = \"info log\" stackTrace = [{\"callableName\":\"f3\",\"moduleName\":\"info\",\"fileName\":\"info.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"moduleName\":\"info\",\"fileName\":\"info.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"moduleName\":\"info\",\"fileName\":\"info.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"moduleName\":\"info\",\"fileName\":\"info.bal\",\"lineNumber\":27}] id = 845315 username = \"Alex92\"");
}

@test:Config {}
public function testPrintWarnLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_WARN_LOGFMT}, (), "run", PRINT_WARN_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], " level = WARN module = \"\" message = \"warn log\"");
    validateLog(logLines[6], " level = WARN module = \"\" message = \"warn log\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[7], " level = WARN module = \"\" message = \"warn log\" id = 845315 username = \"Alex92\"");
    validateLog(logLines[8], " level = WARN module = \"\" message = \"warn log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = WARN module = \"\" message = \"warn log\" error = \"bad sad\" foo = true id = 845315 username = \"Alex92\"");
    validateLog(logLines[10], " level = WARN module = \"\" message = \"warn log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = WARN module = \"\" message = \"warn log\" stackTrace = [{\"callableName\":\"f3\",\"moduleName\":\"warn\",\"fileName\":\"warn.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"moduleName\":\"warn\",\"fileName\":\"warn.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"moduleName\":\"warn\",\"fileName\":\"warn.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"moduleName\":\"warn\",\"fileName\":\"warn.bal\",\"lineNumber\":27}] id = 845315 username = \"Alex92\"");
}

@test:Config {}
public function testErrorLevelLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_ERROR_LOGFMT}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_LOGFMT);
}

@test:Config {}
public function testWarnLevelLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_WARN_LOGFMT}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 7, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_LOGFMT);
    validateLog(logLines[6], MESSAGE_WARN_LOGFMT);
}

@test:Config {}
public function testInfoLevelLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INFO_LOGFMT}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_LOGFMT);
    validateLog(logLines[6], MESSAGE_WARN_LOGFMT);
    validateLog(logLines[7], MESSAGE_INFO_LOGFMT);
}

@test:Config {}
public function testDebugLevelLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_LOGFMT);
    validateLog(logLines[6], MESSAGE_WARN_LOGFMT);
    validateLog(logLines[7], MESSAGE_INFO_LOGFMT);
    validateLog(logLines[8], MESSAGE_DEBUG_LOGFMT);
}

@test:Config {}
public function testProjectWithoutLogLevelLogfmt() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", temp_dir_path
    + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 14, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_MAIN_LOGFMT);
    validateLog(logLines[6], MESSAGE_WARN_MAIN_LOGFMT);
    validateLog(logLines[7], MESSAGE_INFO_MAIN_LOGFMT);
    validateLog(logLines[8], MESSAGE_ERROR_FOO_LOGFMT);
    validateLog(logLines[9], MESSAGE_WARN_FOO_LOGFMT);
    validateLog(logLines[10], MESSAGE_INFO_FOO_LOGFMT);
    validateLog(logLines[11], MESSAGE_ERROR_BAR_LOGFMT);
    validateLog(logLines[12], MESSAGE_WARN_BAR_LOGFMT);
    validateLog(logLines[13], MESSAGE_INFO_BAR_LOGFMT);
}

@test:Config {}
public function testProjectWithGlobalLogLevelLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_LEVEL_LOGFMT}, (),
    "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 11, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_MAIN_LOGFMT);
    validateLog(logLines[6], MESSAGE_WARN_MAIN_LOGFMT);
    validateLog(logLines[7], MESSAGE_ERROR_FOO_LOGFMT);
    validateLog(logLines[8], MESSAGE_WARN_FOO_LOGFMT);
    validateLog(logLines[9], MESSAGE_ERROR_BAR_LOGFMT);
    validateLog(logLines[10], MESSAGE_WARN_BAR_LOGFMT);
}

@test:Config {}
public function testProjectWithGlobalAndDefualtPackageLogLevelLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL_LOGFMT},
     (), "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_MAIN_LOGFMT);
    validateLog(logLines[6], MESSAGE_WARN_MAIN_LOGFMT);
    validateLog(logLines[7], MESSAGE_INFO_MAIN_LOGFMT);
    validateLog(logLines[8], MESSAGE_DEBUG_MAIN_LOGFMT);
    validateLog(logLines[9], MESSAGE_ERROR_FOO_LOGFMT);
    validateLog(logLines[10], MESSAGE_ERROR_BAR_LOGFMT);
    validateLog(logLines[11], MESSAGE_WARN_BAR_LOGFMT);
}

@test:Config {}
public function testProjectWithGlobalAndModuleLogLevelsLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_AND_MODULE_LEVEL_LOGFMT}, (),
    "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[5], MESSAGE_ERROR_MAIN_LOGFMT);
    validateLog(logLines[6], MESSAGE_WARN_MAIN_LOGFMT);
    validateLog(logLines[7], MESSAGE_ERROR_FOO_LOGFMT);
    validateLog(logLines[8], MESSAGE_WARN_FOO_LOGFMT);
    validateLog(logLines[9], MESSAGE_INFO_FOO_LOGFMT);
    validateLog(logLines[10], MESSAGE_DEBUG_FOO_LOGFMT);
    validateLog(logLines[11], MESSAGE_ERROR_BAR_LOGFMT);
}

isolated function validateLog(string log, string output) {
    test:assertTrue(log.includes("time ="), "log does not contain the time");
    test:assertTrue(log.includes(output), "log does not contain the required output");
}

function exec(@untainted string command, @untainted map<string> env = {},
                     @untainted string? dir = (), @untainted string... args) returns Process|error = @java:Method {
    name: "exec",
    'class: "org.ballerinalang.stdlib.log.testutils.nativeimpl.Exec"
} external;

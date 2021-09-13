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

const string FILE_WRITE_OUTPUT_OVERWRITE_INPUT_FILE_LOGFMT = "tests/resources/samples/file-write-output/single-file/overwrite-logfmt.bal";
const string FILE_WRITE_OUTPUT_APPEND_INPUT_FILE_LOGFMT = "tests/resources/samples/file-write-output/single-file/append-logfmt.bal";

const string jsonFILE_WRITE_OUTPUT_OVERWRITE_OUTPUT_FILE_LOGFMT = "build/tmp/output/overwrite-logfmt.log";
const string FILE_WRITE_OUTPUT_APPEND_OUTPUT_FILE_LOGFMT = "build/tmp/output/append-logfmt.log";
const string FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_LOGFMT = "build/tmp/output/project-overwrite-logfmt.log";
const string FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_LOGFMT2 = "build/tmp/output/project-overwrite-logfmt2.log";
const string FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_LOGFMT = "build/tmp/output/project-append-logfmt.log";
const string FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_LOGFMT2 = "build/tmp/output/project-append-logfmt2.log";

const string CONFIG_DEBUG_LOGFMT = "tests/resources/config/logfmt/log-levels/debug/Config.toml";
const string CONFIG_ERROR_LOGFMT = "tests/resources/config/logfmt/log-levels/error/Config.toml";
const string CONFIG_INFO_LOGFMT = "tests/resources/config/logfmt/log-levels/info/Config.toml";
const string CONFIG_WARN_LOGFMT = "tests/resources/config/logfmt/log-levels/warn/Config.toml";
const string CONFIG_PROJECT_GLOBAL_LEVEL_LOGFMT = "tests/resources/config/logfmt/log-project/global/Config.toml";
const string CONFIG_PROJECT_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL_LOGFMT = "tests/resources/config/logfmt/log-project/default/Config.toml";
const string CONFIG_PROJECT_GLOBAL_AND_MODULE_LEVEL_LOGFMT = "tests/resources/config/logfmt/log-project/global-and-module/Config.toml";
const string CONFIG_OBSERVABILITY_PROJECT_LOGFMT = "tests/resources/config/logfmt/observability-project/Config.toml";

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
    validateLog(logLines[6], " level = DEBUG module = \"\" message = \"debug log\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[7], " level = DEBUG module = \"\" message = \"debug log\" username = \"Alex92\" id = 845315");
    validateLog(logLines[8], " level = DEBUG module = \"\" message = \"debug log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = DEBUG module = \"\" message = \"debug log\" error = \"bad sad\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[10], " level = DEBUG module = \"\" message = \"debug log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = DEBUG module = \"\" message = \"debug log\" stackTrace = [{\"callableName\":\"f3\",\"fileName\":\"debug.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"fileName\":\"debug.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"fileName\":\"debug.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"fileName\":\"debug.bal\",\"lineNumber\":27}] username = \"Alex92\" id = 845315");
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
    validateLog(logLines[6], " level = ERROR module = \"\" message = \"error log\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[7], " level = ERROR module = \"\" message = \"error log\" username = \"Alex92\" id = 845315");
    validateLog(logLines[8], " level = ERROR module = \"\" message = \"error log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = ERROR module = \"\" message = \"error log\" error = \"bad sad\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[10], " level = ERROR module = \"\" message = \"error log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = ERROR module = \"\" message = \"error log\" stackTrace = [{\"callableName\":\"f3\",\"fileName\":\"error.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"fileName\":\"error.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"fileName\":\"error.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"fileName\":\"error.bal\",\"lineNumber\":27}] username = \"Alex92\" id = 845315");
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
    validateLog(logLines[6], " level = INFO module = \"\" message = \"info log\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[7], " level = INFO module = \"\" message = \"info log\" username = \"Alex92\" id = 845315");
    validateLog(logLines[8], " level = INFO module = \"\" message = \"info log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = INFO module = \"\" message = \"info log\" error = \"bad sad\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[10], " level = INFO module = \"\" message = \"info log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = INFO module = \"\" message = \"info log\" stackTrace = [{\"callableName\":\"f3\",\"fileName\":\"info.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"fileName\":\"info.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"fileName\":\"info.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"fileName\":\"info.bal\",\"lineNumber\":27}] username = \"Alex92\" id = 845315");
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
    validateLog(logLines[6], " level = WARN module = \"\" message = \"warn log\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[7], " level = WARN module = \"\" message = \"warn log\" username = \"Alex92\" id = 845315");
    validateLog(logLines[8], " level = WARN module = \"\" message = \"warn log\" error = \"bad sad\"");
    validateLog(logLines[9], " level = WARN module = \"\" message = \"warn log\" error = \"bad sad\" username = \"Alex92\" id = 845315 foo = true");
    validateLog(logLines[10], " level = WARN module = \"\" message = \"warn log\\t\\n\\r\\\\\\\"\" username = \"Alex92\\t\\n\\r\\\\\\\"\"");
    validateLog(logLines[11], " level = WARN module = \"\" message = \"warn log\" stackTrace = [{\"callableName\":\"f3\",\"fileName\":\"warn.bal\",\"lineNumber\":39},{\"callableName\":\"f2\",\"fileName\":\"warn.bal\",\"lineNumber\":35},{\"callableName\":\"f1\",\"fileName\":\"warn.bal\",\"lineNumber\":31},{\"callableName\":\"main\",\"fileName\":\"warn.bal\",\"lineNumber\":27}] username = \"Alex92\" id = 845315");
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

@test:Config {}
public function testObservabilityLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_OBSERVABILITY_PROJECT_LOGFMT}, (),
    "run", temp_dir_path + "/observability-project-logfmt");
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
    string spanContext = ioLines[1];
    validateLog(logLines[5], string ` level = ERROR module = myorg/myproject message = "error log" ${spanContext}`);
    validateLog(logLines[6], string ` level = WARN module = myorg/myproject message = "warn log" ${spanContext}`);
    validateLog(logLines[7], string ` level = INFO module = myorg/myproject message = "info log" ${spanContext}`);
    validateLog(logLines[8], string ` level = DEBUG module = myorg/myproject message = "debug log" ${spanContext}`);
}

@test:Config {}
public function testFileWriteOutputSingleFileOverwriteLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run",
    FILE_WRITE_OUTPUT_OVERWRITE_INPUT_FILE_LOGFMT);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(jsonFILE_WRITE_OUTPUT_OVERWRITE_OUTPUT_FILE_LOGFMT);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 4, INCORRECT_NUMBER_OF_LINES);
        validateLog(fileWriteOutputLines[0], MESSAGE_ERROR_LOGFMT);
        validateLog(fileWriteOutputLines[1], MESSAGE_WARN_LOGFMT);
        validateLog(fileWriteOutputLines[2], MESSAGE_INFO_LOGFMT);
        validateLog(fileWriteOutputLines[3], MESSAGE_DEBUG_LOGFMT);
    }
}

@test:Config {}
public function testFileWriteOutputSingleFileAppendLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run",
    FILE_WRITE_OUTPUT_APPEND_INPUT_FILE_LOGFMT);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_APPEND_OUTPUT_FILE_LOGFMT);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 5, INCORRECT_NUMBER_OF_LINES);
        validateLog(fileWriteOutputLines[0], " level = INFO module = \"\" message = \"info log 0\"");
        validateLog(fileWriteOutputLines[1], MESSAGE_ERROR_LOGFMT);
        validateLog(fileWriteOutputLines[2], MESSAGE_WARN_LOGFMT);
        validateLog(fileWriteOutputLines[3], MESSAGE_INFO_LOGFMT);
        validateLog(fileWriteOutputLines[4], MESSAGE_DEBUG_LOGFMT);
    }
}

@test:Config {}
public function testFileWriteOutputProjectOverwriteLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run",
    temp_dir_path + "/file-write-project/overwrite-logfmt");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_LOGFMT);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
        validateLog(fileWriteOutputLines[0], MESSAGE_ERROR_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[1], MESSAGE_WARN_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[2], MESSAGE_INFO_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[3], MESSAGE_DEBUG_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[4], MESSAGE_ERROR_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[5], MESSAGE_WARN_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[6], MESSAGE_INFO_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[7], MESSAGE_DEBUG_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[8], MESSAGE_ERROR_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[9], MESSAGE_WARN_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[10], MESSAGE_INFO_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[11], MESSAGE_DEBUG_BAR_LOGFMT);
    }
}

@test:Config {}
public function testFileWriteOutputProjectOverwriteLogfmt2() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run",
    temp_dir_path + "/file-write-project/overwrite-logfmt2");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_LOGFMT2);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
        validateLog(fileWriteOutputLines[0], MESSAGE_ERROR_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[1], MESSAGE_WARN_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[2], MESSAGE_INFO_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[3], MESSAGE_DEBUG_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[4], MESSAGE_ERROR_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[5], MESSAGE_WARN_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[6], MESSAGE_INFO_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[7], MESSAGE_DEBUG_BAR_LOGFMT);
    }
}

@test:Config {}
public function testFileWriteOutputProjectAppendLogfmt() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run",
    temp_dir_path + "/file-write-project/append-logfmt");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_LOGFMT);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
        validateLog(fileWriteOutputLines[0], " level = INFO module = \"\" message = \"info log 0\"");
        validateLog(fileWriteOutputLines[1], MESSAGE_ERROR_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[2], MESSAGE_WARN_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[3], MESSAGE_INFO_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[4], MESSAGE_DEBUG_MAIN_LOGFMT);
        validateLog(fileWriteOutputLines[5], MESSAGE_ERROR_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[6], MESSAGE_WARN_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[7], MESSAGE_INFO_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[8], MESSAGE_DEBUG_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[9], MESSAGE_ERROR_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[10], MESSAGE_WARN_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[11], MESSAGE_INFO_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[12], MESSAGE_DEBUG_BAR_LOGFMT);
    }
}

@test:Config {}
public function testFileWriteOutputProjectAppendLogfmt2() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_LOGFMT}, (), "run",
    temp_dir_path + "/file-write-project/append-logfmt2");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_LOGFMT2);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
        validateLog(fileWriteOutputLines[0], " level = INFO module = \"\" message = \"info log 0\"");
        validateLog(fileWriteOutputLines[1], MESSAGE_ERROR_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[2], MESSAGE_WARN_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[3], MESSAGE_INFO_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[4], MESSAGE_DEBUG_FOO_LOGFMT);
        validateLog(fileWriteOutputLines[5], MESSAGE_ERROR_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[6], MESSAGE_WARN_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[7], MESSAGE_INFO_BAR_LOGFMT);
        validateLog(fileWriteOutputLines[8], MESSAGE_DEBUG_BAR_LOGFMT);
    }
}

isolated function validateLog(string log, string output) {
    test:assertTrue(log.includes("time ="), "log does not contain the time");
    test:assertTrue(log.includes(output), "log does not contain the required output");
}

function exec(@untainted string command, @untainted map<string> env = {},
                     @untainted string? dir = (), @untainted string... args) returns Process|error = @java:Method {
    name: "exec",
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.Exec"
} external;

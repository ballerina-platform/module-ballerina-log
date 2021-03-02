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
const string FORMAT_JSON_FILE = "tests/resources/samples/format/format-json.bal";

const string CONFIG_DEBUG_FILE = "tests/resources/config/log-levels/debug/Config.toml";
const string CONFIG_ERROR_FILE = "tests/resources/config/log-levels/error/Config.toml";
const string CONFIG_INFO_FILE = "tests/resources/config/log-levels/info/Config.toml";
const string CONFIG_WARN_FILE = "tests/resources/config/log-levels/warn/Config.toml";
const string CONFIG_FORMAT_JSON = "tests/resources/config/format/Config.toml";
const string PROJECT_CONFIG_GLOBAL_LEVEL = "tests/resources/config/log-project/global/Config.toml";
const string PROJECT_CONFIG_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL = "tests/resources/config/log-project/default/Config.toml";
const string PROJECT_CONFIG_GLOBAL_AND_MODULE_LEVEL = "tests/resources/config/log-project/global-and-module/Config.toml";

const string LEVEL_DEBUG = "level = DEBUG";
const string LEVEL_ERROR = "level = ERROR";
const string LEVEL_ERROR_JSON = "\"level\": \"ERROR\"";
const string LEVEL_INFO = "level = INFO";
const string LEVEL_INFO_JSON = "\"level\": \"INFO \"";
const string LEVEL_WARN = "level = WARN";

const string PACKAGE_SINGLE_FILE = "module = \"\"";
const string PACKAGE_SINGLE_FILE_JSON = "\"module\": \"\"";
const string PACKAGE_DEFAULT = "module = myorg/myproject";
const string PACKAGE_FOO = "module = myorg/myproject.foo";
const string PACKAGE_BAR = "module = myorg/myproject.bar";

const string MESSAGE_INFO = "message = \"info log\"";
const string MESSAGE_INFO_JSON = "\"message\": \"info log\"";
const string MESSAGE_DEBUG = "message = \"debug log\"";
const string MESSAGE_ERROR = "message = \"error log\"";
const string MESSAGE_ERROR_JSON = "\"message\": \"error log\"";
const string MESSAGE_ERROR_WITH_ERR = "message = \"error log\" error = \"bad sad\"";
const string MESSAGE_ERROR_WITH_ERR_JSON = "\"message\": \"error log\", \"error\": \"bad sad\"";
const string MESSAGE_WARN = "message = \"warn log\"";
const string KEY_VALUES1 = "foo = true id = 845315 username = \"Alex92\"";
const string KEY_VALUES1_JSON = "\"foo\": true, \"id\": 845315, \"username\": \"Alex92\"";
const string KEY_VALUES2 = "id = 845315 username = \"Alex92\"";
const string KEY_VALUES2_JSON = "\"id\": 845315, \"username\": \"Alex92\"";

configurable string bal_exec_path = ?;
configurable string temp_dir_path = ?;

@test:Config {}
public function testPrintDebug() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: CONFIG_DEBUG_FILE}, (), "run", PRINT_DEBUG_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_DEBUG, PACKAGE_SINGLE_FILE, MESSAGE_DEBUG, "");
    validateLog(logLines[7], LEVEL_DEBUG, PACKAGE_SINGLE_FILE, MESSAGE_DEBUG, KEY_VALUES1);
    validateLog(logLines[8], LEVEL_DEBUG, PACKAGE_SINGLE_FILE, MESSAGE_DEBUG, KEY_VALUES2);
}

@test:Config {}
public function testPrintError() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", PRINT_ERROR_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, "");
    validateLog(logLines[7], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, KEY_VALUES1);
    validateLog(logLines[8], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, KEY_VALUES2);
    validateLog(logLines[9], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR_WITH_ERR, "");
    validateLog(logLines[10], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR_WITH_ERR, KEY_VALUES1);
    validateLog(logLines[11], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, "stackTrace = " +
    "[{\"callableName\":\"f3\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":38}," +
    "{\"callableName\":\"f2\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":34}," +
    "{\"callableName\":\"f1\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":30}," +
    "{\"callableName\":\"main\",\"moduleName\":\"error\",\"fileName\":\"error.bal\",\"lineNumber\":26}] " +
    "id = 845315 username = \"Alex92\"");
}

@test:Config {}
public function testPrintInfo() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", PRINT_INFO_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_INFO, PACKAGE_SINGLE_FILE, MESSAGE_INFO, "");
    validateLog(logLines[7], LEVEL_INFO, PACKAGE_SINGLE_FILE, MESSAGE_INFO, KEY_VALUES1);
    validateLog(logLines[8], LEVEL_INFO, PACKAGE_SINGLE_FILE, MESSAGE_INFO, KEY_VALUES2);
}

@test:Config {}
public function testPrintWarn() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", PRINT_WARN_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_WARN, PACKAGE_SINGLE_FILE, MESSAGE_WARN, "");
    validateLog(logLines[7], LEVEL_WARN, PACKAGE_SINGLE_FILE, MESSAGE_WARN, KEY_VALUES1);
    validateLog(logLines[8], LEVEL_WARN, PACKAGE_SINGLE_FILE, MESSAGE_WARN, KEY_VALUES2);
}

@test:Config {}
public function testErrorLevel() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: CONFIG_ERROR_FILE}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 7, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, "");
}

@test:Config {}
public function testWarnLevel() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: CONFIG_WARN_FILE}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, "");
    validateLog(logLines[7], LEVEL_WARN, PACKAGE_SINGLE_FILE, MESSAGE_WARN, "");
}

@test:Config {}
public function testInfoLevel() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: CONFIG_INFO_FILE}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, "");
    validateLog(logLines[7], LEVEL_WARN, PACKAGE_SINGLE_FILE, MESSAGE_WARN, "");
    validateLog(logLines[8], LEVEL_INFO, PACKAGE_SINGLE_FILE, MESSAGE_INFO, "");
}

@test:Config {}
public function testDebugLevel() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: CONFIG_DEBUG_FILE}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 10, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_ERROR, PACKAGE_SINGLE_FILE, MESSAGE_ERROR, "");
    validateLog(logLines[7], LEVEL_WARN, PACKAGE_SINGLE_FILE, MESSAGE_WARN, "");
    validateLog(logLines[8], LEVEL_INFO, PACKAGE_SINGLE_FILE, MESSAGE_INFO, "");
    validateLog(logLines[9], LEVEL_DEBUG, PACKAGE_SINGLE_FILE, MESSAGE_DEBUG, "");
}

@test:Config {}
public function testProjectWithoutLogLevel() {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", temp_dir_path
    + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 18, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], LEVEL_ERROR, PACKAGE_DEFAULT, MESSAGE_ERROR, "");
    validateLog(logLines[10], LEVEL_WARN, PACKAGE_DEFAULT, MESSAGE_WARN, "");
    validateLog(logLines[11], LEVEL_INFO, PACKAGE_DEFAULT, MESSAGE_INFO, "");
    validateLog(logLines[12], LEVEL_ERROR, PACKAGE_FOO, MESSAGE_ERROR, "");
    validateLog(logLines[13], LEVEL_WARN, PACKAGE_FOO, MESSAGE_WARN, "");
    validateLog(logLines[14], LEVEL_INFO, PACKAGE_FOO, MESSAGE_INFO, "");
    validateLog(logLines[15], LEVEL_ERROR, PACKAGE_BAR, MESSAGE_ERROR, "");
    validateLog(logLines[16], LEVEL_WARN, PACKAGE_BAR, MESSAGE_WARN, "");
    validateLog(logLines[17], LEVEL_INFO, PACKAGE_BAR, MESSAGE_INFO, "");
}

@test:Config {}
public function testProjectWithGlobalLogLevel() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: PROJECT_CONFIG_GLOBAL_LEVEL}, (),
    "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 15, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], LEVEL_ERROR, PACKAGE_DEFAULT, MESSAGE_ERROR, "");
    validateLog(logLines[10], LEVEL_WARN, PACKAGE_DEFAULT, MESSAGE_WARN, "");
    validateLog(logLines[11], LEVEL_ERROR, PACKAGE_FOO, MESSAGE_ERROR, "");
    validateLog(logLines[12], LEVEL_WARN, PACKAGE_FOO, MESSAGE_WARN, "");
    validateLog(logLines[13], LEVEL_ERROR, PACKAGE_BAR, MESSAGE_ERROR, "");
    validateLog(logLines[14], LEVEL_WARN, PACKAGE_BAR, MESSAGE_WARN, "");
}

@test:Config {}
public function testProjectWithGlobalAndDefualtPackageLogLevel() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: PROJECT_CONFIG_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL},
     (), "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 16, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], LEVEL_ERROR, PACKAGE_DEFAULT, MESSAGE_ERROR, "");
    validateLog(logLines[10], LEVEL_WARN, PACKAGE_DEFAULT, MESSAGE_WARN, "");
    validateLog(logLines[11], LEVEL_INFO, PACKAGE_DEFAULT, MESSAGE_INFO, "");
    validateLog(logLines[12], LEVEL_DEBUG, PACKAGE_DEFAULT, MESSAGE_DEBUG, "");
    validateLog(logLines[13], LEVEL_ERROR, PACKAGE_FOO, MESSAGE_ERROR, "");
    validateLog(logLines[14], LEVEL_ERROR, PACKAGE_BAR, MESSAGE_ERROR, "");
    validateLog(logLines[15], LEVEL_WARN, PACKAGE_BAR, MESSAGE_WARN, "");
}

@test:Config {}
public function testProjectWithGlobalAndModuleLogLevels() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: PROJECT_CONFIG_GLOBAL_AND_MODULE_LEVEL}, (),
    "run", temp_dir_path + "/log-project");
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 16, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], LEVEL_ERROR, PACKAGE_DEFAULT, MESSAGE_ERROR, "");
    validateLog(logLines[10], LEVEL_WARN, PACKAGE_DEFAULT, MESSAGE_WARN, "");
    validateLog(logLines[11], LEVEL_ERROR, PACKAGE_FOO, MESSAGE_ERROR, "");
    validateLog(logLines[12], LEVEL_WARN, PACKAGE_FOO, MESSAGE_WARN, "");
    validateLog(logLines[13], LEVEL_INFO, PACKAGE_FOO, MESSAGE_INFO, "");
    validateLog(logLines[14], LEVEL_DEBUG, PACKAGE_FOO, MESSAGE_DEBUG, "");
    validateLog(logLines[15], LEVEL_ERROR, PACKAGE_BAR, MESSAGE_ERROR, "");
}

@test:Config {}
public function testJsonFormat() {
    Process|error execResult = exec(bal_exec_path, {BALCONFIGFILE: CONFIG_FORMAT_JSON}, (), "run", FORMAT_JSON_FILE);
    Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_INFO_JSON, PACKAGE_SINGLE_FILE_JSON, MESSAGE_INFO_JSON, KEY_VALUES1_JSON);
    validateLog(logLines[7], LEVEL_INFO_JSON, PACKAGE_SINGLE_FILE_JSON, MESSAGE_INFO_JSON, KEY_VALUES2_JSON);
    validateLog(logLines[8], LEVEL_ERROR_JSON, PACKAGE_SINGLE_FILE_JSON, MESSAGE_ERROR_JSON, KEY_VALUES1_JSON);
    validateLog(logLines[9], LEVEL_ERROR_JSON, PACKAGE_SINGLE_FILE_JSON, MESSAGE_ERROR_JSON, KEY_VALUES2_JSON);
    validateLog(logLines[10], LEVEL_ERROR_JSON, PACKAGE_SINGLE_FILE_JSON, MESSAGE_ERROR_JSON, KEY_VALUES1_JSON);
    validateLog(logLines[11], LEVEL_ERROR_JSON, PACKAGE_SINGLE_FILE_JSON, MESSAGE_ERROR_JSON, "\"stackTrace\": " +
    "[{\"callableName\":\"f3\",\"moduleName\":\"format-json\",\"fileName\":\"format-json.bal\",\"lineNumber\":38}," +
    "{\"callableName\":\"f2\",\"moduleName\":\"format-json\",\"fileName\":\"format-json.bal\",\"lineNumber\":34}," +
    "{\"callableName\":\"f1\",\"moduleName\":\"format-json\",\"fileName\":\"format-json.bal\",\"lineNumber\":30}," +
    "{\"callableName\":\"main\",\"moduleName\":\"format-json\",\"fileName\":\"format-json.bal\",\"lineNumber\":26}]," +
    " \"id\": 845315, \"username\": \"Alex92\"}");
}

isolated function validateLog(string log, string level, string package, string message, string keyValues) {
    test:assertTrue(log.includes(level));
    test:assertTrue(log.includes(package));
    test:assertTrue(log.includes(message));
    test:assertTrue(log.includes(keyValues));
}

function exec(@untainted string command, @untainted map<string> env = {},
                     @untainted string? dir = (), @untainted string... args) returns Process|error = @java:Method {
    name: "exec",
    'class: "org.ballerinalang.stdlib.log.testutils.nativeimpl.Exec"
} external;

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

const string FILE_WRITE_OUTPUT_OVERWRITE_INPUT_FILE_JSON = "tests/resources/samples/file-write-output/single-file/overwrite-json.bal";
const string FILE_WRITE_OUTPUT_APPEND_INPUT_FILE_JSON = "tests/resources/samples/file-write-output/single-file/append-json.bal";

const string FILE_WRITE_OUTPUT_OVERWRITE_OUTPUT_FILE_JSON = "build/tmp/output/overwrite-json.log";
const string FILE_WRITE_OUTPUT_APPEND_OUTPUT_FILE_JSON = "build/tmp/output/append-json.log";
const string FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_JSON = "build/tmp/output/project-overwrite-json.log";
const string FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_JSON2 = "build/tmp/output/project-overwrite-json2.log";
const string FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_JSON = "build/tmp/output/project-append-json.log";
const string FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_JSON2 = "build/tmp/output/project-append-json2.log";

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
public function testPrintDebugJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run", PRINT_DEBUG_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[7], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[8], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"debug.bal\", \"lineNumber\":22}]}}");
    validateLogJson(logLines[9], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"debug.bal\", \"lineNumber\":22}]}, \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[10], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"stackTrace\":[\"callableName: f3  fileName: debug.bal lineNumber: 48\", \"callableName: f2  fileName: debug.bal lineNumber: 44\", \"callableName: f1  fileName: debug.bal lineNumber: 40\", \"callableName: main  fileName: debug.bal lineNumber: 29\"], \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[12], "\", \"level\":\"DEBUG\", \"module\":\"\", \"message\":\"debug log\", \"error\":{\"causes\":[], \"message\":{\"code\":403, \"details\":\"Authentication failed\"}, \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"debug.bal\", \"lineNumber\":35}]}}");
}

@test:Config {}
public function testPrintErrorJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_ERROR_JSON}, (), "run", PRINT_ERROR_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[7], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[8], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"error.bal\", \"lineNumber\":22}]}}");
    validateLogJson(logLines[9], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"error.bal\", \"lineNumber\":22}]}, \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[10], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"stackTrace\":[\"callableName: f3  fileName: error.bal lineNumber: 48\", \"callableName: f2  fileName: error.bal lineNumber: 44\", \"callableName: f1  fileName: error.bal lineNumber: 40\", \"callableName: main  fileName: error.bal lineNumber: 29\"], \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[12], "\", \"level\":\"ERROR\", \"module\":\"\", \"message\":\"error log\", \"error\":{\"causes\":[], \"message\":{\"code\":403, \"details\":\"Authentication failed\"}, \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"error.bal\", \"lineNumber\":35}]}}");
}

@test:Config {}
public function testPrintInfoJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INFO_JSON}, (), "run", PRINT_INFO_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[7], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[8], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"info.bal\", \"lineNumber\":22}]}}");
    validateLogJson(logLines[9], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"info.bal\", \"lineNumber\":22}]}, \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[10], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"stackTrace\":[\"callableName: f3  fileName: info.bal lineNumber: 48\", \"callableName: f2  fileName: info.bal lineNumber: 44\", \"callableName: f1  fileName: info.bal lineNumber: 40\", \"callableName: main  fileName: info.bal lineNumber: 29\"], \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[12], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log\", \"error\":{\"causes\":[], \"message\":{\"code\":403, \"details\":\"Authentication failed\"}, \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"info.bal\", \"lineNumber\":35}]}}");
}

@test:Config {}
public function testPrintWarnJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_WARN_JSON}, (), "run", PRINT_WARN_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\"}");
    validateLogJson(logLines[6], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[7], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[8], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"warn.bal\", \"lineNumber\":22}]}}");
    validateLogJson(logLines[9], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"error\":{\"causes\":[], \"message\":\"bad sad\", \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"warn.bal\", \"lineNumber\":22}]}, \"username\":\"Alex92\", \"id\":845315, \"foo\":true}");
    validateLogJson(logLines[10], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\\t\\n\\r\\\\\\\"\", \"username\":\"Alex92\\t\\n\\r\\\\\\\"\"}");
    validateLogJson(logLines[11], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"stackTrace\":[\"callableName: f3  fileName: warn.bal lineNumber: 48\", \"callableName: f2  fileName: warn.bal lineNumber: 44\", \"callableName: f1  fileName: warn.bal lineNumber: 40\", \"callableName: main  fileName: warn.bal lineNumber: 29\"], \"username\":\"Alex92\", \"id\":845315}");
    validateLogJson(logLines[12], "\", \"level\":\"WARN\", \"module\":\"\", \"message\":\"warn log\", \"error\":{\"causes\":[], \"message\":{\"code\":403, \"details\":\"Authentication failed\"}, \"detail\":{}, \"stackTrace\":[{\"callableName\":\"main\", \"moduleName\":null, \"fileName\":\"warn.bal\", \"lineNumber\":35}]}}");
}

@test:Config {}
public function testErrorLevelJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_ERROR_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
}

@test:Config {}
public function testWarnLevelJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_WARN_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 7, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_JSON);
}

@test:Config {}
public function testInfoLevelJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INFO_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_JSON);
    validateLogJson(logLines[7], MESSAGE_INFO_JSON);
}

@test:Config {}
public function testDebugLevelJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_JSON);
    validateLogJson(logLines[7], MESSAGE_INFO_JSON);
    validateLogJson(logLines[8], MESSAGE_DEBUG_JSON);
}

@test:Config {}
public function testProjectWithoutLogLevelJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_WITHOUT_LEVEL_JSON}, (), "run", temp_dir_path
    + "/log-project");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
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
public function testProjectWithGlobalLogLevelJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_LEVEL_JSON}, (),
    "run", temp_dir_path + "/log-project");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 11, INCORRECT_NUMBER_OF_LINES);
    validateLogJson(logLines[5], MESSAGE_ERROR_MAIN_JSON);
    validateLogJson(logLines[6], MESSAGE_WARN_MAIN_JSON);
    validateLogJson(logLines[7], MESSAGE_ERROR_FOO_JSON);
    validateLogJson(logLines[8], MESSAGE_WARN_FOO_JSON);
    validateLogJson(logLines[9], MESSAGE_ERROR_BAR_JSON);
    validateLogJson(logLines[10], MESSAGE_WARN_BAR_JSON);
}

@test:Config {}
public function testProjectWithGlobalAndDefualtPackageLogLevelJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_AND_DEFAULT_PACKAGE_LEVEL_JSON},
     (), "run", temp_dir_path + "/log-project");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
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
public function testProjectWithGlobalAndModuleLogLevelsJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_PROJECT_GLOBAL_AND_MODULE_LEVEL_JSON}, (),
    "run", temp_dir_path + "/log-project");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
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
public function testObservabilityJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_OBSERVABILITY_PROJECT_JSON}, (),
    "run", temp_dir_path + "/observability-project-json");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);

    io:ReadableByteChannel readableOutResult = result.stdout();
    io:ReadableCharacterChannel sc2 = new (readableOutResult, UTF_8);
    string outText2 = check sc2.read(100000);
    string[] ioLines = re`\n`.split(outText2);
    string spanContext = ioLines[ioLines.length() - 1];
    validateLogJson(logLines[5], string `", "level":"ERROR", "module":"myorg/myproject", "message":"error log", ${spanContext}}`);
    validateLogJson(logLines[6], string `", "level":"WARN", "module":"myorg/myproject", "message":"warn log", ${spanContext}}`);
    validateLogJson(logLines[7], string `", "level":"INFO", "module":"myorg/myproject", "message":"info log", ${spanContext}}`);
    validateLogJson(logLines[8], string `", "level":"DEBUG", "module":"myorg/myproject", "message":"debug log", ${spanContext}}`);
}

@test:Config {}
public function testSetOutputFileSingleFileOverwriteJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run",
    FILE_WRITE_OUTPUT_OVERWRITE_INPUT_FILE_JSON);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_OVERWRITE_OUTPUT_FILE_JSON);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 4, INCORRECT_NUMBER_OF_LINES);
        validateLogJson(fileWriteOutputLines[0], MESSAGE_ERROR_JSON);
        validateLogJson(fileWriteOutputLines[1], MESSAGE_WARN_JSON);
        validateLogJson(fileWriteOutputLines[2], MESSAGE_INFO_JSON);
        validateLogJson(fileWriteOutputLines[3], MESSAGE_DEBUG_JSON);
    }
}

@test:Config {}
public function testSetOutputFileSingleFileAppendJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run",
    FILE_WRITE_OUTPUT_APPEND_INPUT_FILE_JSON);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_APPEND_OUTPUT_FILE_JSON);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 5, INCORRECT_NUMBER_OF_LINES);
        validateLogJson(fileWriteOutputLines[0], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log 0\"}");
        validateLogJson(fileWriteOutputLines[1], MESSAGE_ERROR_JSON);
        validateLogJson(fileWriteOutputLines[2], MESSAGE_WARN_JSON);
        validateLogJson(fileWriteOutputLines[3], MESSAGE_INFO_JSON);
        validateLogJson(fileWriteOutputLines[4], MESSAGE_DEBUG_JSON);
    }
}

@test:Config {}
public function testSetOutputFileProjectOverwriteJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run",
    temp_dir_path + "/file-write-project/overwrite-json");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_JSON);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 12, INCORRECT_NUMBER_OF_LINES);
        validateLogJson(fileWriteOutputLines[0], MESSAGE_ERROR_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[1], MESSAGE_WARN_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[2], MESSAGE_INFO_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[3], MESSAGE_DEBUG_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[4], MESSAGE_ERROR_FOO_JSON);
        validateLogJson(fileWriteOutputLines[5], MESSAGE_WARN_FOO_JSON);
        validateLogJson(fileWriteOutputLines[6], MESSAGE_INFO_FOO_JSON);
        validateLogJson(fileWriteOutputLines[7], MESSAGE_DEBUG_FOO_JSON);
        validateLogJson(fileWriteOutputLines[8], MESSAGE_ERROR_BAR_JSON);
        validateLogJson(fileWriteOutputLines[9], MESSAGE_WARN_BAR_JSON);
        validateLogJson(fileWriteOutputLines[10], MESSAGE_INFO_BAR_JSON);
        validateLogJson(fileWriteOutputLines[11], MESSAGE_DEBUG_BAR_JSON);
    }
}

@test:Config {}
public function testSetOutputFileProjectOverwriteJson2() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run",
    temp_dir_path + "/file-write-project/overwrite-json2");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_OVERWRITE_PROJECT_OUTPUT_FILE_JSON2);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
        validateLogJson(fileWriteOutputLines[0], MESSAGE_ERROR_FOO_JSON);
        validateLogJson(fileWriteOutputLines[1], MESSAGE_WARN_FOO_JSON);
        validateLogJson(fileWriteOutputLines[2], MESSAGE_INFO_FOO_JSON);
        validateLogJson(fileWriteOutputLines[3], MESSAGE_DEBUG_FOO_JSON);
        validateLogJson(fileWriteOutputLines[4], MESSAGE_ERROR_BAR_JSON);
        validateLogJson(fileWriteOutputLines[5], MESSAGE_WARN_BAR_JSON);
        validateLogJson(fileWriteOutputLines[6], MESSAGE_INFO_BAR_JSON);
        validateLogJson(fileWriteOutputLines[7], MESSAGE_DEBUG_BAR_JSON);
    }
}

@test:Config {}
public function testSetOutputFileProjectAppendJson() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run",
    temp_dir_path + "/file-write-project/append-json");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_JSON);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
        validateLogJson(fileWriteOutputLines[0], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log 0\"}");
        validateLogJson(fileWriteOutputLines[1], MESSAGE_ERROR_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[2], MESSAGE_WARN_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[3], MESSAGE_INFO_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[4], MESSAGE_DEBUG_MAIN_JSON);
        validateLogJson(fileWriteOutputLines[5], MESSAGE_ERROR_FOO_JSON);
        validateLogJson(fileWriteOutputLines[6], MESSAGE_WARN_FOO_JSON);
        validateLogJson(fileWriteOutputLines[7], MESSAGE_INFO_FOO_JSON);
        validateLogJson(fileWriteOutputLines[8], MESSAGE_DEBUG_FOO_JSON);
        validateLogJson(fileWriteOutputLines[9], MESSAGE_ERROR_BAR_JSON);
        validateLogJson(fileWriteOutputLines[10], MESSAGE_WARN_BAR_JSON);
        validateLogJson(fileWriteOutputLines[11], MESSAGE_INFO_BAR_JSON);
        validateLogJson(fileWriteOutputLines[12], MESSAGE_DEBUG_BAR_JSON);
    }
}

@test:Config {}
public function testSetOutputFileProjectAppendJson2() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_DEBUG_JSON}, (), "run",
    temp_dir_path + "/file-write-project/append-json2");
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();

    string[]|io:Error fileWriteOutputLines = io:fileReadLines(FILE_WRITE_OUTPUT_APPEND_PROJECT_OUTPUT_FILE_JSON2);
    test:assertTrue(fileWriteOutputLines is string[]);
    if fileWriteOutputLines is string[] {
        test:assertEquals(fileWriteOutputLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
        validateLogJson(fileWriteOutputLines[0], "\", \"level\":\"INFO\", \"module\":\"\", \"message\":\"info log 0\"}");
        validateLogJson(fileWriteOutputLines[1], MESSAGE_ERROR_FOO_JSON);
        validateLogJson(fileWriteOutputLines[2], MESSAGE_WARN_FOO_JSON);
        validateLogJson(fileWriteOutputLines[3], MESSAGE_INFO_FOO_JSON);
        validateLogJson(fileWriteOutputLines[4], MESSAGE_DEBUG_FOO_JSON);
        validateLogJson(fileWriteOutputLines[5], MESSAGE_ERROR_BAR_JSON);
        validateLogJson(fileWriteOutputLines[6], MESSAGE_WARN_BAR_JSON);
        validateLogJson(fileWriteOutputLines[7], MESSAGE_INFO_BAR_JSON);
        validateLogJson(fileWriteOutputLines[8], MESSAGE_DEBUG_BAR_JSON);
    }
}

isolated function validateLogJson(string log, string output) {
    test:assertTrue(isValidJsonString(log), "log output is not a valid json string");
    test:assertTrue(log.includes("{\"time\":\""), "log does not contain the time");
    test:assertTrue(log.includes(output), string `log: ${log} does not contain the output: ${output}`);
}

isolated function isValidJsonString(string log) returns boolean {
    json|error j = value:fromJsonString(log);
    return j is json ? true : false;
}

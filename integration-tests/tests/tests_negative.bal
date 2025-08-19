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
import ballerina/test;

const CONFIG_INVALID_GLOBAL_LOG_LEVEL = "tests/resources/config/invalid/global/Config.toml";
const CONFIG_INVALID_MODULE_LOG_LEVEL = "tests/resources/config/invalid/module/Config.toml";
const FILE_WRITE_OUTPUT_NEGATIVE = "tests/resources/samples/file-write-output/single-file/set-output-file-negative.bal";
const CONFIG_INVALID_GLOBAL_DESTINATION = "tests/resources/config/invalid/global/destination/Config.toml";

@test:Config {}
public function testGlobalLogLevelNegative() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INVALID_GLOBAL_LOG_LEVEL}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 7, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes("configurable variable 'level' is expected to be of type 'ballerina/log:2:(ballerina/log:2:Level & readonly)', but found 'string'"));
}

@test:Config {}
public function testModuleLogLevelNegative() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INVALID_MODULE_LOG_LEVEL}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes("configurable variable 'modules.level' is expected to be of type 'ballerina/log:2:Level', but found 'string'"));
}

@test:Config {}
public function testSetOutputFileNegative() returns error? {
    Process|error execResult = exec(bal_exec_path, {}, (), "run", FILE_WRITE_OUTPUT_NEGATIVE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 7, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[6].includes("error: The given path is not valid. Should be a file with .log extension."), "module log level is not validated");
}

@test:Config {
    groups: ["logger"]
}
public function testInvalidGlobalDestination() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INVALID_GLOBAL_DESTINATION}, (), "run", LOG_LEVEL_FILE);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re`\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes("error: The given destination path: 'invalid_file' is not valid. Log destination should be either 'stderr', 'stdout' or a valid file with .log extension."));
}

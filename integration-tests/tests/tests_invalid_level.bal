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
import ballerina/regex;
import ballerina/test;

const string CONFIG_INVALID_GLOBAL_LOG_LEVEL = "tests/resources/config/invalid/global/Config.toml";
const string CONFIG_INVALID_MODULE_LOG_LEVEL = "tests/resources/config/invalid/module/Config.toml";

@test:Config {}
public function testInvalidGlobalLogLevel() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INVALID_GLOBAL_LOG_LEVEL}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int _ = checkpanic result.waitForExit();
    int _ = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes("error: invalid log level: debug {}"), "global log level is not validated");
}

@test:Config {}
public function testInvalidModuleLogLevel() {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: CONFIG_INVALID_MODULE_LOG_LEVEL}, (), "run", LOG_LEVEL_FILE);
    Process result = checkpanic execResult;
    int _ = checkpanic result.waitForExit();
    int _ = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes("error: invalid log level: debug for module: myorg/myproject.foo {}"), "module log level is not validated");
}

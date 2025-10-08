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

import ballerina/test;
import ballerina/io;

const MASKED_LOGGER_CONFIG_FILE = "tests/resources/samples/masked-logger/Config.toml";

@test:Config {
    groups: ["maskedLogger"]
}
function testMaskedLogger() returns error? {
    Process|error execResult = exec(bal_exec_path, {BAL_CONFIG_FILES: MASKED_LOGGER_CONFIG_FILE}, (), "run", string `${temp_dir_path}/masked-logger`);
    Process result = check execResult;
    int _ = check result.waitForExit();
    int _ = check result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = check sc.read(100000);
    string[] logLines = re `\n`.split(outText.trim());
    test:assertEquals(logLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
    test:assertTrue(logLines[5].includes(string `level=INFO module=wso2/masked_logger message="user logged in" userDetails={"name":"John Doe","password":"*****","mail":"joh**************com"}`));
    test:assertTrue(logLines[6].includes(string `level=DEBUG module=wso2/masked_logger message="user details: {\"name\":\"John Doe\",\"password\":\"*****\",\"mail\":\"joh**************com\"}"`));
    test:assertTrue(logLines[7].includes(string `level=ERROR module=wso2/masked_logger message="error occurred" userDetails={"name":"John Doe","password":"*****","mail":"joh**************com"}`));
    check sc.close();
}

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

final Logger maskerJsonLogger = check fromConfig(enableSensitiveDataMasking = true);
final Logger maskerLogger = check fromConfig(enableSensitiveDataMasking = true, format = LOGFMT);

string[] maskedLogs = [];

function addMaskedLogs(io:FileOutputStream fileOutputStream, io:Printable... values) {
    var firstValue = values[0];
    if firstValue is string {
        maskedLogs.push(firstValue);
    }
}

final readonly & User user = {
    name: "John Doe",
    ssn: "123-45-6789",
    password: "password123",
    mail: "john.doe@example.com",
    creditCard: "4111-1111-1111-1111"
};

isolated function getUser() returns User => user;

@test:Config {
    groups: ["logMasking"]
}
function testLogMasking() returns error? {
    test:when(mock_fprintln).call("addMaskedLogs");
    maskerJsonLogger.printInfo("user logged in", user = user);
    string expectedLog = string `"message":"user logged in","user":{"name":"John Doe","password":"*****","mail":"joh**************com"},"env":"test"`;
    test:assertEquals(maskedLogs.length(), 1);
    test:assertTrue(maskedLogs[0].includes(expectedLog));
    maskedLogs.removeAll();

    maskerLogger.printInfo("user logged in", user = user);
    expectedLog = string `message="user logged in" user={"name":"John Doe","password":"*****","mail":"joh**************com"} env="test"`;
    test:assertEquals(maskedLogs.length(), 1);
    test:assertTrue(maskedLogs[0].includes(expectedLog));
    maskedLogs.removeAll();

    map<json> userTmp = user;
    maskerJsonLogger.printInfo("user logged in", user = userTmp);
    expectedLog = string `"message":"user logged in","user":{"name":"John Doe","password":"*****","mail":"joh**************com"},"env":"test"`;
    test:assertEquals(maskedLogs.length(), 1);
    test:assertTrue(maskedLogs[0].includes(expectedLog));
    maskedLogs.removeAll();

    userTmp = check user.cloneWithType();
    maskerJsonLogger.printInfo("user logged in", user = userTmp);
    expectedLog = string `"message":"user logged in","user":{"name":"John Doe","ssn":"123-45-6789","password":"password123","mail":"john.doe@example.com","creditCard":"4111-1111-1111-1111"},"env":"test"`;
    test:assertEquals(maskedLogs.length(), 1);
    test:assertTrue(maskedLogs[0].includes(expectedLog));
    maskedLogs.removeAll();

    maskerLogger.printDebug(`user login event. user details: ${user}`);
    expectedLog = string `message="user login event. user details: {\"name\":\"John Doe\",\"password\":\"*****\",\"mail\":\"joh**************com\"}" env="test"`;
    test:assertEquals(maskedLogs.length(), 1);
    test:assertTrue(maskedLogs[0].includes(expectedLog));
    maskedLogs.removeAll();

    maskerLogger.printWarn("user login attempt failed", user = getUser);
    expectedLog = string `message="user login attempt failed" user={"name":"John Doe","password":"*****","mail":"joh**************com"} env="test"`;
    test:assertEquals(maskedLogs.length(), 1);
    test:assertTrue(maskedLogs[0].includes(expectedLog));
    maskedLogs.removeAll();
}

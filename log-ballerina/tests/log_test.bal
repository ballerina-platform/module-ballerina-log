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

import ballerina/test;

string logMessage = "";

@test:Mock {
    moduleName: "ballerina/log",
    functionName: "printLogFmtExtern"
}
test:MockFunction mock_printLogFmtExtern = new();

function mockPrintLogFmtExtern(LogRecord msg) {
    logMessage = msg.message;
}

@test:Config {}
function testFunc() {
    test:when(mock_printLogFmtExtern).call("mockPrintLogFmtExtern");

    main();
    test:assertEquals(logMessage, "something went wrong");
}

public isolated function main() {
    error err = error("bad sad");
    printDebug("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315, attempts = isolated function() returns int { return 3;});
    printError("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315, attempts = isolated function() returns int { return 3;});
    printInfo("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315, attempts = isolated function() returns int { return 3;});
    printWarn("something went wrong", 'error = err, username = "Alex92", admin = true, id = 845315, attempts = isolated function() returns int { return 3;});
}

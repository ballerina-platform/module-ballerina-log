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

import ballerina/log;

type ContextualInfo record {
    string id;
    string ctxMsg;
    map<string> additionalInfo;
};

isolated function getContextualInfo() returns ContextualInfo => {
    id: "ctx-1234",
    ctxMsg: "Contextual message",
    additionalInfo: {
        key1: "value1",
        key2: "value2"
    }
};

const LOGGER_ID = "log-123";

log:Logger rootLogger = log:root();
log:Logger logger1 = check rootLogger.withContext(correlationId = "12345");
log:Logger logger2 = check rootLogger.withContext(workerId = "value2", loggerInfo = `logger with id: ${LOGGER_ID}`, ctx = getContextualInfo);

public function main() {
    rootLogger.printInfo("This is a root logger message", logger = "root");
    logger1.printError("This is a logger 1 message", logger = "logger1", id = "abcde");
    logger2.printWarn("This is a logger 2 message", logger = "logger2", id = "fghij");
}

// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/java;
import ballerina/stringutils;
import ballerina/test;

@test:Config {}
function testFormat() {
    string traceLogMessage = "[id: 0x65d56de4, correlatedSource: n/a, host:localhost/0:0:0:0:0:0:0:1:9090 - " +
                             "remote:/0:0:0:0:0:0:0:1:52872] OUTBOUND: DefaultFullHttpResponse(decodeResult: success, " +
                             "version: HTTP/1.1, content: CompositeByteBuf(ridx: 0, widx: 55, cap: 55, " +
                             "components=1))\nHTTP/1.1 200 OK\ncontent-type: application/json\ncontent-length: " +
                             "55\nserver: wso2-http-transport\ndate: Fri, 16 Mar 2018 14:26:12 +0530, " +
                             "55B\n{\"message\":\"Max entity body size resource is invoked.\"} ";
    string result = format(traceLogMessage);
    test:assertTrue(stringutils:contains(result, "[id: 0x65d56de4, correlatedSource: n/a, " +
                                                 "host:localhost/0:0:0:0:0:0:0:1:9090 - remote:/0:0:0:0:0:0:0:1:52872] " +
                                                 "OUTBOUND: DefaultFullHttpResponse(decodeResult: success, " +
                                                 "version: HTTP/1.1, content: CompositeByteBuf(ridx: 0, widx: 55, " +
                                                 "cap: 55, components"));
}

@test:Config {}
function testFormatNull() {
    boolean result = formatNull();
    test:assertFalse(result, "Exception thrown");
}

@test:Config {}
function testFormatWithCustomValues() {
    string traceLogMessage = "[id: 0x65d56de4, correlatedSource: n/a, host:localhost/0:0:0:0:0:0:0:1:9090 - " +
                             "remote:/0:0:0:0:0:0:0:1:52872] OUTBOUND: DefaultFullHttpResponse(decodeResult: success, " +
                             "version: HTTP/1.1, content: CompositeByteBuf(ridx: 0, widx: 55, cap: 55, " +
                             "components=1))\nHTTP/1.1 200 OK\ncontent-type: application/json\ncontent-length: " +
                             "55\nserver: wso2-http-transport\ndate: Fri, 16 Mar 2018 14:26:12 +0530, " +
                             "55B\n{\"message\":\"Max entity body size resource is invoked.\"} ";
    string result = formatWithCustomValues(traceLogMessage + " {0,number}", "logger", "rb name", "class", "method",
    100, 1000, 12321312, 0, 12321312);
    test:assertTrue(stringutils:contains(result, "class"), "Log record doesn't contain class.");
    test:assertTrue(stringutils:contains(result, "method"), "Log record doesn't contain method.");
    test:assertTrue(stringutils:contains(result, "100"), "Log record doesn't contain parameters.");
}

@test:Config {}
function testGetHead() {
    string result = getHead();
    test:assertTrue(stringutils:contains(result, ""));
}

@test:Config {}
function testGetTail() {
    string result = getTail();
    test:assertTrue(stringutils:contains(result, ""));
}

public function format(string logMessage) returns string = @java:Method {
    class: "org/ballerinalang/stdlib/log/testutils/JsonLogFormatterTestUtils"
} external;

public function formatNull() returns boolean = @java:Method {
    class: "org/ballerinalang/stdlib/log/testutils/JsonLogFormatterTestUtils"
} external;

public function formatWithCustomValues(string logMessage, string logger, string resourceBundleName, string className,
string methodName, int param, int threadId, int sequenceNumber, int millis, int calMillis) returns string = @java:Method {
    class: "org/ballerinalang/stdlib/log/testutils/JsonLogFormatterTestUtils"
} external;

public function getHead() returns string = @java:Method {
    class: "org/ballerinalang/stdlib/log/testutils/JsonLogFormatterTestUtils"
} external;

public function getTail() returns string = @java:Method {
    class: "org/ballerinalang/stdlib/log/testutils/JsonLogFormatterTestUtils"
} external;

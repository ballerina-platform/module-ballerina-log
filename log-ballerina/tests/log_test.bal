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

@test:Config {}
isolated function testAppendKeyValue() {
    test:assertEquals(appendKeyValue("username", "Alex92"), " username = \"Alex92\"");
    test:assertEquals(appendKeyValue("id", 845315), " id = 845315");
    test:assertEquals(appendKeyValue("foo", true), " foo = true");
}

@test:Config {}
isolated function testGetOutput() {
    test:assertEquals(getOutput("Inside main function", " foo = true id = 845315 username = \"Alex92\""),
    "message = \"Inside main function\" foo = true id = 845315 username = \"Alex92\"");
    test:assertEquals(getOutput("Inside main function", " foo = true id = 845315 username = \"Alex92\"", error("bad sad")),
        "message = \"Inside main function\" error = \"bad sad\" foo = true id = 845315 username = \"Alex92\"");
}

@test:Config {}
isolated function testGetMessage() {
    test:assertEquals(getMessage("Inside main function"), "\"Inside main function\"");
    test:assertEquals(getMessage("Inside main function", error("bad sad")), "\"Inside main function\" error = \"bad sad\"");
}

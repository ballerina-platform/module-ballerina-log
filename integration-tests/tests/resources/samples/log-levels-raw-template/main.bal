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

import ballerina/log;

public function main() {
    string myname = "Alex92";
    int myage = 25;
    string action1 = "action1";
    string action2 = "action2";
    string action3 = "action3";
    log:printError(`error: My name is ${myname} and my age is ${myage}`);
    log:printWarn(`warning: My name is ${myname} and my age is ${myage}`);
    log:printInfo(`info: My name is ${myname} and my age is ${myage}`);
    log:printDebug(`debug: My name is ${myname} and my age is ${myage}`);
    log:printInfo("User details", details = `name: ${myname}, age: ${myage}`, actions = `actions: ${action1}, ${action2}, ${action3}`);   
}


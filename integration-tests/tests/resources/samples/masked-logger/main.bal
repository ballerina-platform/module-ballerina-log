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

type User record {|
    string name;
    @log:SensitiveData
    string ssn;
    @log:SensitiveData {strategy: {replacement: "*****"}}
    string password;
    @log:SensitiveData {strategy: {replacement: maskStringPartially}}
    string mail;
    @log:SensitiveData {strategy: log:EXCLUDE}
    string creditCard;
|};

isolated function maskStringPartially(string input) returns string {
    int len = input.length();
    if len <= 6 {
        return "******";
    }
    string maskedString = input.substring(0, 3);
    foreach int i in 3 ... len - 4 {
        maskedString += "*";
    }
    maskedString += input.substring(len - 3);
    return maskedString;
};

final readonly & User user = {
    name: "John Doe",
    ssn: "123-45-6789",
    password: "P@ssw0rd!",
    mail: "john.doe@example.com",
    creditCard: "4111-1111-1111-1111"
};

isolated function getUser() returns User => user;

public function main() {
    log:printInfo("user logged in", userDetails = user);
    log:printDebug(`user details: ${user}`);
    log:printError("error occurred", userDetails = getUser);
}

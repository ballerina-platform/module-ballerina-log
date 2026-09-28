// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import ballerina/os as env;

// The temporary directory reached through an aliased import of the same module
public function logToTempFromAliasedEnvironment() returns error? {
    check log:setOutputFile(env:getEnv("TMPDIR") + "/application.log");
}

// The path supplied by name, with the write option written before it
public function logToTempWithNamedArguments() returns error? {
    check log:setOutputFile(option = log:OVERWRITE, path = "/tmp/application.log");
}

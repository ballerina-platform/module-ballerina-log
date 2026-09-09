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
import ballerina/os;

// A shared temporary directory: readable by every local account, and another
// user can create the file first so the service appends to a file it does not own
public function logToTemp() returns error? {
    check log:setOutputFile("/tmp/application.log");
}

// The same directory reached through the environment
public function logToTempFromEnvironment() returns error? {
    check log:setOutputFile(os:getEnv("TMPDIR") + "/application.log");
}

// The result is bound rather than checked, which the call-statement hook would miss
public function logToTempWithBoundResult() {
    log:Error? result = log:setOutputFile("/var/tmp/application.log");
    if result is log:Error {
        return;
    }
}

// The current API: a file destination on a logger configuration
public function logToTempViaLoggerConfig() returns error? {
    log:Logger _ = check log:fromConfig({
        destinations: [{'type: log:FILE, path: "/tmp/service.log"}]
    });
}

// The same with the destinations supplied as a named argument
public function logToTempViaNamedDestinations() returns error? {
    log:Logger _ = check log:fromConfig(
        destinations = [{'type: log:FILE, path: "/dev/shm/service.log"}]
    );
}

// Negative case - a directory the service owns
public function logToOwnedDirectory() returns error? {
    check log:setOutputFile("./logs/application.log");
}

// Negative case - a directory whose name only begins like a temporary one
public function logToSimilarlyNamedDirectory() returns error? {
    check log:setOutputFile("/tmpfiles/application.log");
}

// Negative case - a logger configuration writing under an owned directory
public function logToOwnedDirectoryViaLoggerConfig() returns error? {
    log:Logger _ = check log:fromConfig({
        destinations: [{'type: log:FILE, path: "./logs/service.log"}]
    });
}

// Negative case - a case-sensitive filesystem treats this as a different directory
public function logToUppercaseTemp() returns error? {
    check log:setOutputFile("/TMP/application.log");
}

// Negative case - a different environment variable from TMPDIR on POSIX
public function logToLowercaseEnvironmentVariable() returns error? {
    check log:setOutputFile(os:getEnv("tmpdir") + "/application.log");
}

// Negative case - on POSIX a backslash is an ordinary filename character, not a separator, so this
// names a single file at the root rather than a file under /tmp
public function logToPosixPathWithBackslash() returns error? {
    check log:setOutputFile("/tmp\\application.log");
}

// A Windows temporary directory, written with the escaping Ballerina requires for a backslash
public function logToWindowsTemp() returns error? {
    check log:setOutputFile("C:\\Temp\\application.log");
}

// Negative case - concatenation without a separator lands beside the directory, not inside it
public function logToConcatenatedSiblingPath() returns error? {
    check log:setOutputFile("/tmp" + "file.log");
}

// A concatenation with an explicit separator still lands inside the directory
public function logToConcatenatedPath() returns error? {
    check log:setOutputFile("/tmp" + "/file.log");
}

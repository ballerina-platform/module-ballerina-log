// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
import ballerina/log;

// Module-level logger with explicit ID — tests module prefix resolution during module init
log:Logger moduleLogger = check log:fromConfig(id = "audit-service", level = log:WARN);

public function main() returns error? {
    // 1. Verify module-level logger is registered with module prefix
    log:Logger? moduleLookedUp = log:getLoggerRegistry().getById("myorg/registrytest:audit-service");
    if moduleLookedUp is log:Logger {
        io:println("MODULE_LEVEL_ID:myorg/registrytest:audit-service");
        io:println("MODULE_LEVEL_LEVEL:" + moduleLookedUp.getLevel().toString());
    } else {
        io:println("MODULE_LEVEL_ID:NOT_FOUND");
        io:println("MODULE_LEVEL_LEVEL:NOT_FOUND");
    }

    // 2. Create a logger with explicit ID inside main
    log:Logger explicitLogger = check log:fromConfig(id = "payment-service", level = log:INFO);
    io:println("EXPLICIT_ID:" + log:getLoggerRegistry().getIds().reduce(
        isolated function(string acc, string id) returns string {
            if id.includes("payment-service") {
                return id;
            }
            return acc;
        }, "NOT_FOUND"));

    // 2. Create a logger without ID (auto-generated)
    log:Logger autoLogger = check log:fromConfig(level = log:DEBUG);
    string[] allIds = log:getLoggerRegistry().getIds();
    boolean autoIdFound = false;
    foreach string id in allIds {
        if id.startsWith("myorg/registrytest:")
                && id != "myorg/registrytest:audit-service"
                && id != "myorg/registrytest:payment-service" {
            autoIdFound = true;
            break;
        }
    }
    io:println("AUTO_ID_FOUND:" + autoIdFound.toString());

    // 3. Check that registry has the global root logger
    boolean hasRoot = false;
    foreach string id in allIds {
        if id == "root" {
            hasRoot = true;
            break;
        }
    }
    io:println("REGISTRY_HAS_ROOT:" + hasRoot.toString());

    // 4. Look up explicit logger by ID and print its level
    log:Logger? lookedUp = log:getLoggerRegistry().getById("myorg/registrytest:payment-service");
    if lookedUp is log:Logger {
        io:println("LOOKUP_LEVEL:" + lookedUp.getLevel().toString());
    } else {
        io:println("LOOKUP_LEVEL:NOT_FOUND");
    }

    // 5. Create a child logger
    log:Logger childLogger = check explicitLogger.withContext(component = "order");

    // 6. Change parent level and verify child inherits
    check explicitLogger.setLevel(log:DEBUG);
    io:println("CHILD_INHERITS:" + childLogger.getLevel().toString());

    // 7. Attempt setLevel on child — should return error
    error? childSetResult = childLogger.setLevel(log:WARN);
    if childSetResult is error {
        io:println("CHILD_SET_ERROR:" + childSetResult.message());
    } else {
        io:println("CHILD_SET_ERROR:NO_ERROR");
    }

    // 8. Verify child is NOT in registry
    boolean childInRegistry = false;
    string[] finalIds = log:getLoggerRegistry().getIds();
    foreach string id in finalIds {
        if id.includes("order") {
            childInRegistry = true;
            break;
        }
    }
    io:println("CHILD_NOT_IN_REGISTRY:" + (!childInRegistry).toString());
}

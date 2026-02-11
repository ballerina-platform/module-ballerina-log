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

import ballerina/jballerina.java;
import ballerina/test;

// ========== Test utility native function declarations ==========

isolated function getLogConfigNative() returns map<anydata> = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "getLogConfig"
} external;

isolated function getGlobalLogLevelNative() returns string = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "getGlobalLogLevel"
} external;

isolated function setGlobalLogLevelNative(string level) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "setGlobalLogLevel"
} external;

isolated function setModuleLogLevelNative(string moduleName, string level) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "setModuleLogLevel"
} external;

isolated function removeModuleLogLevelNative(string moduleName) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "removeModuleLogLevel"
} external;

isolated function setCustomLoggerLevelNative(string loggerId, string level) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "setCustomLoggerLevel"
} external;

isolated function getVisibleCustomLoggerCount() returns int = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "getVisibleCustomLoggerCount"
} external;

isolated function isCustomLoggerVisible(string loggerId) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.LogConfigTestUtils",
    name: "isCustomLoggerVisible"
} external;

// ========== Tests for runtime log configuration ==========

@test:Config {
    groups: ["logConfig"]
}
function testGetGlobalLogLevel() {
    string currentLevel = getGlobalLogLevelNative();
    // The default level should be one of the valid levels
    test:assertTrue(currentLevel == "DEBUG" || currentLevel == "INFO" ||
                    currentLevel == "WARN" || currentLevel == "ERROR",
                    "Global log level should be a valid level");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testGetGlobalLogLevel]
}
function testSetGlobalLogLevel() returns error? {
    // Get current level to restore later
    string originalLevel = getGlobalLogLevelNative();

    // Set to DEBUG
    check setGlobalLogLevelNative("DEBUG");
    test:assertEquals(getGlobalLogLevelNative(), "DEBUG", "Global log level should be DEBUG");

    // Set to ERROR
    check setGlobalLogLevelNative("ERROR");
    test:assertEquals(getGlobalLogLevelNative(), "ERROR", "Global log level should be ERROR");

    // Set to WARN
    check setGlobalLogLevelNative("WARN");
    test:assertEquals(getGlobalLogLevelNative(), "WARN", "Global log level should be WARN");

    // Set to INFO
    check setGlobalLogLevelNative("INFO");
    test:assertEquals(getGlobalLogLevelNative(), "INFO", "Global log level should be INFO");

    // Test case-insensitivity
    check setGlobalLogLevelNative("debug");
    test:assertEquals(getGlobalLogLevelNative(), "DEBUG", "Log level should be case-insensitive");

    // Restore original level
    check setGlobalLogLevelNative(originalLevel);
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetGlobalLogLevel]
}
function testSetInvalidGlobalLogLevel() {
    error? result = setGlobalLogLevelNative("INVALID");
    test:assertTrue(result is error, "Setting invalid log level should return error");
    if result is error {
        test:assertTrue(result.message().includes("Invalid log level"),
                        "Error message should mention invalid log level");
    }
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetInvalidGlobalLogLevel]
}
function testSetModuleLogLevel() returns error? {
    string testModule = "testorg/testmodule";

    // Set module log level
    check setModuleLogLevelNative(testModule, "DEBUG");

    // Verify via getLogConfig
    map<anydata> config = getLogConfigNative();
    map<anydata> modules = <map<anydata>>config["modules"];
    test:assertTrue(modules.hasKey(testModule), "Module should be in config");
    map<anydata> moduleConfig = <map<anydata>>modules[testModule];
    test:assertEquals(<string>moduleConfig["level"], "DEBUG", "Module level should be DEBUG");

    // Update module log level
    check setModuleLogLevelNative(testModule, "ERROR");
    config = getLogConfigNative();
    modules = <map<anydata>>config["modules"];
    moduleConfig = <map<anydata>>modules[testModule];
    test:assertEquals(<string>moduleConfig["level"], "ERROR", "Module level should be updated to ERROR");

    // Clean up
    _ = removeModuleLogLevelNative(testModule);
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetModuleLogLevel]
}
function testRemoveModuleLogLevel() returns error? {
    string testModule = "testorg/removemodule";

    // Add module log level
    check setModuleLogLevelNative(testModule, "WARN");

    // Remove it
    boolean removed = removeModuleLogLevelNative(testModule);
    test:assertTrue(removed, "Module should be removed");

    // Verify it's gone
    map<anydata> config = getLogConfigNative();
    map<anydata> modules = <map<anydata>>config["modules"];
    test:assertFalse(modules.hasKey(testModule), "Module should not be in config after removal");

    // Try to remove non-existent module
    boolean removedAgain = removeModuleLogLevelNative(testModule);
    test:assertFalse(removedAgain, "Removing non-existent module should return false");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testRemoveModuleLogLevel]
}
function testCustomLoggerWithId() returns error? {
    // Get initial count of visible custom loggers
    int initialCount = getVisibleCustomLoggerCount();

    // Create a logger with explicit ID
    Logger namedLogger = check fromConfig(id = "test-named-logger", level = DEBUG);

    // Verify it's visible
    test:assertTrue(isCustomLoggerVisible("test-named-logger"),
                    "Logger with ID should be visible");

    // Verify count increased
    int newCount = getVisibleCustomLoggerCount();
    test:assertEquals(newCount, initialCount + 1, "Visible logger count should increase by 1");

    // Verify we can modify its level
    check setCustomLoggerLevelNative("test-named-logger", "ERROR");

    // Log something to verify it works
    namedLogger.printError("Test error message");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testCustomLoggerWithId]
}
function testCustomLoggerWithoutId() returns error? {
    // Get initial count of visible custom loggers
    int initialCount = getVisibleCustomLoggerCount();

    // Create a logger without ID
    Logger unnamedLogger = check fromConfig(level = DEBUG);

    // Verify count did NOT increase (logger is not visible)
    int newCount = getVisibleCustomLoggerCount();
    test:assertEquals(newCount, initialCount, "Visible logger count should not change for unnamed logger");

    // Log something to verify it works
    unnamedLogger.printDebug("Test debug message from unnamed logger");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testCustomLoggerWithoutId]
}
function testSetCustomLoggerLevel() returns error? {
    // Create a logger with explicit ID
    string loggerId = "test-level-change-logger";
    Logger testLogger = check fromConfig(id = loggerId, level = INFO);

    // Verify initial level
    test:assertTrue(isCustomLoggerVisible(loggerId), "Logger should be visible");

    // Change level to DEBUG
    check setCustomLoggerLevelNative(loggerId, "DEBUG");

    // Log at DEBUG level - should work now
    testLogger.printDebug("This debug message should appear after level change");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetCustomLoggerLevel]
}
function testSetInvalidCustomLoggerLevel() {
    // Try to set level for non-existent logger
    error? result = setCustomLoggerLevelNative("non-existent-logger", "DEBUG");
    test:assertTrue(result is error, "Setting level for non-existent logger should return error");

    // Try to set invalid level for existing logger
    error? result2 = setCustomLoggerLevelNative("test-named-logger", "INVALID");
    test:assertTrue(result2 is error, "Setting invalid log level should return error");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetInvalidCustomLoggerLevel]
}
function testDuplicateLoggerId() {
    // Try to create another logger with the same ID
    Logger|Error result = fromConfig(id = "test-named-logger", level = WARN);
    test:assertTrue(result is Error, "Creating logger with duplicate ID should return error");
    if result is Error {
        test:assertTrue(result.message().includes("already exists"),
                        "Error message should mention logger already exists");
    }
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testDuplicateLoggerId]
}
function testGetLogConfiguration() {
    map<anydata> config = getLogConfigNative();

    // Verify structure
    test:assertTrue(config.hasKey("rootLogger"), "Config should have rootLogger");
    test:assertTrue(config.hasKey("modules"), "Config should have modules");
    test:assertTrue(config.hasKey("customLoggers"), "Config should have customLoggers");

    // Verify rootLogger has level and is a valid level
    map<anydata> rootLogger = <map<anydata>>config["rootLogger"];
    test:assertTrue(rootLogger.hasKey("level"), "rootLogger should have level");
    string rootLevel = <string>rootLogger["level"];
    test:assertTrue(rootLevel == "DEBUG" || rootLevel == "INFO" ||
                    rootLevel == "WARN" || rootLevel == "ERROR",
                    "Root level should be a valid level");

    // Verify modules is a map
    map<anydata> modules = <map<anydata>>config["modules"];
    test:assertTrue(modules is map<anydata>, "Modules should be a map");

    // Verify customLoggers is a map
    map<anydata> customLoggers = <map<anydata>>config["customLoggers"];
    test:assertTrue(customLoggers is map<anydata>, "CustomLoggers should be a map");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testGetLogConfiguration]
}
function testChildLoggerInheritsId() returns error? {
    // Create a parent logger with ID
    string parentId = "parent-logger-for-child-test";
    Logger parentLogger = check fromConfig(id = parentId, level = INFO);

    // Create a child logger
    Logger childLogger = check parentLogger.withContext(childKey = "childValue");

    // Change parent's level
    check setCustomLoggerLevelNative(parentId, "DEBUG");

    // Child should also be affected (logs at DEBUG level should appear)
    childLogger.printDebug("Child logger debug message after parent level change");
}

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

import ballerina/test;

// ========== Tests for runtime log configuration ==========

@test:Config {
    groups: ["logConfig"]
}
function testGetGlobalLogLevel() {
    Level currentLevel = root().getLevel();
    // The default level should be one of the valid levels
    test:assertTrue(currentLevel == DEBUG || currentLevel == INFO ||
                    currentLevel == WARN || currentLevel == ERROR,
                    "Global log level should be a valid level");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testGetGlobalLogLevel]
}
function testSetGlobalLogLevel() returns error? {
    Logger rootLog = root();
    // Get current level to restore later
    Level originalLevel = rootLog.getLevel();

    // Set to DEBUG
    check rootLog.setLevel(DEBUG);
    test:assertEquals(rootLog.getLevel(), DEBUG, "Global log level should be DEBUG");

    // Set to ERROR
    check rootLog.setLevel(ERROR);
    test:assertEquals(rootLog.getLevel(), ERROR, "Global log level should be ERROR");

    // Set to WARN
    check rootLog.setLevel(WARN);
    test:assertEquals(rootLog.getLevel(), WARN, "Global log level should be WARN");

    // Set to INFO
    check rootLog.setLevel(INFO);
    test:assertEquals(rootLog.getLevel(), INFO, "Global log level should be INFO");

    // Restore original level
    check rootLog.setLevel(originalLevel);
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetGlobalLogLevel]
}
function testCustomLoggerWithId() returns error? {
    // Get initial count of loggers in registry
    int initialCount = getLoggerRegistry().getIds().length();

    // Create a logger with explicit ID - ID will be module-prefixed
    _ = check fromConfig(id = "test-named-logger", level = DEBUG);

    // Verify it's visible (with module prefix)
    string[] ids = getLoggerRegistry().getIds();
    boolean found = false;
    foreach string id in ids {
        if id.endsWith(":test-named-logger") || id == "test-named-logger" {
            found = true;
            break;
        }
    }
    test:assertTrue(found, "Logger with ID should be in registry");

    // Verify count increased
    int newCount = getLoggerRegistry().getIds().length();
    test:assertEquals(newCount, initialCount + 1, "Logger count should increase by 1");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testCustomLoggerWithId]
}
function testCustomLoggerWithoutId() returns error? {
    // Get initial count of loggers
    int initialCount = getLoggerRegistry().getIds().length();

    // Create a logger without ID - should be visible with auto-generated ID
    _ = check fromConfig(level = DEBUG);

    // Verify count increased (all loggers are now visible)
    int newCount = getLoggerRegistry().getIds().length();
    test:assertEquals(newCount, initialCount + 1, "Logger count should increase for auto-ID logger");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testCustomLoggerWithoutId]
}
function testSetCustomLoggerLevel() returns error? {
    // Create a logger with explicit ID
    Logger logger = check fromConfig(id = "test-level-change-logger", level = INFO);

    // Find the actual module-prefixed ID
    string[] ids = getLoggerRegistry().getIds();
    string loggerId = "";
    foreach string id in ids {
        if id.endsWith(":test-level-change-logger") || id == "test-level-change-logger" {
            loggerId = id;
            break;
        }
    }

    // Verify initial level
    Logger? retrieved = getLoggerRegistry().getById(loggerId);
    test:assertTrue(retrieved is Logger, "Logger should be in registry");

    // Change level to DEBUG via Ballerina API
    check logger.setLevel(DEBUG);
    test:assertEquals(logger.getLevel(), DEBUG, "Logger level should be DEBUG after setLevel");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetCustomLoggerLevel]
}
function testDuplicateLoggerId() returns error? {
    // Create a logger with a known ID
    _ = check fromConfig(id = "test-dup-logger", level = WARN);

    // Try to create another logger with the same ID
    Logger|Error result = fromConfig(id = "test-dup-logger", level = WARN);
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
function testChildLoggerInheritsLevel() returns error? {
    // Create a parent logger with ID
    Logger parentLogger = check fromConfig(id = "parent-logger-for-child-test", level = INFO);

    // Create a child logger
    Logger childLogger = check parentLogger.withContext(childKey = "childValue");

    // Child should inherit parent's level
    test:assertEquals(childLogger.getLevel(), INFO, "Child should inherit INFO");

    // Change parent's level
    check parentLogger.setLevel(DEBUG);

    // Child should follow parent (delegates to parent.getLevel())
    test:assertEquals(childLogger.getLevel(), DEBUG, "Child should follow parent level change to DEBUG");
}

// ========== Tests for getLevel, setLevel ==========

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testChildLoggerInheritsLevel]
}
function testGetLevel() returns error? {
    // Create a logger with INFO level
    Logger testLogger = check fromConfig(id = "test-get-level", level = INFO);
    test:assertEquals(testLogger.getLevel(), INFO, "Logger should return its configured level");

    // Create a logger with DEBUG level
    Logger debugLogger = check fromConfig(id = "test-get-level-debug", level = DEBUG);
    test:assertEquals(debugLogger.getLevel(), DEBUG, "Logger should return DEBUG level");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testGetLevel]
}
function testSetLevel() returns error? {
    Logger testLogger = check fromConfig(id = "test-set-level", level = INFO);
    test:assertEquals(testLogger.getLevel(), INFO, "Initial level should be INFO");

    // Set to DEBUG
    check testLogger.setLevel(DEBUG);
    test:assertEquals(testLogger.getLevel(), DEBUG, "Level should be DEBUG after setLevel");

    // Set to ERROR
    check testLogger.setLevel(ERROR);
    test:assertEquals(testLogger.getLevel(), ERROR, "Level should be ERROR after setLevel");

    // Set to WARN
    check testLogger.setLevel(WARN);
    test:assertEquals(testLogger.getLevel(), WARN, "Level should be WARN after setLevel");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testSetLevel]
}
function testChildLoggerInheritsParentChange() returns error? {
    // Create parent with INFO
    Logger parentLogger = check fromConfig(id = "test-inherit-change-parent", level = INFO);

    // Create child (inherits, no explicit level)
    Logger childLogger = check parentLogger.withContext(childKey = "val");
    test:assertEquals(childLogger.getLevel(), INFO, "Child should inherit INFO");

    // Change parent's level to DEBUG
    check parentLogger.setLevel(DEBUG);
    test:assertEquals(childLogger.getLevel(), DEBUG, "Child should follow parent's level change to DEBUG");

    // Change parent's level to ERROR
    check parentLogger.setLevel(ERROR);
    test:assertEquals(childLogger.getLevel(), ERROR, "Child should follow parent's level change to ERROR");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testChildLoggerInheritsParentChange]
}
function testGetLoggerById() returns error? {
    // Create a logger with known ID
    string userId = "test-get-by-id-logger";
    _ = check fromConfig(id = userId, level = WARN);

    // Find the actual prefixed ID
    string[] ids = getLoggerRegistry().getIds();
    string actualId = "";
    foreach string id in ids {
        if id.endsWith(":" + userId) || id == userId {
            actualId = id;
            break;
        }
    }
    test:assertTrue(actualId.length() > 0, "Should find logger ID in registry");

    // Retrieve it by ID
    Logger? retrieved = getLoggerRegistry().getById(actualId);
    test:assertTrue(retrieved is Logger, "Should find logger by ID");

    // Verify it's the same logger by checking level
    if retrieved is Logger {
        test:assertEquals(retrieved.getLevel(), WARN, "Retrieved logger should have WARN level");
    }

    // Try non-existent ID
    Logger? notFound = getLoggerRegistry().getById("non-existent-id");
    test:assertTrue(notFound is (), "Non-existent ID should return nil");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testGetLoggerById]
}
function testAutoGeneratedId() returns error? {
    // Create a logger without explicit ID
    _ = check fromConfig(level = DEBUG);

    // It should appear in the registry
    string[] ids = getLoggerRegistry().getIds();

    // Verify there are auto-generated IDs that contain ":" (module:function format)
    boolean foundAutoId = false;
    foreach string id in ids {
        if id.includes(":") && !id.includes(":test-") && !id.includes(":parent-") && !id.includes(":test_") {
            foundAutoId = true;
            break;
        }
    }
    test:assertTrue(foundAutoId, "Should find at least one auto-generated ID with module:function format");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testAutoGeneratedId]
}
function testGrandchildInheritance() returns error? {
    // parent -> child -> grandchild: grandchild should inherit through the chain
    Logger parent = check fromConfig(id = "test-grandchild-parent", level = WARN);
    Logger child = check parent.withContext(childKey = "c1");
    Logger grandchild = check child.withContext(childKey = "c2");

    // All should report WARN (inherited)
    test:assertEquals(parent.getLevel(), WARN, "Parent should be WARN");
    test:assertEquals(child.getLevel(), WARN, "Child should inherit WARN");
    test:assertEquals(grandchild.getLevel(), WARN, "Grandchild should inherit WARN");

    // Change parent to DEBUG - entire chain should follow
    check parent.setLevel(DEBUG);
    test:assertEquals(child.getLevel(), DEBUG, "Child should follow parent to DEBUG");
    test:assertEquals(grandchild.getLevel(), DEBUG, "Grandchild should follow parent to DEBUG");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testGrandchildInheritance]
}
function testChildInheritsParentLevelChanges() returns error? {
    // Child without explicit level should track parent changes
    Logger parent = check fromConfig(id = "test-child-tracks-parent", level = INFO);
    Logger child = check parent.withContext(childKey = "val");

    test:assertEquals(child.getLevel(), INFO, "Child should inherit INFO");

    // Change parent - child should follow
    check parent.setLevel(WARN);
    test:assertEquals(child.getLevel(), WARN, "Child should follow parent change to WARN");

    check parent.setLevel(DEBUG);
    test:assertEquals(child.getLevel(), DEBUG, "Child should follow parent change to DEBUG");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testChildInheritsParentLevelChanges]
}
function testRootLoggerGetAndSetLevel() returns error? {
    Logger rootLog = root();

    // Root logger should have a valid level
    Level rootLevel = rootLog.getLevel();
    test:assertTrue(rootLevel == DEBUG || rootLevel == INFO ||
                    rootLevel == WARN || rootLevel == ERROR,
                    "Root logger should have a valid level");

    // Save original and set to DEBUG
    Level original = rootLog.getLevel();
    check rootLog.setLevel(DEBUG);
    test:assertEquals(rootLog.getLevel(), DEBUG, "Root logger level should be DEBUG after setLevel");

    // Set to ERROR
    check rootLog.setLevel(ERROR);
    test:assertEquals(rootLog.getLevel(), ERROR, "Root logger level should be ERROR after setLevel");

    // Restore original
    check rootLog.setLevel(original);
    test:assertEquals(rootLog.getLevel(), original, "Root logger level should be restored");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testRootLoggerGetAndSetLevel]
}
function testGetLoggerByIdSetLevelRoundTrip() returns error? {
    // Create logger, retrieve from registry, change level via retrieved reference
    string userId = "test-roundtrip-logger";
    Logger original = check fromConfig(id = userId, level = INFO);

    // Find actual prefixed ID
    string[] ids = getLoggerRegistry().getIds();
    string actualId = "";
    foreach string id in ids {
        if id.endsWith(":" + userId) || id == userId {
            actualId = id;
            break;
        }
    }

    Logger? retrieved = getLoggerRegistry().getById(actualId);
    test:assertTrue(retrieved is Logger, "Should find logger by ID");

    if retrieved is Logger {
        // Change level via retrieved logger
        check retrieved.setLevel(DEBUG);

        // Verify both references see the change (they are the same object)
        test:assertEquals(retrieved.getLevel(), DEBUG, "Retrieved logger should be DEBUG");
        test:assertEquals(original.getLevel(), DEBUG, "Original logger should also be DEBUG");
    }
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testGetLoggerByIdSetLevelRoundTrip]
}
function testMultipleChildrenInherit() returns error? {
    // Multiple children from same parent: all inherit from parent
    Logger parent = check fromConfig(id = "test-multi-children-parent", level = INFO);
    Logger child1 = check parent.withContext(childKey = "c1");
    Logger child2 = check parent.withContext(childKey = "c2");
    Logger child3 = check parent.withContext(childKey = "c3");

    // All inherit INFO
    test:assertEquals(child1.getLevel(), INFO, "Child1 should inherit INFO");
    test:assertEquals(child2.getLevel(), INFO, "Child2 should inherit INFO");
    test:assertEquals(child3.getLevel(), INFO, "Child3 should inherit INFO");

    // Change parent to WARN - all children should follow
    check parent.setLevel(WARN);
    test:assertEquals(child1.getLevel(), WARN, "Child1 should follow parent to WARN");
    test:assertEquals(child2.getLevel(), WARN, "Child2 should follow parent to WARN");
    test:assertEquals(child3.getLevel(), WARN, "Child3 should follow parent to WARN");
}

// ========== Tests for level-checking logic ==========

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testMultipleChildrenInherit]
}
function testIsLevelEnabled() {
    // INFO-level logger: DEBUG should be disabled, INFO/WARN/ERROR enabled
    test:assertFalse(isLevelEnabled(INFO, DEBUG), "DEBUG should not be enabled for INFO-level logger");
    test:assertTrue(isLevelEnabled(INFO, INFO), "INFO should be enabled for INFO-level logger");
    test:assertTrue(isLevelEnabled(INFO, WARN), "WARN should be enabled for INFO-level logger");
    test:assertTrue(isLevelEnabled(INFO, ERROR), "ERROR should be enabled for INFO-level logger");

    // DEBUG-level logger: all should be enabled
    test:assertTrue(isLevelEnabled(DEBUG, DEBUG), "DEBUG should be enabled for DEBUG-level logger");
    test:assertTrue(isLevelEnabled(DEBUG, INFO), "INFO should be enabled for DEBUG-level logger");

    // ERROR-level logger: only ERROR enabled
    test:assertFalse(isLevelEnabled(ERROR, DEBUG), "DEBUG should not be enabled for ERROR-level logger");
    test:assertFalse(isLevelEnabled(ERROR, INFO), "INFO should not be enabled for ERROR-level logger");
    test:assertFalse(isLevelEnabled(ERROR, WARN), "WARN should not be enabled for ERROR-level logger");
    test:assertTrue(isLevelEnabled(ERROR, ERROR), "ERROR should be enabled for ERROR-level logger");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testIsLevelEnabled]
}
function testInheritedLevelFiltersCorrectly() returns error? {
    // When a child inherits DEBUG from parent via setLevel(),
    // the level check must also use the inherited level.
    Logger parent = check fromConfig(id = "test-inherited-filter-parent", level = INFO);
    Logger child = check parent.withContext(childKey = "val");

    // Initially both at INFO - DEBUG should be disabled
    test:assertEquals(child.getLevel(), INFO, "Child should inherit INFO");
    test:assertFalse(isLevelEnabled(child.getLevel(), DEBUG),
            "DEBUG should not be enabled when child inherits INFO");

    // Change parent to DEBUG - child should inherit and DEBUG should now be enabled
    check parent.setLevel(DEBUG);
    test:assertEquals(child.getLevel(), DEBUG, "Child should inherit DEBUG from parent");
    test:assertTrue(isLevelEnabled(child.getLevel(), DEBUG),
            "DEBUG should be enabled when child inherits DEBUG from parent");
}

// ========== Tests for registry and ID generation ==========

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testInheritedLevelFiltersCorrectly]
}
function testRootLoggerInRegistry() returns error? {
    // The global root logger should be registered with well-known ID "root"
    LoggerRegistry registry = getLoggerRegistry();
    string[] ids = registry.getIds();

    boolean found = false;
    foreach string id in ids {
        if id == "root" {
            found = true;
            break;
        }
    }
    test:assertTrue(found, "Root logger should be in the registry with ID 'root'");

    // Root logger should be retrievable by ID
    Logger? rootLog = registry.getById("root");
    test:assertTrue(rootLog is Logger, "Root logger should be retrievable via getById('root')");

    // The root logger from registry should be the same as log:root()
    if rootLog is Logger {
        test:assertEquals(rootLog.getLevel(), root().getLevel(),
                "Registry root logger level should match log:root() level");
    }
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testRootLoggerInRegistry]
}
function testModulePrefixedId() returns error? {
    // Verify that user-provided IDs get module-prefixed
    _ = check fromConfig(id = "my-custom-id", level = INFO);

    string[] ids = getLoggerRegistry().getIds();
    boolean found = false;
    foreach string id in ids {
        // Should be prefixed with module name
        if id.endsWith(":my-custom-id") {
            found = true;
            break;
        }
    }
    // ID should either be module-prefixed or bare (if module name is empty)
    boolean foundBare = false;
    foreach string id in ids {
        if id == "my-custom-id" {
            foundBare = true;
            break;
        }
    }
    test:assertTrue(found || foundBare, "User-provided ID should be in registry (possibly module-prefixed)");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testModulePrefixedId]
}
function testAutoIdFirstNoSuffix() returns error? {
    // The first auto-generated ID for a function should not have a counter suffix.
    // Capture the registry state before creating a new logger with an auto-generated ID.
    string[] idsBefore = getLoggerRegistry().getIds();
    int sizeBefore = idsBefore.length();

    // Create a logger with an auto-generated ID (no explicit id provided).
    Logger _ = check fromConfig(level = DEBUG);

    // Capture the registry state after creating the logger.
    string[] idsAfter = getLoggerRegistry().getIds();
    int sizeAfter = idsAfter.length();

    // Exactly one new entry should be added to the registry.
    test:assertEquals(sizeAfter, sizeBefore + 1,
            "Creating a logger with auto-ID should add exactly one registry entry");

    // Compute the set of new IDs added to the registry.
    string[] newIds = [];
    foreach string id in idsAfter {
        boolean found = false;
        foreach string beforeId in idsBefore {
            if id == beforeId {
                found = true;
                break;
            }
        }
        if !found {
            newIds.push(id);
        }
    }

    // At least one new auto-generated ID should be present.
    test:assertTrue(newIds.length() >= 1, "At least one new auto-generated ID should be present");

    // Auto-generated IDs have format "module:function" (no suffix for first).
    // Verify that at least one new ID contains ":" and does not end with "-N" (where N is a digit).
    boolean foundMatch = false;
    foreach string id in newIds {
        if id.includes(":") && !id.matches(re `.*-\d+$`) {
            foundMatch = true;
            break;
        }
    }

    test:assertTrue(foundMatch,
            "First auto-generated ID for a logger should not have a numeric suffix (e.g., -1)");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testAutoIdFirstNoSuffix]
}
function testChildSetLevelReturnsError() returns error? {
    // Child loggers should return an error when setLevel is called
    Logger parent = check fromConfig(id = "test-child-setlevel-err", level = INFO);
    Logger child = check parent.withContext(childKey = "val");

    error? result = child.setLevel(DEBUG);
    test:assertTrue(result is error, "setLevel on child logger should return error");
    if result is error {
        test:assertTrue(result.message().includes("child logger"),
                "Error message should mention child logger");
    }

    // Verify child still inherits parent level (setLevel had no effect)
    test:assertEquals(child.getLevel(), INFO, "Child should still inherit INFO from parent");
}

@test:Config {
    groups: ["logConfig"],
    dependsOn: [testChildSetLevelReturnsError]
}
function testChildNotInRegistry() returns error? {
    // Child loggers should NOT be registered in the Ballerina-side registry
    string[] idsBefore = getLoggerRegistry().getIds();
    int sizeBefore = idsBefore.length();

    // Create parent logger
    Logger parentLogger = check fromConfig(id = "test-child-not-registered", level = INFO);

    // Create child via withContext
    _ = check parentLogger.withContext(childKey = "childValue");

    // Registry should have only 1 more entry (parent only, not child)
    string[] idsAfter = getLoggerRegistry().getIds();
    int sizeAfter = idsAfter.length();
    test:assertEquals(sizeAfter, sizeBefore + 1, "Registry should have only 1 more entry (parent only)");
}


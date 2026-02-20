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

import ballerina/io;
import ballerina/test;
import ballerina/lang.runtime;
import ballerina/jballerina.java;

const string ROTATION_TEST_DIR = "tests/resources/rotation/";

// Native file operation functions to avoid cyclic dependency with ballerina/file module
isolated function fileExists(string path) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.TestFileUtils"
} external;

isolated function isDirectory(string path) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.TestFileUtils"
} external;

isolated function listFilesJson(string path) returns string|error = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.TestFileUtils"
} external;

isolated function removeFile(string path, boolean recursive) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.TestFileUtils"
} external;

isolated function createDirectory(string path) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.log.testutils.nativeimpl.TestFileUtils"
} external;

// File metadata record
type FileInfo record {|
    string absPath;
    string name;
    boolean isDir;
    int size;
|};

// Wrapper function to parse JSON and return FileInfo array
isolated function listFiles(string path) returns FileInfo[]|error {
    string jsonStr = check listFilesJson(path);
    return jsonStr.fromJsonStringWithType();
}

@test:BeforeSuite
function setupRotationTests() returns error? {
    // Create test directory
    check createDirectory(ROTATION_TEST_DIR);
    check io:fileWriteString(ROTATION_TEST_DIR + "test.log", "");
}

@test:AfterSuite
function cleanupRotationTests() returns error? {
    // Clean up test files
    if fileExists(ROTATION_TEST_DIR) {
        check removeFile(ROTATION_TEST_DIR, true);
    }
}

// Test size-based rotation
@test:Config {}
function testSizeBasedRotation() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "size_rotation_test.log";
    
    // Configure logger with size-based rotation
    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024, // 1KB for testing
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Write logs to exceed file size
    foreach int i in 0...100 {
        logger.printInfo(string `This is a test log message number ${i} with some extra content to fill the file`);
    }

    // Give some time for rotation to happen
    runtime:sleep(1);

    // Check that rotation happened - backup files should exist
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("size_rotation_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertTrue(backupCount > 0, "Size-based rotation should create backup files");
    test:assertTrue(backupCount <= 3, "Should not exceed max backup files");
}

// Test time-based rotation
@test:Config {}
function testTimeBasedRotation() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "time_rotation_test.log";
    
    // Configure logger with time-based rotation (2 seconds for testing)
    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: TIME_BASED,
                    maxAge: 2, // 2 seconds
                    maxBackupFiles: 5
                }
            }
        ]
    );

    // Write initial logs
    logger.printInfo("Log before rotation");
    
    // Wait for rotation time
    runtime:sleep(3);
    
    // Write more logs to trigger rotation check
    logger.printInfo("Log after rotation period");

    // Check that rotation happened
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    boolean rotatedFileExists = false;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("time_rotation_test-") && fileInfo.absPath.endsWith(".log") {
            rotatedFileExists = true;
            break;
        }
    }

    test:assertTrue(rotatedFileExists, "Time-based rotation should create backup files");
}

// Test combined (BOTH) rotation policy
@test:Config {}
function testCombinedRotation() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "combined_rotation_test.log";
    
    // Configure logger with both size and time-based rotation
    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: BOTH,
                    maxFileSize: 2048, // 2KB
                    maxAge: 5, // 5 seconds
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Write logs to trigger size-based rotation first
    foreach int i in 0...150 {
        logger.printInfo(string `Combined rotation test log message ${i} with additional content`);
    }

    // Check that rotation happened due to size
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    boolean rotatedFileExists = false;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("combined_rotation_test-") && fileInfo.absPath.endsWith(".log") {
            rotatedFileExists = true;
            break;
        }
    }

    test:assertTrue(rotatedFileExists, "Combined rotation should create backup files when size limit is reached");
}

// Test backup file cleanup
@test:Config {}
function testBackupFileCleanup() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "cleanup_test.log";
    
    // Configure logger with max 2 backup files
    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 512, // Very small for quick rotation
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write logs to trigger multiple rotations
    foreach int i in 0...200 {
        logger.printInfo(string `Cleanup test log message ${i} with sufficient content for rotation`);
        if i % 50 == 0 {
            runtime:sleep(0.5); // Small delay to ensure rotations happen
        }
    }

    runtime:sleep(1);

    // Count backup files
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("cleanup_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertTrue(backupCount <= 2, string `Should keep at most 2 backup files, found ${backupCount}`);
}

// Test no rotation when policy is NONE
@test:Config {}
function testNoRotation() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "no_rotation_test.log";

    // Configure logger without rotation (no rotation config provided)
    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE
            }
        ]
    );

    // Write many logs
    foreach int i in 0...100 {
        logger.printInfo(string `No rotation test log message ${i}`);
    }

    runtime:sleep(1);

    // Check that no backup files were created
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("no_rotation_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertEquals(backupCount, 0, "No rotation should not create backup files");
}

// Test rotation with multiple log levels
@test:Config {}
function testRotationWithMultipleLevels() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "multilevel_rotation_test.log";
    
    Logger logger = check fromConfig(
        level = DEBUG,
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write logs at different levels
    foreach int i in 0...50 {
        logger.printDebug(string `Debug message ${i}`);
        logger.printInfo(string `Info message ${i}`);
        logger.printWarn(string `Warn message ${i}`);
        logger.printError(string `Error message ${i}`);
    }

    runtime:sleep(1);

    // Verify rotation occurred
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    boolean hasBackup = false;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("multilevel_rotation_test-") {
            hasBackup = true;
            break;
        }
    }

    test:assertTrue(hasBackup, "Rotation should work with multiple log levels");
}

// Test default rotation configuration
@test:Config {}
function testDefaultRotationConfig() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "default_rotation_test.log";
    
    // Configure logger with default rotation values
    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED
                    // Using default maxFileSize (10MB) and maxBackupFiles (10)
                }
            }
        ]
    );

    // Write some logs
    foreach int i in 0...10 {
        logger.printInfo(string `Default config test message ${i}`);
    }

    // File should exist and be writable
    test:assertTrue(fileExists(logFilePath), "Log file should exist");
}

// Test rotation with error logging
@test:Config {}
function testRotationWithErrors() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "error_rotation_test.log";
    
    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 800,
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Write logs with errors
    foreach int i in 0...50 {
        error sampleError = error(string `Sample error ${i}`);
        logger.printError(string `Error log ${i}`, 'error = sampleError);
    }

    runtime:sleep(1);

    // Verify logs were written and rotation occurred if needed
    test:assertTrue(fileExists(logFilePath), "Log file should exist");
}

// Test rotation with maxBackupFiles = 0 (no backups kept)
@test:Config {}
function testRotationWithZeroBackups() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "zero_backup_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 512,
                    maxBackupFiles: 0
                }
            }
        ]
    );

    // Write logs to trigger multiple rotations
    foreach int i in 0...80 {
        logger.printInfo(string `Zero backup test log message ${i} with content`);
    }

    runtime:sleep(1);

    // Check that no backup files exist
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("zero_backup_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertEquals(backupCount, 0, "Should not keep any backup files when maxBackupFiles is 0");
    test:assertTrue(fileExists(logFilePath), "Main log file should still exist");
}

// Test rotation with maxBackupFiles = 1
@test:Config {}
function testRotationWithOneBackup() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "one_backup_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 512,
                    maxBackupFiles: 1
                }
            }
        ]
    );

    // Write logs to trigger multiple rotations
    foreach int i in 0...100 {
        logger.printInfo(string `One backup test log message ${i} with extra content for rotation`);
    }

    runtime:sleep(1);

    // Check that only one backup file exists
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("one_backup_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertTrue(backupCount <= 1, string `Should keep at most 1 backup file, found ${backupCount}`);
}

// Test very small file size causing immediate rotation
@test:Config {}
function testImmediateRotation() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "immediate_rotation_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 200, // Very small size
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Each log will likely trigger rotation
    logger.printInfo("First log message with some content");
    runtime:sleep(0.1);
    logger.printInfo("Second log message with some content");
    runtime:sleep(0.1);
    logger.printInfo("Third log message with some content");

    runtime:sleep(1);

    // Verify rotation occurred
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("immediate_rotation_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertTrue(backupCount > 0, "Should have created backup files with very small maxFileSize");
}

// Test rotation with APPEND mode
@test:Config {}
function testRotationWithAppendMode() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "append_rotation_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: APPEND,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write initial logs
    foreach int i in 0...50 {
        logger.printInfo(string `Append mode rotation test ${i}`);
    }

    runtime:sleep(1);

    // Verify file exists and rotation may have occurred
    test:assertTrue(fileExists(logFilePath), "Log file should exist with APPEND mode");
}

// Test rotation with all log levels
@test:Config {}
function testRotationWithAllLogLevels() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "all_levels_rotation_test.log";

    Logger logger = check fromConfig(
        level = DEBUG,
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 800,
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write logs at all levels
    foreach int i in 0...30 {
        logger.printDebug(string `Debug message ${i}`);
        logger.printInfo(string `Info message ${i}`);
        logger.printWarn(string `Warn message ${i}`);
        error err = error("Test error");
        logger.printError(string `Error message ${i}`, 'error = err);
    }

    runtime:sleep(1);

    test:assertTrue(fileExists(logFilePath), "Log file should exist");
}

// Test rotation with JSON format
@test:Config {}
function testRotationWithJsonFormat() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "json_rotation_test.log";

    Logger logger = check fromConfig(
        format = JSON_FORMAT,
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Write logs in JSON format
    foreach int i in 0...60 {
        logger.printInfo("JSON format log", requestId = i, status = "success");
    }

    runtime:sleep(1);

    test:assertTrue(fileExists(logFilePath), "JSON log file should exist");

    // Verify backup files were created
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("json_rotation_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertTrue(backupCount > 0, "Should have created backup files");
}

// Test rotation with context logger
@test:Config {}
function testRotationWithContextLogger() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "context_rotation_test.log";

    Logger baseLogger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Create context loggers
    Logger contextLogger1 = check baseLogger.withContext(component = "auth", version = "1.0");
    Logger contextLogger2 = check baseLogger.withContext(component = "api", version = "2.0");

    // Write logs from different context loggers
    foreach int i in 0...40 {
        contextLogger1.printInfo(string `Auth service log ${i}`);
        contextLogger2.printInfo(string `API service log ${i}`);
    }

    runtime:sleep(1);

    test:assertTrue(fileExists(logFilePath), "Context logger log file should exist");
}

// Test that rotation properly handles rapid successive writes
@test:Config {}
function testRapidSuccessiveWrites() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "rapid_writes_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 600,
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Rapid successive writes without delays
    foreach int i in 0...150 {
        logger.printInfo(string `Rapid write ${i} with content to fill the log file`);
    }

    runtime:sleep(1);

    // Verify rotation handled rapid writes correctly
    test:assertTrue(fileExists(logFilePath), "Log file should exist after rapid writes");

    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("rapid_writes_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertTrue(backupCount <= 3, string `Should keep at most 3 backups, found ${backupCount}`);
}

// Test time-based rotation with very short interval
@test:Config {}
function testShortTimeInterval() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "short_interval_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: TIME_BASED,
                    maxAge: 1, // 1 second
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write initial log
    logger.printInfo("Initial log entry");

    // Wait for rotation time
    runtime:sleep(1.5);

    // Write another log to trigger rotation check
    logger.printInfo("Log after rotation time");

    runtime:sleep(0.5);

    // Verify rotation occurred
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    boolean rotatedFileExists = false;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("short_interval_test-") && fileInfo.absPath.endsWith(".log") {
            rotatedFileExists = true;
            break;
        }
    }

    test:assertTrue(rotatedFileExists, "Time-based rotation should have created backup file");
}

// Test that backup files are properly timestamped
@test:Config {}
function testBackupTimestamps() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "timestamp_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 400,
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Trigger first rotation
    foreach int i in 0...30 {
        logger.printInfo(string `First batch ${i} with content`);
    }

    runtime:sleep(1);

    // Trigger second rotation
    foreach int i in 0...30 {
        logger.printInfo(string `Second batch ${i} with content`);
    }

    runtime:sleep(1);

    // Check that backup files have timestamp format in their names
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("timestamp_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
            // Backup file should have format: timestamp_test-yyyyMMdd-HHmmss.log
            string fileName = fileInfo.name;
            test:assertTrue(fileName.startsWith("timestamp_test-"), "Backup file should have correct prefix");
            test:assertTrue(fileName.length() > 30, "Backup file should have timestamp in name");
        }
    }

    test:assertTrue(backupCount > 0, "Should have created timestamped backup files");
}

// Test rotation with masked sensitive data
@test:Config {}
function testRotationWithMasking() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "masked_rotation_test.log";

    Logger logger = check fromConfig(
        enableSensitiveDataMasking = true,
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write logs with sensitive data
    foreach int i in 0...50 {
        logger.printInfo("Processing user data", userId = i, password = "secret123");
    }

    runtime:sleep(1);

    test:assertTrue(fileExists(logFilePath), "Masked log file should exist");
}

// Test BOTH rotation policy triggering on size first
@test:Config {}
function testBothPolicySizeFirst() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "both_size_first_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: BOTH,
                    maxFileSize: 800,
                    maxAge: 10, // 10 seconds (longer than test)
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write enough logs to trigger size-based rotation before time
    foreach int i in 0...80 {
        logger.printInfo(string `BOTH policy size trigger test ${i}`);
    }

    runtime:sleep(1);

    // Verify rotation occurred due to size
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    boolean rotatedFileExists = false;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("both_size_first_test-") && fileInfo.absPath.endsWith(".log") {
            rotatedFileExists = true;
            break;
        }
    }

    test:assertTrue(rotatedFileExists, "BOTH policy should rotate on size trigger");
}

// Test BOTH rotation policy triggering on time first
@test:Config {}
function testBothPolicyTimeFirst() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "both_time_first_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: BOTH,
                    maxFileSize: 100000, // Very large (won't trigger)
                    maxAge: 2, // 2 seconds
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Write few logs
    logger.printInfo("Initial log");

    // Wait for time trigger
    runtime:sleep(2);

    // Write another log to trigger rotation check
    logger.printInfo("Log after time trigger");

    runtime:sleep(0.5);

    // Verify rotation occurred due to time
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    boolean rotatedFileExists = false;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("both_time_first_test-") && fileInfo.absPath.endsWith(".log") {
            rotatedFileExists = true;
            break;
        }
    }

    test:assertTrue(rotatedFileExists, "BOTH policy should rotate on time trigger");
}

// Test rotation with key-value pairs
@test:Config {}
function testRotationWithKeyValues() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "keyvalues_rotation_test.log";

    Logger logger = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 2
                }
            }
        ],
        keyValues = {
            "environment": "test",
            "application": "rotation-test"
        }
    );

    // Write logs with additional key-value pairs
    foreach int i in 0...50 {
        logger.printInfo("Log with context", requestId = string `req-${i}`, status = "success");
    }

    runtime:sleep(1);

    test:assertTrue(fileExists(logFilePath), "Log file with key-values should exist");
}

// Test empty log file doesn't trigger rotation
@test:Config {}
function testEmptyFileNoRotation() returns error? {
    string logFilePath = ROTATION_TEST_DIR + "empty_file_test.log";

    _ = check fromConfig(
        destinations = [
            {
                'type: FILE,
                path: logFilePath,
                mode: TRUNCATE,
                rotation: {
                    policy: SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Create the logger but don't write anything
    runtime:sleep(1);

    // Verify no rotation occurred
    FileInfo[] files = check listFiles(ROTATION_TEST_DIR);
    int backupCount = 0;
    foreach FileInfo fileInfo in files {
        if fileInfo.absPath.includes("empty_file_test-") && fileInfo.absPath.endsWith(".log") {
            backupCount += 1;
        }
    }

    test:assertEquals(backupCount, 0, "Empty file should not trigger rotation");
}

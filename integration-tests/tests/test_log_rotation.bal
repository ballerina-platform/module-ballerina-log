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

import ballerina/data.jsondata;
import ballerina/io;
import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/test;

const string INTEGRATION_TEST_DIR = "tests/resources/integration-rotation/";

// Native file operation functions to avoid cyclic dependency with ballerina/file module
isolated function fileExists(string path) returns boolean = @java:Method {
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
    return jsondata:parseString(jsonStr);
}

@test:BeforeSuite
function setupIntegrationTests() returns error? {
    // Ensure test directory exists
    if !fileExists(INTEGRATION_TEST_DIR) {
        check createDirectory(INTEGRATION_TEST_DIR);
    }
}

@test:AfterSuite
function cleanupIntegrationTests() returns error? {
    // Clean up test files
    if fileExists(INTEGRATION_TEST_DIR) {
        check removeFile(INTEGRATION_TEST_DIR, true);
    }
}

// Integration test for size-based rotation in real-world scenario
@test:Config {}
function integrationTestSizeRotation() returns error? {
    string logFile = INTEGRATION_TEST_DIR + "app.log";
    
    log:Logger appLogger = check log:fromConfig(
        format = log:JSON_FORMAT,
        level = log:INFO,
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 2048, // 2KB
                    maxBackupFiles: 5
                }
            }
        ]
    );

    // Simulate application logging
    foreach int i in 0...100 {
        appLogger.printInfo("Processing transaction", transactionId = i, amount = 100.50 * i, status = "completed");
        if i % 10 == 0 {
            appLogger.printWarn("High transaction volume detected", count = i);
        }
    }

    runtime:sleep(1);

    // Verify log rotation occurred
    FileInfo[] files = check listFiles(INTEGRATION_TEST_DIR);
    int totalLogFiles = 0;
    foreach FileInfo f in files {
        // Only count files related to this test (app.log and app-*.log)
        if f.name == "app.log" || (f.name.startsWith("app-") && f.name.endsWith(".log")) {
            totalLogFiles += 1;
        }
    }

    test:assertTrue(totalLogFiles > 1, "Should have created backup log files");
    test:assertTrue(totalLogFiles <= 6, "Should have main log + max 5 backups"); // 1 main + 5 backups max
}

// Integration test for time-based rotation
@test:Config {}
function integrationTestTimeRotation() returns error? {
    string logFile = INTEGRATION_TEST_DIR + "scheduled.log";
    
    log:Logger scheduledLogger = check log:fromConfig(
        format = log:LOGFMT,
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:TIME_BASED,
                    maxAge: 3, // 3 seconds
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Simulate periodic logging
    scheduledLogger.printInfo("Scheduled task started");
    runtime:sleep(1);
    scheduledLogger.printInfo("Scheduled task running");
    runtime:sleep(2.5);
    scheduledLogger.printInfo("Scheduled task completed");

    runtime:sleep(1);

    // Verify rotation occurred
    FileInfo[] files = check listFiles(INTEGRATION_TEST_DIR);
    boolean hasRotatedFile = false;
    foreach FileInfo f in files {
        if f.absPath.includes("scheduled-") && f.absPath.endsWith(".log") {
            hasRotatedFile = true;
            break;
        }
    }

    test:assertTrue(hasRotatedFile, "Time-based rotation should create backup files");
}

// Integration test with mixed destinations (stderr + file with rotation)
@test:Config {}
function integrationTestMixedDestinations() returns error? {
    string logFile = INTEGRATION_TEST_DIR + "mixed.log";
    
    log:Logger mixedLogger = check log:fromConfig(
        destinations = [
            {'type: log:STDERR},
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 1024,
                    maxBackupFiles: 2
                }
            }
        ]
    );

    // Log to both destinations
    foreach int i in 0...80 {
        mixedLogger.printInfo(string `Mixed destination log entry ${i}`);
    }

    runtime:sleep(1);

    // Verify file exists and rotation may have occurred
    test:assertTrue(fileExists(logFile), "Log file should exist");
}

// Integration test for production-like scenario with all log levels
@test:Config {}
function integrationTestProductionScenario() returns error? {
    string logFile = INTEGRATION_TEST_DIR + "production.log";
    
    log:Logger prodLogger = check log:fromConfig(
        format = log:JSON_FORMAT,
        level = log:DEBUG,
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:BOTH,
                    maxFileSize: 3072, // 3KB
                    maxAge: 10, // 10 seconds
                    maxBackupFiles: 10
                }
            }
        ],
        keyValues = {
            "service": "user-service",
            "version": "1.0.0"
        }
    );

    // Simulate production logging patterns
    prodLogger.printInfo("Application started", environment = "production");
    
    foreach int i in 0...60 {
        prodLogger.printDebug("Processing request", requestId = i);
        prodLogger.printInfo("Request processed successfully", requestId = i, duration = 123 + i);
        
        if i % 20 == 0 {
            prodLogger.printWarn("Resource usage high", cpu = 85.5, memory = 78.2);
        }
        
        if i % 30 == 0 {
            error err = error("Database connection timeout");
            prodLogger.printError("Request failed", 'error = err, requestId = i);
        }
    }

    prodLogger.printInfo("Application shutting down");
    
    runtime:sleep(1);

    // Verify logging worked
    test:assertTrue(fileExists(logFile), "Production log file should exist");

    // Read and verify log content
    string content = check io:fileReadString(logFile);
    test:assertTrue(content.length() > 0, "Log file should have content");
}

// Integration test for rotation with context logger
@test:Config {}
function integrationTestContextLoggerRotation() returns error? {
    string logFile = INTEGRATION_TEST_DIR + "context.log";
    
    log:Logger baseLogger = check log:fromConfig(
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 1536,
                    maxBackupFiles: 3
                }
            }
        ]
    );

    // Create context loggers
    log:Logger userLogger = check baseLogger.withContext(component = "user-handler");
    log:Logger orderLogger = check baseLogger.withContext(component = "order-handler");

    // Log from different contexts
    foreach int i in 0...50 {
        userLogger.printInfo("User operation", userId = i, operation = "login");
        orderLogger.printInfo("Order operation", orderId = i, operation = "create");
    }

    runtime:sleep(1);

    // Verify rotation works with context loggers
    test:assertTrue(fileExists(logFile), "Context logger log file should exist");
}

// Integration test for concurrent logging with rotation
@test:Config {}
function integrationTestConcurrentLogging() returns error? {
    string logFile = INTEGRATION_TEST_DIR + "concurrent.log";
    
    log:Logger concurrentLogger = check log:fromConfig(
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 2048,
                    maxBackupFiles: 4
                }
            }
        ]
    );

    // Simulate concurrent logging from different parts of application
    worker w1 {
        foreach int i in 0...40 {
            concurrentLogger.printInfo("Worker 1 log", workerId = 1, iteration = i);
        }
    }

    worker w2 {
        foreach int i in 0...40 {
            concurrentLogger.printInfo("Worker 2 log", workerId = 2, iteration = i);
        }
    }

    worker w3 {
        foreach int i in 0...40 {
            concurrentLogger.printInfo("Worker 3 log", workerId = 3, iteration = i);
        }
    }

    _ = wait {w1, w2, w3};
    runtime:sleep(1);

    // Verify concurrent logging doesn't cause issues
    test:assertTrue(fileExists(logFile), "Concurrent log file should exist");
}

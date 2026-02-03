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
import ballerina/log;
import ballerina/test;
import ballerina/time;

const int PERF_ITERATIONS = 10000;
const int PERF_RUNS = 3; // Number of times to run each test for averaging
const string PERF_TEST_DIR = "tests/resources/perf/";

@test:BeforeSuite
function setupPerfTests() returns error? {
    if !fileExists(PERF_TEST_DIR) {
        check createDirectory(PERF_TEST_DIR);
    }
}

@test:AfterSuite
function cleanupPerfTests() returns error? {
    if fileExists(PERF_TEST_DIR) {
        check removeFile(PERF_TEST_DIR, true);
    }
}

@test:Config {}
function performanceComparisonTest() returns error? {
    io:println("\n=== Log Performance Comparison ===");
    io:println(string `Iterations per test: ${PERF_ITERATIONS}, Runs: ${PERF_RUNS}\n`);

    // Warmup run to eliminate JVM startup overhead
    io:println("Running warmup...");
    _ = check testWithoutRotation();

    // Test 1: Logging without rotation (baseline) - run multiple times and average
    io:println("\nTest 1: Logging WITHOUT rotation (baseline)");
    decimal noRotationTotal = 0.0d;
    foreach int i in 0 ..< PERF_RUNS {
        decimal time = check testWithoutRotation();
        noRotationTotal += time;
    }
    decimal noRotationTime = noRotationTotal / <decimal>PERF_RUNS;
    io:println(string `Average time: ${noRotationTime}ms`);
    io:println(string `Throughput: ${<decimal>PERF_ITERATIONS / (noRotationTime / 1000.0d)} logs/second`);

    // Test 3: Logging with rotation triggered - run multiple times and average
    io:println("\nTest 2: Logging WITH rotation (rotation triggered)");
    decimal rotationTriggeredTotal = 0.0d;
    foreach int i in 0 ..< PERF_RUNS {
        decimal time = check testWithRotationTriggered();
        rotationTriggeredTotal += time;
    }
    decimal rotationTriggeredTime = rotationTriggeredTotal / <decimal>PERF_RUNS;
    io:println(string `Average time: ${rotationTriggeredTime}ms`);
    io:println(string `Throughput: ${<decimal>PERF_ITERATIONS / (rotationTriggeredTime / 1000.0d)} logs/second`);

    // Calculate overhead
    decimal rotationOverhead = ((rotationTriggeredTime - noRotationTime) / noRotationTime) * 100.0d;

    io:println("\n=== Performance Summary ===");
    io:println(string `Baseline (no rotation): ${noRotationTime}ms`);
    io:println(string `With rotation triggered: ${rotationTriggeredTime}ms`);
    io:println(string `Overhead when rotation triggers: ${rotationOverhead}%`);

    // Performance assertions - overhead should be reasonable
    // Note: When rotation is actively triggered (file renaming, creation), ~100% overhead is expected
    test:assertTrue(rotationOverhead < 150.0d, string `Rotation trigger overhead too high: ${rotationOverhead}%`);
}

function testWithoutRotation() returns decimal|error {
    string logFile = PERF_TEST_DIR + "perf_no_rotation.log";

    // Clean up
    if fileExists(logFile) {
        _ = check removeFile(logFile, false);
    }

    // Create logger without rotation
    log:Logger logger = check log:fromConfig(
        format = log:LOGFMT,
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE
            }
        ]
    );

    time:Utc startTime = time:utcNow();

    // Log messages
    foreach int i in 0 ..< PERF_ITERATIONS {
        logger.printInfo("Performance test message", iteration = i, value = i * 2);
    }

    time:Utc endTime = time:utcNow();
    decimal duration = <decimal>(endTime[0] - startTime[0]) * 1000.0d +
                       <decimal>(endTime[1] - startTime[1]) / 1000000.0d;

    return duration;
}

function testWithRotation() returns decimal|error {
    string logFile = PERF_TEST_DIR + "perf_with_rotation.log";

    // Clean up
    if fileExists(logFile) {
        _ = check removeFile(logFile, false);
    }

    // Create logger with rotation configured (large file size to avoid rotation)
    log:Logger logger = check log:fromConfig(
        format = log:LOGFMT,
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 100000000, // 100MB - won't be triggered
                    maxBackupFiles: 5
                }
            }
        ]
    );

    time:Utc startTime = time:utcNow();

    // Log messages
    foreach int i in 0 ..< PERF_ITERATIONS {
        logger.printInfo("Performance test message", iteration = i, value = i * 2);
    }

    time:Utc endTime = time:utcNow();
    decimal duration = <decimal>(endTime[0] - startTime[0]) * 1000.0d +
                       <decimal>(endTime[1] - startTime[1]) / 1000000.0d;

    return duration;
}

function testWithRotationTriggered() returns decimal|error {
    string logFile = PERF_TEST_DIR + "perf_rotation_triggered.log";

    // Clean up existing files
    if fileExists(logFile) {
        _ = check removeFile(logFile, false);
    }

    if fileExists(PERF_TEST_DIR) {
        FileInfo[] files = check listFiles(PERF_TEST_DIR);
        foreach FileInfo f in files {
            if f.name.startsWith("perf_rotation_triggered-") {
                _ = check removeFile(f.absPath, false);
            }
        }
    }

    // Create logger with rotation configured (small file size to trigger rotation)
    log:Logger logger = check log:fromConfig(
        format = log:LOGFMT,
        destinations = [
            {
                'type: log:FILE,
                path: logFile,
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 10240, // 10KB - will be triggered multiple times
                    maxBackupFiles: 5
                }
            }
        ]
    );

    time:Utc startTime = time:utcNow();

    // Log messages
    foreach int i in 0 ..< PERF_ITERATIONS {
        logger.printInfo("Performance test message", iteration = i, value = i * 2);
    }

    time:Utc endTime = time:utcNow();

    // Calculate duration more carefully
    int secondsDiff = endTime[0] - startTime[0];
    decimal nanosDiff = <decimal>(endTime[1] - startTime[1]);
    decimal duration = <decimal>secondsDiff * 1000.0d + nanosDiff / 1000000.0d;

    // Count how many rotated files were created
    int rotatedCount = 0;
    if fileExists(PERF_TEST_DIR) {
        FileInfo[] files = check listFiles(PERF_TEST_DIR);
        foreach FileInfo f in files {
            if f.name.startsWith("perf_rotation_triggered-") {
                rotatedCount += 1;
            }
        }
    }
    io:println(string `Rotations triggered: ${rotatedCount}`);

    return duration;
}

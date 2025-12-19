// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org).
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
import ballerina/lang.runtime;

// Example demonstrating log rotation features
public function main() returns error? {
    // Example 1: Size-based rotation
    log:Logger sizeLogger = check log:fromConfig(
        destinations = [
            {
                'type: log:FILE,
                path: "./logs/size-based.log",
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 1024, // 1KB for quick demo
                    maxBackupFiles: 3
                }
            }
        ]
    );

    log:printInfo("Size-based rotation demo started");
    
    // Generate logs to trigger size-based rotation
    foreach int i in 0...50 {
        sizeLogger.printInfo("Processing transaction", 
            transactionId = i, 
            amount = 100.50 * i, 
            status = "completed",
            timestamp = runtime:currentTimeMillis()
        );
    }

    log:printInfo("Size-based rotation demo completed - check ./logs/ for rotated files");

    // Example 2: Time-based rotation
    log:Logger timeLogger = check log:fromConfig(
        format: log:JSON_FORMAT,
        destinations = [
            {
                'type: log:FILE,
                path: "./logs/time-based.log",
                mode: log:TRUNCATE,
                rotation: {
                    policy: log:TIME_BASED,
                    maxAge: 5, // 5 seconds for demo
                    maxBackupFiles: 2
                }
            }
        ]
    );

    log:printInfo("Time-based rotation demo started");
    timeLogger.printInfo("First batch of logs");
    
    runtime:sleep(3);
    timeLogger.printInfo("Second batch of logs");
    
    runtime:sleep(3);
    timeLogger.printInfo("Third batch of logs - rotation should have occurred");

    log:printInfo("Time-based rotation demo completed");

    // Example 3: Combined rotation (production-ready)
    log:Logger prodLogger = check log:fromConfig(
        format: log:JSON_FORMAT,
        level: log:INFO,
        destinations = [
            {'type: log:STDERR}, // Also log to console
            {
                'type: log:FILE,
                path: "./logs/production.log",
                mode: log:APPEND,
                rotation: {
                    policy: log:BOTH,
                    maxFileSize: 2048, // 2KB for demo (use 50-100MB in production)
                    maxAge: 10, // 10 seconds (use 86400 seconds = 24 hours in production)
                    maxBackupFiles: 5
                }
            }
        ],
        keyValues: {
            service: "demo-service",
            version: "1.0.0",
            environment: "development"
        }
    );

    log:printInfo("Production-style rotation demo started");
    
    // Simulate various application activities
    foreach int i in 0...30 {
        if i % 10 == 0 {
            prodLogger.printInfo("Health check passed", 
                checkId = i, 
                responseTime = 50 + i
            );
        } else if i % 7 == 0 {
            prodLogger.printWarn("High memory usage detected", 
                memoryPercent = 85.5, 
                iteration = i
            );
        } else if i % 15 == 0 {
            error sampleError = error("Temporary network glitch");
            prodLogger.printError("Request failed but will retry", 
                'error = sampleError, 
                attempt = i
            );
        } else {
            prodLogger.printInfo("Processing request", 
                requestId = i, 
                endpoint = "/api/data"
            );
        }
    }

    log:printInfo("Production-style rotation demo completed");
    log:printInfo("Check the ./logs/ directory for main and rotated backup files");
    log:printInfo("Backup files are named with timestamps (e.g., production-20251209-143022.log)");
}

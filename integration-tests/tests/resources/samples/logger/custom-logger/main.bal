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
import ballerina/time;

public type LogConfig record {|
    string filePath;
    log:Level level = log:INFO;
    readonly & log:AnydataKeyValues keyValues = {};
|};

final readonly & map<int> logLevelWeight = {
    [log:ERROR]: 1000,
    [log:WARN]: 900,
    [log:INFO]: 800,
    [log:DEBUG]: 700
};

isolated class CustomLogger {
    *log:Logger;

    private final log:Level level;
    private final string filePath;
    private final readonly & log:AnydataKeyValues keyValues;

    public isolated function init(*LogConfig config) returns error? {
        if !config.filePath.endsWith(".log") {
            return error("File path must end with .log");
        }
        self.filePath = config.filePath;
        self.level = config.level;
        self.keyValues = config.keyValues;
    }

    isolated function isLogLevelEnabled(log:Level level) returns boolean {
        return logLevelWeight[level] >= logLevelWeight[self.level];
    }

    public isolated function printDebug(string|log:PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *log:KeyValues keyValues) {
        self.print(log:DEBUG, msg, 'error, stackTrace, keyValues);
    }

    public isolated function printError(string|log:PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *log:KeyValues keyValues) {
        self.print(log:ERROR, msg, 'error, stackTrace, keyValues);
    }

    public isolated function printInfo(string|log:PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *log:KeyValues keyValues) {
        self.print(log:INFO, msg, 'error, stackTrace, keyValues);
    }

    public isolated function printWarn(string|log:PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *log:KeyValues keyValues) {
        self.print(log:WARN, msg, 'error, stackTrace, keyValues);
    }

    public isolated function withContext(*log:KeyValues keyValues) returns log:Logger|error {
        log:AnydataKeyValues newKeyValues = {...self.keyValues};
        foreach [string, log:Value] [k, v] in keyValues.entries() {
            newKeyValues[k] = v is log:Valuer ? v() : v is anydata ? v : log:evaluateTemplate(v);
        }
        return new CustomLogger(filePath = self.filePath, level = self.level, keyValues = newKeyValues.cloneReadOnly());
    }

    public isolated function getLevel() returns log:Level {
        return self.level;
    }

    public isolated function setLevel(log:Level level) returns error? {
        return error("Unsupported operation: CustomLogger does not support runtime level changes.");
    }

    isolated function print(log:Level level, string|log:PrintableRawTemplate msg, error? 'error, error:StackFrame[]? stackTrace, *log:KeyValues keyValues) {
        if !self.isLogLevelEnabled(level) {
            return;
        }
        string timestamp = time:utcToEmailString(time:utcNow());
        string message = msg is string ? msg : log:evaluateTemplate(msg);
        string logMessage = string `[${timestamp}] {${level}} "${message}" `;
        if 'error is error {
            logMessage += string `error="${'error.message()}"`;
        }
        if stackTrace is error:StackFrame[] {
            string[] traces = from var trace in stackTrace
                select trace.toString();
            string stackTraceString = string:'join(" ", ...traces);
            logMessage += string `traces="${stackTraceString}"`;
        }
        foreach [string, anydata] [k, v] in self.keyValues.entries() {
            logMessage += string ` ${k}="${v.toString()}"`;
        }
        foreach [string, log:Value] [k, v] in keyValues.entries() {
            anydata value = v is log:Valuer ? v() : v is anydata ? v : log:evaluateTemplate(v);
            logMessage += string ` ${k}="${value.toString()}"`;
        }
        logMessage += "\n";
        do {
            _ = check io:fileWriteString(self.filePath, logMessage, option = io:APPEND);
        } on fail error err {
            log:printError("Failed to write log message to file", err, stackTrace);
        }
    }
}

final log:Logger customInfoLogger = check new CustomLogger(filePath = "build/tmp/output/custom-logger-info.log", keyValues = {"mode": "info"});
final log:Logger customDebugLogger = check new CustomLogger(filePath = "build/tmp/output/custom-logger-debug.log", keyValues = {"mode": "debug"}, level = log:DEBUG);

final log:Logger customChildLogger = check customInfoLogger.withContext(child = true);

public function main() {
    customInfoLogger.printInfo("This is an info message");
    customInfoLogger.printError("This is an error message", error("An error occurred"));
    customInfoLogger.printWarn("This is a warning message");
    customInfoLogger.printDebug("This is a debug message");

    customDebugLogger.printInfo("This is an info message");
    customDebugLogger.printError("This is an error message", error("An error occurred"));
    customDebugLogger.printWarn("This is a warning message");
    customDebugLogger.printDebug("This is a debug message");

    customChildLogger.printInfo("This is an info message");
    customChildLogger.printError("This is an error message", error("An error occurred"));
    customChildLogger.printWarn("This is a warning message");
    customChildLogger.printDebug("This is a debug message");
}

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

# Logger object type defines an interface for logging messages
public type Logger isolated object {
   # Prints debug logs.
   #
   # + msg - The message to be logged
   # + 'error - The error struct to be logged
   # + stackTrace - The error stack trace to be logged
   # + keyValues - The key-value pairs to be logged
   public isolated function printDebug(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues);

   # Prints info logs.
   # 
   # + msg - The message to be logged
   # + 'error - The error struct to be logged
   # + stackTrace - The error stack trace to be logged
   # + keyValues - The key-value pairs to be logged
   public isolated function printInfo(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues);

   # Prints warn logs.
   # 
   # + msg - The message to be logged
   # + 'error - The error struct to be logged
   # + stackTrace - The error stack trace to be logged
   # + keyValues - The key-value pairs to be logged
   public isolated function printWarn(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues);

   # Prints error logs.
   # 
   # + msg - The message to be logged
   # + 'error - The error struct to be logged
   # + stackTrace - The error stack trace to be logged
   # + keyValues - The key-value pairs to be logged
   public isolated function printError(string|PrintableRawTemplate msg, error? 'error = (), error:StackFrame[]? stackTrace = (), *KeyValues keyValues);

   # Creates a new child/derived logger with the given key-values.
   #
   # + keyValues - The key-value pairs to be added to the logger context
   # + return - A new Logger instance with the given key-values added to its context
   public isolated function withContext(*KeyValues keyValues) returns Logger|error;

   # Returns the effective log level of this logger.
   # For root and custom loggers, returns the explicitly set level.
   # For child loggers (created via `withContext`), returns the inherited level from the parent logger.
   #
   # + return - The effective log level
   public isolated function getLevel() returns Level;

   # Sets the log level of this logger at runtime.
   # This is supported on root loggers, module loggers, and loggers created via `fromConfig`.
   # Child loggers (created via `withContext`) do not support this operation and will return an error.
   # To change a child logger's effective level, set the level on its parent logger instead.
   #
   # + level - The new log level to set
   # + return - An error if the operation is not supported, nil on success
   public isolated function setLevel(Level level) returns error?;
};

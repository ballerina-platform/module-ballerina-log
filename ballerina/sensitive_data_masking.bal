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

import ballerina/jballerina.java;

# Exclude the field from log output
public const EXCLUDE = "EXCLUDE";

# Replacement function type for sensitive data masking
public type ReplacementFunction isolated function (string input) returns string;

# Replacement strategy for sensitive data
public type Replacement record {|
    # The replacement value. This can be a string which will be used to replace the
    # entire value, or a function that takes the original value and returns a masked version.
    string|ReplacementFunction replacement;
|};

# Masking strategy for sensitive data
public type MaskingStrategy EXCLUDE|Replacement;

# Represents sensitive data with a masking strategy
public type SensitiveConfig record {|
    # The masking strategy to apply
    MaskingStrategy strategy = EXCLUDE;
|};

# Marks a record field or type as sensitive, excluding it from log output
# The default strategy is to exclude the field from log output
public annotation SensitiveConfig Sensitive on record field;

configurable boolean enableSensitiveDataMasking = false;

# Returns a masked string representation of the given data based on the sensitive data masking annotation.
# This method panics if a cyclic value reference is encountered.
#
# + data - The data to be masked
# + return - The masked string representation of the data
public isolated function toMaskedString(anydata data) returns string = @java:Method {
    'class: "io.ballerina.stdlib.log.Utils"
} external;

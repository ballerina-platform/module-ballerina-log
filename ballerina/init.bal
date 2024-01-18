// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

function init() returns error? {
    if(!(level is LogLevel)) {
       return  error(string `invalid log level: ${level}`);
    }
    lock {
        levelInternal = level;
    }
    
    boolean invalidModuleLogLevel = false;
    string invalidModule = "";
    string invalidLogLevel = "";
    modules.forEach(function(Module module) {
        string moduleName = module.name;
        string moduleLevel = module.level;

        if (!(moduleLevel is LogLevel)) {
            invalidModuleLogLevel = true;
            invalidLogLevel = moduleLevel;
            invalidModule = moduleName;
        }
        else {
            lock {
                modulesInternal.put({ name: moduleName, level: moduleLevel});
            }
        }
    });
    if invalidModuleLogLevel {
        return  error(string `invalid log level: ${invalidLogLevel} for module: ${invalidModule}`); 
    }
    setModule();
}

isolated function setModule() = @java:Method {
    'class: "io.ballerina.stdlib.log.ModuleUtils"
} external;

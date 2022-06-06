/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.log;

import io.ballerina.runtime.api.utils.IdentifierUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Native function implementations of the log-api module.
 *
 * @since 1.1.0
 */
public class Utils {

    private Utils() {

    }

    /**
     * Get the name of the current module.
     *
     * @return module name
     */
    public static BString getModuleNameExtern() {
        String className = Thread.currentThread().getStackTrace()[5].getClassName();
        String[] pkgData = className.split("\\.");
        if (pkgData.length > 1) {
            String module = IdentifierUtils.decodeIdentifier(pkgData[1]);
            return StringUtils.fromString(pkgData[0] + "/" + module);
        }
        return StringUtils.fromString(".");
    }

    /**
     * Get the current local time.
     *
     * @return current local time in RFC3339 format
     */
    public static BString getCurrentTime() {
        return StringUtils.fromString(
                new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX")
                        .format(new Date()));
    }
}

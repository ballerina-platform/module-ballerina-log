/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.stdlib.log.testutils;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.logging.formatters.JsonLogFormatter;

import java.util.Calendar;
import java.util.logging.Level;
import java.util.logging.LogRecord;

/**
 * Test cases JsonLogFormatter.
 */
public class JsonLogFormatterTestUtils {

    public static BString format(BString logMessage) {
        JsonLogFormatter jsonLogFormatter = new JsonLogFormatter();
        LogRecord logRecord = new LogRecord(Level.FINEST, logMessage.toString());
        return StringUtils.fromString(jsonLogFormatter.format(logRecord));
    }

    public static boolean formatNull() {
        boolean exceptionThrown = false;
        try {
            JsonLogFormatter jsonLogFormatter = new JsonLogFormatter();
            jsonLogFormatter.format(null);
        } catch (NullPointerException e) {
            exceptionThrown = true;
        } finally {
            return exceptionThrown;
        }
    }

    public static BString formatWithCustomValues(BString logMessage, BString logger, BString resourceBundleName,
                                                 BString className, BString methodName, int param, int threadId,
                                                 int sequenceNumber, int millis, int calMillis) {
        JsonLogFormatter jsonLogFormatter = new JsonLogFormatter();
        LogRecord logRecord = new LogRecord(Level.FINEST, logMessage.toString());

        logRecord.setMessage(logMessage.toString());
        logRecord.setLoggerName(logger.toString());
        logRecord.setResourceBundleName(resourceBundleName.toString());
        logRecord.setSourceClassName(className.toString());
        logRecord.setSourceMethodName(methodName.toString());
        logRecord.setParameters(new Object[]{Integer.valueOf(param), new Object()});
        logRecord.setThreadID(threadId);
        logRecord.setSequenceNumber(sequenceNumber);
        logRecord.setMillis(millis);

        String str = jsonLogFormatter.format(logRecord);
        Calendar cal = Calendar.getInstance();
        cal.setTimeInMillis(calMillis);

        return StringUtils.fromString(str);
    }

    public static BString getHead() {
        JsonLogFormatter jsonLogFormatter = new JsonLogFormatter();
        return StringUtils.fromString(jsonLogFormatter.getHead(null));
    }

    public static BString getTail() {
        JsonLogFormatter jsonLogFormatter = new JsonLogFormatter();
        return StringUtils.fromString(jsonLogFormatter.getTail(null));
    }
}

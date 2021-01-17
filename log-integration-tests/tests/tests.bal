import ballerina/config;
import ballerina/io;
import ballerina/os;
import ballerina/regex;
import ballerina/test;

const BAL_EXEC_PATH = "bal_exec_path";
const INCORRECT_NUMBER_OF_LINES = "incorrect number of lines in output";
const UTF_8 = "UTF-8";
const LOG_LEVEL_TEST_FILE = "tests/resources/log_level_test.bal";
const LOG_PROJECT_FOO = "tests/resources/foo";
const string PRINT_MESSAGE = "message = " + "\"" + "Inside main function" + "\"";
const string PRINT_ERROR_MESSAGE = "message = " + "\"" + "Something went wrong" + "\"";
const string PRINT_ERROR_WITH_CAUSE_MESSAGE = "message = " + "\"" + "Something went wrong" + "\"" + " error = " + "\"" +
                                              "bad sad" + "\"";
const string KEY_VALUE_FOO = "foo = true";
const string KEY_VALUE_ID = "id = 845315";
const string KEY_VALUE_USERNAME = "username = " + "\"" + "Alex92" + "\"";

@test:Config {}
public function testSingleFile() {
    os:Process|error execResult = os:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE);
    os:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 11, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], " ", PRINT_MESSAGE, [KEY_VALUE_FOO, KEY_VALUE_ID, KEY_VALUE_USERNAME]);
    validateLog(logLines[7], " ", PRINT_MESSAGE, [KEY_VALUE_ID, KEY_VALUE_USERNAME]);
    validateLog(logLines[8], " ", PRINT_ERROR_MESSAGE, [KEY_VALUE_FOO, KEY_VALUE_ID, KEY_VALUE_USERNAME]);
    validateLog(logLines[9], " ", PRINT_ERROR_MESSAGE, [KEY_VALUE_ID, KEY_VALUE_USERNAME]);
    validateLog(logLines[10], " ", PRINT_ERROR_WITH_CAUSE_MESSAGE, [KEY_VALUE_FOO, KEY_VALUE_ID, KEY_VALUE_USERNAME]);
}

isolated function validateLog(string log, string logLocation, string logMsg, string[] keyValues) {
    test:assertTrue(log.includes(logLocation));
    test:assertTrue(log.includes(logMsg));
    foreach var keyValue in keyValues {
        test:assertTrue(log.includes(keyValue));
    }
}



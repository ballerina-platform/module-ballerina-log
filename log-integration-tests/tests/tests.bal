import ballerina/io;
import ballerina/os;
import ballerina/regex;
import ballerina/test;

const INCORRECT_NUMBER_OF_LINES = "incorrect number of lines in output";
const UTF_8 = "UTF-8";
const LOG_LEVEL_TEST_FILE = "tests/resources/log_level_test.bal";
const BALCONFIGFILE_PATH = "tests/resources/Config.toml";
const string PRINT_MESSAGE_LOGFMT = "message = \"Inside main function\"";
const string PRINT_ERROR_MESSAGE_LOGFMT = "message = \"Something went wrong\"";
const string PRINT_ERROR_WITH_CAUSE_MESSAGE_LOGFMT = "message = \"Something went wrong\" error = \"bad sad\"";
const string KEY_VALUE_FOO_LOGFMT = "foo = true";
const string KEY_VALUE_ID_LOGFMT = "id = 845315";
const string KEY_VALUE_USERNAME_LOGFMT = "username = \"Alex92\"";

const string PRINT_MESSAGE_JSON = "\"message\": \"Inside main function\"";
const string PRINT_ERROR_MESSAGE_JSON = "\"message\": \"Something went wrong\"";
const string PRINT_ERROR_WITH_CAUSE_MESSAGE_JSON = "\"message\": \"Something went wrong\", \"error\": \"bad sad\"";
const string KEY_VALUE_FOO_JSON = "\"foo\": true";
const string KEY_VALUE_ID_JSON = "\"id\": 845315";
const string KEY_VALUE_USERNAME_JSON = "\"username\": \"Alex92\"";

configurable string bal_exec_path = ?;

@test:Config {}
public function testSingleFileLogfmtFormat() {
    os:Process|error execResult = os:exec(bal_exec_path, {}, (), "run", LOG_LEVEL_TEST_FILE);
    os:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 11, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], " ", PRINT_MESSAGE_LOGFMT, [KEY_VALUE_FOO_LOGFMT, KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[7], " ", PRINT_MESSAGE_LOGFMT, [KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[8], " ", PRINT_ERROR_MESSAGE_LOGFMT, [KEY_VALUE_FOO_LOGFMT, KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[9], " ", PRINT_ERROR_MESSAGE_LOGFMT, [KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[10], " ", PRINT_ERROR_WITH_CAUSE_MESSAGE_LOGFMT, [KEY_VALUE_FOO_LOGFMT, KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
}

@test:Config {}
public function testSingleFileJsonFormat() {
    os:Process|error execResult = os:exec(bal_exec_path, {BALCONFIGFILE: BALCONFIGFILE_PATH}, (), "run", LOG_LEVEL_TEST_FILE);
    os:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 11, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], " ", PRINT_MESSAGE_JSON, [KEY_VALUE_FOO_JSON, KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[7], " ", PRINT_MESSAGE_JSON, [KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[8], " ", PRINT_ERROR_MESSAGE_JSON, [KEY_VALUE_FOO_JSON, KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[9], " ", PRINT_ERROR_MESSAGE_JSON, [KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[10], " ", PRINT_ERROR_WITH_CAUSE_MESSAGE_JSON, [KEY_VALUE_FOO_JSON, KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
}

isolated function validateLog(string log, string logLocation, string logMsg, string[] keyValues) {
    test:assertTrue(log.includes(logLocation));
    test:assertTrue(log.includes(logMsg));
    foreach var keyValue in keyValues {
        test:assertTrue(log.includes(keyValue));
    }
}

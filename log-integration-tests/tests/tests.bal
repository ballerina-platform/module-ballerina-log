import ballerina/config;
import ballerina/io;
import ballerina/system;
import ballerina/stringutils;
import ballerina/test;

const BAL_EXEC_PATH = "bal_exec_path";
const LOG_PROJECT = "tests/resources/log-project";
const INCORRECT_NUMBER_OF_LINES = "incorrect number of lines in output";
const UTF_8 = "UTF-8";
const LOG_LEVEL_TEST_FILE = "tests/resources/log_level_test.bal";
const LOG_MESSAGE_TEST_FILE_LOCATION = "tests/resources/log-messages";
const LOG_LEVEL_PROPERTY = "b7a.log.level";
const ERROR_LOG = "ERROR level log";
const ERROR_LOG_WITH_ERROR = "ERROR level log with error : error(\"B7aError\",foo=\"bar\")";
const WARN_LOG = "WARN level log";
const INFO_LOG = "INFO level log";
const DEBUG_LOG = "DEBUG level log";
const TRACE_LOG = "TRACE level log";
const INTEGER_OUTPUT = "123456";
const FLOAT_OUTPUT = "123456.789";
const BOOLEAN_OUTPUT = "true";
const FUNCTION_OUTPUT = "Name of the fruit is is Apple";
const ERROR_WITH_CAUSE_OUTPUT = "error log with cause : error(\"error occurred\")";

@test:Config {}
public function testBasicLogFunctionality() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_PROJECT, "run");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], "INFO", "[logorg/foo]", "Logging from inside `foo` module");
    validateLog(logLines[10], "INFO", "[logorg/bar]", "Logging from inside `bar` module");
    validateLog(logLines[11], "ERROR", "[logorg/baz]", "Logging at ERROR level inside `baz`");
    validateLog(logLines[12], "INFO", "[logorg/mainmod]", "Logging from inside `mainmod` module");
}

function validateLog(string log, string logLevel, string logLocation, string logMsg) {
    test:assertTrue(stringutils:contains(log, logLevel));
    test:assertTrue(stringutils:contains(log, logLocation));
    test:assertTrue(stringutils:contains(log, logMsg));
}



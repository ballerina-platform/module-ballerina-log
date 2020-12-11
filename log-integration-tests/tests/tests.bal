import ballerina/config;
import ballerina/io;
import ballerina/system;
import ballerina/stringutils;
import ballerina/test;

const BAL_EXEC_PATH = "bal_exec_path";
const INCORRECT_NUMBER_OF_LINES = "incorrect number of lines in output";
const UTF_8 = "UTF-8";
const LOG_LEVEL_TEST_FILE = "tests/resources/log_level_test.bal";
const LOG_LEVEL_PROPERTY = "b7a.log.level";
const ERROR_LOG = "ERROR level log";
const ERROR_LOG_WITH_ERROR = "ERROR level log with error : error(\"B7aError\",foo=\"bar\")";
const INTEGER_OUTPUT = "123456";
const FLOAT_OUTPUT = "123456.789";
const BOOLEAN_OUTPUT = "true";
const FUNCTION_OUTPUT = "Name of the fruit is is Apple";
const ERROR_WITH_CAUSE_OUTPUT = "error log with cause : error(\"error occurred\")";

@test:Config {}
public function testSingleFile() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=INFO");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], " ", "message = " + "\"" + "Inside main function" + "\"");
    validateLog(logLines[7], " ", "message = " + "\"" + "Something went wrong" + "\"");
    validateLog(logLines[8], " ", "message = " + "\"" + "Something went wrong" + "\"" + " error = " + "\"" +
    "bad sad" + "\"");
}

function validateLog(string log, string logLocation, string logMsg) {
    test:assertTrue(stringutils:contains(log, logLocation));
    test:assertTrue(stringutils:contains(log, logMsg));
}



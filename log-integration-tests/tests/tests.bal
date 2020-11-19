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

@test:Config {}
public function testLogsOff() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=OFF");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 3, INCORRECT_NUMBER_OF_LINES);
}

@test:Config {}
public function testErrorLevel() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=ERROR");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 6, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "ERROR", "[]", ERROR_LOG);
    validateLog(logLines[5], "ERROR", "[]", ERROR_LOG_WITH_ERROR);
}

@test:Config {}
public function testWarnLevel() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=WARN");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 7, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "ERROR", "[]", ERROR_LOG);
    validateLog(logLines[5], "ERROR", "[]", ERROR_LOG_WITH_ERROR);
    validateLog(logLines[6], "WARN", "[]", WARN_LOG);
}

@test:Config {}
public function testInfoLevel() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=INFO");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 8, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "ERROR", "[]", ERROR_LOG);
    validateLog(logLines[5], "ERROR", "[]", ERROR_LOG_WITH_ERROR);
    validateLog(logLines[6], "WARN", "[]", WARN_LOG);
    validateLog(logLines[7], "INFO", "[]", INFO_LOG);
}

@test:Config {}
public function testDebugLevel() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=DEBUG");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "ERROR", "[]", ERROR_LOG);
    validateLog(logLines[5], "ERROR", "[]", ERROR_LOG_WITH_ERROR);
    validateLog(logLines[6], "WARN", "[]", WARN_LOG);
    validateLog(logLines[7], "INFO", "[]", INFO_LOG);
    validateLog(logLines[8], "DEBUG", "[]", DEBUG_LOG);
}

@test:Config {}
public function testTraceLevel() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=TRACE");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 10, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "ERROR", "[]", ERROR_LOG);
    validateLog(logLines[5], "ERROR", "[]", ERROR_LOG_WITH_ERROR);
    validateLog(logLines[6], "WARN", "[]", WARN_LOG);
    validateLog(logLines[7], "INFO", "[]", INFO_LOG);
    validateLog(logLines[8], "DEBUG", "[]", DEBUG_LOG);
    validateLog(logLines[9], "TRACE", "[]", TRACE_LOG);
}

@test:Config {}
public function testAllOn() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, (), "run", LOG_LEVEL_TEST_FILE,
     "--" + LOG_LEVEL_PROPERTY + "=ALL");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 10, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "ERROR", "[]", ERROR_LOG);
    validateLog(logLines[5], "ERROR", "[]", ERROR_LOG_WITH_ERROR);
    validateLog(logLines[6], "WARN", "[]", WARN_LOG);
    validateLog(logLines[7], "INFO", "[]", INFO_LOG);
    validateLog(logLines[8], "DEBUG", "[]", DEBUG_LOG);
    validateLog(logLines[9], "TRACE", "[]", TRACE_LOG);
}

@test:Config {}
public function testSettingLogLevelToPackage() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_PROJECT, "run",
    "--logorg/foo.loglevel=DEBUG", "--logorg/baz.loglevel=ERROR", "--logorg/mainmod.loglevel=OFF");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], "INFO", "[logorg/foo]", "Logging from inside `foo` module");
    validateLog(logLines[10], "DEBUG", "[logorg/foo]", "Logging at DEBUG level inside `foo`");
    validateLog(logLines[11], "INFO", "[logorg/bar]", "Logging from inside `bar` module");
    validateLog(logLines[12], "ERROR", "[logorg/baz]", "Logging at ERROR level inside `baz`");
}

@test:Config {}
public function testErrorMessage() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_MESSAGE_TEST_FILE_LOCATION,
     "run", "print_error_test.bal", "--" + LOG_LEVEL_PROPERTY + "=ERROR");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 10, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "ERROR", "[]", ERROR_LOG);
    validateLog(logLines[5], "ERROR", "[]", INTEGER_OUTPUT);
    validateLog(logLines[6], "ERROR", "[]", FLOAT_OUTPUT);
    validateLog(logLines[7], "ERROR", "[]", BOOLEAN_OUTPUT);
    validateLog(logLines[8], "ERROR", "[]", FUNCTION_OUTPUT);
    validateLog(logLines[9], "ERROR", "[]", ERROR_WITH_CAUSE_OUTPUT);
}

@test:Config {}
public function testWarnMessage() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_MESSAGE_TEST_FILE_LOCATION,
     "run", "print_warn_test.bal", "--" + LOG_LEVEL_PROPERTY + "=WARN");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "WARN", "[]", WARN_LOG);
    validateLog(logLines[5], "WARN", "[]", INTEGER_OUTPUT);
    validateLog(logLines[6], "WARN", "[]", FLOAT_OUTPUT);
    validateLog(logLines[7], "WARN", "[]", BOOLEAN_OUTPUT);
    validateLog(logLines[8], "WARN", "[]", FUNCTION_OUTPUT);
}

@test:Config {}
public function testInfoMessage() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_MESSAGE_TEST_FILE_LOCATION,
     "run", "print_info_test.bal", "--" + LOG_LEVEL_PROPERTY + "=INFO");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "INFO", "[]", INFO_LOG);
    validateLog(logLines[5], "INFO", "[]", INTEGER_OUTPUT);
    validateLog(logLines[6], "INFO", "[]", FLOAT_OUTPUT);
    validateLog(logLines[7], "INFO", "[]", BOOLEAN_OUTPUT);
    validateLog(logLines[8], "INFO", "[]", FUNCTION_OUTPUT);
}

@test:Config {}
public function testDebugMessage() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_MESSAGE_TEST_FILE_LOCATION,
     "run", "print_debug_test.bal", "--" + LOG_LEVEL_PROPERTY + "=DEBUG");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "DEBUG", "[]", DEBUG_LOG);
    validateLog(logLines[5], "DEBUG", "[]", INTEGER_OUTPUT);
    validateLog(logLines[6], "DEBUG", "[]", FLOAT_OUTPUT);
    validateLog(logLines[7], "DEBUG", "[]", BOOLEAN_OUTPUT);
    validateLog(logLines[8], "DEBUG", "[]", FUNCTION_OUTPUT);
}

@test:Config {}
public function testTraceMessage() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_MESSAGE_TEST_FILE_LOCATION,
     "run", "print_trace_test.bal", "--" + LOG_LEVEL_PROPERTY + "=TRACE");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[4], "TRACE", "[]", TRACE_LOG);
    validateLog(logLines[5], "TRACE", "[]", INTEGER_OUTPUT);
    validateLog(logLines[6], "TRACE", "[]", FLOAT_OUTPUT);
    validateLog(logLines[7], "TRACE", "[]", BOOLEAN_OUTPUT);
    validateLog(logLines[8], "TRACE", "[]", FUNCTION_OUTPUT);
}

@test:Config {}
public function testSetModuleLogLevel() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_PROJECT, "run", "hello");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 16, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], "ERROR", "[logorg/alpha]", "Logging error log from inside `alpha` module");
    validateLog(logLines[10], "WARN", "[logorg/alpha]", "Logging warn log from inside `alpha` module");
    validateLog(logLines[11], "ERROR", "[logorg/beta]", "Logging error log from inside `beta` module");
    validateLog(logLines[12], "WARN", "[logorg/beta]", "Logging warn log from inside `beta` module");
    validateLog(logLines[13], "INFO", "[logorg/beta]", "Logging info log from inside `beta` module");
    validateLog(logLines[14], "DEBUG", "[logorg/beta]", "Logging debug log from inside `beta` module");
    validateLog(logLines[15], "ERROR", "[logorg/hello]", "Logging error log from inside `hello` module");
}

@test:Config {}
public function testSetModuleLogLevelWithConsoleArgs() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_PROJECT, "run", "hello" ,
    "--logorg/alpha.loglevel=DEBUG", "--logorg/beta.loglevel=OFF");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 16, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], "ERROR", "[logorg/alpha]", "Logging error log from inside `alpha` module");
    validateLog(logLines[10], "WARN", "[logorg/alpha]", "Logging warn log from inside `alpha` module");
    validateLog(logLines[11], "ERROR", "[logorg/beta]", "Logging error log from inside `beta` module");
    validateLog(logLines[12], "WARN", "[logorg/beta]", "Logging warn log from inside `beta` module");
    validateLog(logLines[13], "INFO", "[logorg/beta]", "Logging info log from inside `beta` module");
    validateLog(logLines[14], "DEBUG", "[logorg/beta]", "Logging debug log from inside `beta` module");
    validateLog(logLines[15], "ERROR", "[logorg/hello]", "Logging error log from inside `hello` module");
}

@test:Config {}
public function testSetModuleLogLevelFromModule() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_PROJECT, "run", "omega");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 13, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], "ERROR", "[logorg/delta]", "Logging error log from inside `delta` module");
    validateLog(logLines[10], "WARN", "[logorg/delta]", "Logging warn log from inside `delta` module");
    validateLog(logLines[11], "INFO", "[logorg/delta]", "Logging info log from inside `delta` module");
    validateLog(logLines[12], "DEBUG", "[logorg/delta]", "Logging debug log from inside `delta` module");
}

@test:Config {}
public function testSetModuleLogLevelFromModuleOverridden() {
    system:Process|error execResult = system:exec(config:getAsString(BAL_EXEC_PATH), {}, LOG_PROJECT, "run", "omega2");
    system:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = stringutils:split(outText, "\n");
    test:assertEquals(logLines.length(), 10, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[9], "ERROR", "[logorg/delta2]", "Logging error log from inside `delta2` module");
}

function validateLog(string log, string logLevel, string logLocation, string logMsg) {
    test:assertTrue(stringutils:contains(log, logLevel));
    test:assertTrue(stringutils:contains(log, logLocation));
    test:assertTrue(stringutils:contains(log, logMsg));
}



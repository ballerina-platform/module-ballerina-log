import ballerina/io;
import ballerina/os;
import ballerina/regex;
import ballerina/test;

const INCORRECT_NUMBER_OF_LINES = "incorrect number of lines in output";
const UTF_8 = "UTF-8";
const LOG_LEVEL_TEST_FILE = "tests/resources/log_level_test.bal";
const BALCONFIGFILE_PATH = "tests/resources/Config.toml";
const string DIST_LIB_REL_PATH = "bre/lib/";
const string COVERAGE_DIR_REL_PATH = "target/cache/tests_cache/coverage/";
const string JACOCO_AGENT_JAR = "jacocoagent.jar";
const string JACOCO_EXEC_FILE_NAME = "ballerina-additional.exec";
const string PRINT_MESSAGE_LOGFMT = "message = \"Inside main function\"";
const string PRINT_ERROR_MESSAGE_LOGFMT = "message = \"Something went wrong\"";
const string PRINT_ERROR_WITH_CAUSE_MESSAGE_LOGFMT = "message = \"Something went wrong\" error = \"bad sad\"";
const string KEY_VALUE_FOO_LOGFMT = "foo = true";
const string KEY_VALUE_ID_LOGFMT = "id = 845315";
const string KEY_VALUE_USERNAME_LOGFMT = "username = \"Alex92\"";
const string LEVEL_INFO_LOGFMT = "level = INFO";
const string LEVEL_ERROR_LOGFMT = "level = ERROR";
const string MODULE_LOGFMT = "module = \"\"";

const string PRINT_MESSAGE_JSON = "\"message\": \"Inside main function\"";
const string PRINT_ERROR_MESSAGE_JSON = "\"message\": \"Something went wrong\"";
const string PRINT_ERROR_WITH_CAUSE_MESSAGE_JSON = "\"message\": \"Something went wrong\", \"error\": \"bad sad\"";
const string KEY_VALUE_FOO_JSON = "\"foo\": true";
const string KEY_VALUE_ID_JSON = "\"id\": 845315";
const string KEY_VALUE_USERNAME_JSON = "\"username\": \"Alex92\"";
const string MODULE_JSON = "\"module\": \"\"";
const string LEVEL_INFO_JSON = "\"level\": \"INFO \"";
const string LEVEL_ERROR_JSON = "\"level\": \"ERROR\"";

configurable string bal_exec_path = ?;

@test:Config {}
public function testSingleFileLogfmtFormat() {
    os:Process|error execResult = os:exec(bal_exec_path, createEnvVariables(), (), "run", "--debug", "5005", LOG_LEVEL_TEST_FILE);
    os:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 11, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_INFO_LOGFMT, MODULE_LOGFMT, PRINT_MESSAGE_LOGFMT, [KEY_VALUE_FOO_LOGFMT, KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[7], LEVEL_INFO_LOGFMT, MODULE_LOGFMT, PRINT_MESSAGE_LOGFMT, [KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[8], LEVEL_ERROR_LOGFMT, MODULE_LOGFMT, PRINT_ERROR_MESSAGE_LOGFMT, [KEY_VALUE_FOO_LOGFMT, KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[9], LEVEL_ERROR_LOGFMT, MODULE_LOGFMT, PRINT_ERROR_MESSAGE_LOGFMT, [KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
    validateLog(logLines[10], LEVEL_ERROR_LOGFMT, MODULE_LOGFMT, PRINT_ERROR_WITH_CAUSE_MESSAGE_LOGFMT, [KEY_VALUE_FOO_LOGFMT, KEY_VALUE_ID_LOGFMT, KEY_VALUE_USERNAME_LOGFMT]);
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
    validateLog(logLines[6], LEVEL_INFO_JSON, MODULE_JSON, PRINT_MESSAGE_JSON, [KEY_VALUE_FOO_JSON, KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[7], LEVEL_INFO_JSON, MODULE_JSON, PRINT_MESSAGE_JSON, [KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[8], LEVEL_ERROR_JSON, MODULE_JSON, PRINT_ERROR_MESSAGE_JSON, [KEY_VALUE_FOO_JSON, KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[9], LEVEL_ERROR_JSON, MODULE_JSON, PRINT_ERROR_MESSAGE_JSON, [KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
    validateLog(logLines[10], LEVEL_ERROR_JSON, MODULE_JSON, PRINT_ERROR_WITH_CAUSE_MESSAGE_JSON, [KEY_VALUE_FOO_JSON, KEY_VALUE_ID_JSON, KEY_VALUE_USERNAME_JSON]);
}

isolated function validateLog(string log, string level, string moduleName, string logMsg, string[] keyValues) {
    test:assertTrue(log.includes(level));
    test:assertTrue(log.includes(moduleName));
    test:assertTrue(log.includes(logMsg));
    foreach var keyValue in keyValues {
        test:assertTrue(log.includes(keyValue));
    }
}

function createEnvVariables() returns map<string> {
    string logModulePath = bal_exec_path.substring(0, <int> bal_exec_path.indexOf("log-integration-tests")) 
        + "log-ballerina" + "/";
    string balDistPath = logModulePath + 
        bal_exec_path.substring(<int> bal_exec_path.indexOf("build"), <int> bal_exec_path.indexOf("bin"));
    string jacocoAgentPath = balDistPath + DIST_LIB_REL_PATH + JACOCO_AGENT_JAR;
    string execFilePath = logModulePath + COVERAGE_DIR_REL_PATH + JACOCO_EXEC_FILE_NAME;
    map<string> envVariables= {
        JAVA_OPTS: os:getEnv("JAVA_OPTS") + " -javaagent:" + jacocoAgentPath + "=destfile=" + execFilePath +
        ",includes=* "
    };
    return envVariables;
}



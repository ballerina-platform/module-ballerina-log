//import ballerina/io;
import ballerina/regex;
import ballerina/test;

const INCORRECT_NUMBER_OF_LINES = "incorrect number of lines in output";
const UTF_8 = "UTF-8";
const LOG_MESSAGE_INFO_FILE = "tests/resources/log-messages/info.bal";
const LOG_MESSAGE_DEBUG_FILE = "tests/resources/log-messages/debug.bal";
const string MESSAGE_INFO = "message = \"info log\"";
const string MESSAGE_DEBUG = "message = \"debug log\"";
const string KEY_VALUES1 = "foo = true id = 845315 username = \"Alex92\"";
const string KEY_VALUES2 = "id = 845315 username = \"Alex92\"";
const string LEVEL_INFO = "level = INFO";
const string LEVEL_DEBUG = "level = DEBUG";
const string MODULE = "module = \"\"";

const string CONFIG_DEBUG_PATH = "tests/resources/config/debug/Config.toml";

configurable string bal_exec_path = ?;

@test:Config {}
public function testInfoMessage() {
    os:Process|error execResult = os:exec(bal_exec_path, {}, (), "run", LOG_MESSAGE_INFO_FILE);
    os:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_INFO, MODULE, MESSAGE_INFO, "");
    validateLog(logLines[7], LEVEL_INFO, MODULE, MESSAGE_INFO, KEY_VALUES1);
    validateLog(logLines[8], LEVEL_INFO, MODULE, MESSAGE_INFO, KEY_VALUES2);
}

@test:Config {}
public function testDebugMessage() {
    os:Process|error execResult = os:exec(bal_exec_path, {BALCONFIGFILE: CONFIG_DEBUG_PATH}, (), "run", LOG_MESSAGE_DEBUG_FILE);
    os:Process result = checkpanic execResult;
    int waitForExit = checkpanic result.waitForExit();
    int exitCode = checkpanic result.exitCode();
    io:ReadableByteChannel readableResult = result.stderr();
    io:ReadableCharacterChannel sc = new (readableResult, UTF_8);
    string outText = checkpanic sc.read(100000);
    string[] logLines = regex:split(outText, "\n");
    test:assertEquals(logLines.length(), 9, INCORRECT_NUMBER_OF_LINES);
    validateLog(logLines[6], LEVEL_DEBUG, MODULE, MESSAGE_DEBUG, "");
    validateLog(logLines[7], LEVEL_DEBUG, MODULE, MESSAGE_DEBUG, KEY_VALUES1);
    validateLog(logLines[8], LEVEL_DEBUG, MODULE, MESSAGE_DEBUG, KEY_VALUES2);
}

isolated function validateLog(string log, string level, string package, string message, string keyValues) {
    test:assertTrue(log.includes(level));
    test:assertTrue(log.includes(package));
    test:assertTrue(log.includes(message));
    test:assertTrue(log.includes(keyValues));
}

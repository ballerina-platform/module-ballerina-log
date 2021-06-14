import ballerina/io;
import ballerina/log;
import ballerina/observe;
import ballerina/observe.mockextension;

public function main() {
    foo();
    var spans = mockextension:getFinishedSpans("Ballerina");
    io:println(spans[0].traceId);
    io:println(spans[0].spanId);
}

@observe:Observable
function foo() {
    log:printError("error log");
    log:printWarn("warn log");
    log:printInfo("info log");
    log:printDebug("debug log");
}

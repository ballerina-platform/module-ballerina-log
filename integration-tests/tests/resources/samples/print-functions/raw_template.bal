import ballerina/log;

type HttpError error<map<anydata>>;

public function main() {
    string name = "Alex92";
    int id = 845315;
    boolean active = true;

    log:printError(string `Status: ${active} for user ${name} with ID ${id}`);
    // log:printDebug(string `User ${name} with ID ${id} encountered an error`, id=343434);

    // error e = error("bad sad");
    // log:printError(string `Error occurred: ${e.message()}`);

    // map<anydata> httpError = {
    //     "code": 403,
    //     "details": "Authentication failed"
    // };
    // HttpError err = error(httpError.toJsonString());
    // log:printError(string `HTTP Error: ${err.message()}`);

    // // Testing escaping in raw templates
    // log:printError(string `Special chars: \t\n\r\\\"`);

    // f1();
}

// function f1() {
//     f2();
// }

// function f2() {
//     f3();
// }

// function f3() {
//     string stackTrace = "asdasdasd";
//     log:printError(string `Stack trace error: ${stackTrace}`);
// }

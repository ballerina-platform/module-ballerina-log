## Overview

This module provides APIs to log information when running applications, with support for contextual logging, configurable log levels, formats, destinations, and key-value context.

### Log Levels

The log module supports four log levels, in order of priority:

1. `ERROR`
2. `WARN`
3. `INFO`
4. `DEBUG`

By default, only `INFO` and higher level logs are logged. The log level can be configured globally or per module in the `Config.toml` file:

```toml
[ballerina.log]
level = "DEBUG" # or INFO, WARN, ERROR
```

Per-module log level:

```toml
[[ballerina.log.modules]]
name = "[ORG_NAME]/[MODULE_NAME]"
level = "[LOG_LEVEL]"
```

### Logging API

Log messages at different levels using:

```ballerina
log:printDebug("debug log");
log:printError("error log");
log:printInfo("info log");
log:printWarn("warn log");
```

You can also log errors and add contextual key-value pairs (including function pointers and templates):

```ballerina
log:printError("error log with cause", err);
log:printInfo("info log", id = 845315, name = "foo", successful = true);
```

Sample output (LogFmt):

```log
time=2025-08-20T08:49:05.484+05:30 level=INFO module="" message="info log" id=845315 name="foo" successful=true
```

### Log Output and Format

By default, logs are written to the `stderr` stream in `logfmt` format. You can configure the output format and destinations in `Config.toml`:

```toml
[ballerina.log]
format = "json" # or "logfmt"

[[ballerina.log.destinations]]
type = "stderr" # or "stdout"

[[ballerina.log.destinations]]
path = "./logs/app.log"
```

Sample output (JSON):

```json
{"time":"2025-08-20T11:26:00.021+05:30", "level":"INFO", "module":"myorg/foo", "message":"Authenticating user"}
```

> **Note:**
>
> - Destination types can be `stderr`, `stdout`, or `file`. File Destination must point to a path with a `.log` extension.
> - The deprecated `log:setOutputFile()` should be avoided; use configuration instead.

### Root Context

You can add a default context to all log messages:

```toml
[ballerina.log]
keyValues = {env = "prod", nodeId = "delivery-svc-001"}
```

### Contextual Logging

The log module supports contextual logging, allowing you to create loggers with additional context or unique configurations.

- **Root Logger:** The default logger, accessed via `log:root()`.
- **Child Logger with Context:**

    ```ballerina
    log:Logger parentLogger = log:root();
    log:Logger childLogger = parentLogger.withContext("userId": "12345", "requestId": "abcde");
    childLogger.printInfo("User logged in");
    ```

    The log message will include the additional context.

- **Logger with Unique Configuration:**

    ```ballerina
    log:Config auditLogConfig = {
            level: log:INFO,
            format: "json",
            destinations: ["./logs/audit.log"]
    };
    log:Logger auditLogger = log:fromConfig(auditLogConfig);
    auditLogger.printInfo("Hello World from the audit logger!");
    ```

For more details and advanced usage, see the module specification and API documentation.

## Sensitive Data Masking

The log module provides capabilities to mask sensitive data in log messages to maintain data privacy and security when dealing with personally identifiable information (PII) or other sensitive data.

> **Note**: By default, sensitive data masking is disabled. Enable it in `Config.toml`:
>
> ```toml
> [ballerina.log]
> enableSensitiveDataMasking = true
> ```
>
> Or configure it per logger:
>
> ```ballerina
> log:Config secureConfig = {
>     enableSensitiveDataMasking: true
> };
> log:Logger secureLogger = log:fromConfig(secureConfig);
> ```

### Sensitive Data Annotation

Use the `@log:Sensitive` annotation to mark fields in records as sensitive. When such fields are logged, their values will be excluded or masked:

```ballerina
import ballerina/log;

type User record {
    string id;
    @log:Sensitive
    string password;
    string name;
};

public function main() {
    User user = {id: "U001", password: "mypassword", name: "John Doe"};
    log:printInfo("user details", user = user);
}
```

Output (with masking enabled):

```log
time=2025-08-20T09:15:30.123+05:30 level=INFO module="" message="user details" user={"id":"U001","name":"John Doe"}
```

### Masking Strategies

Configure masking strategies using the `strategy` field:

```ballerina
import ballerina/log;

isolated function maskString(string input) returns string {
    if input.length() <= 2 {
        return "****";
    }
    return input.substring(0, 1) + "****" + input.substring(input.length() - 1);
}

type User record {
    string id;
    @log:Sensitive {
        strategy: {
            replacement: "****"
        }   
    }
    string password;
    @log:Sensitive {
        strategy: {
            replacement: maskString
        }
    }
    string ssn;
    string name;
};
```

### Masked String Function

Use `log:toMaskedString()` to get the masked version of a value for custom logging implementations:

```ballerina
User user = {id: "U001", password: "mypassword", name: "John Doe"};
string maskedUser = log:toMaskedString(user);
io:println(maskedUser); // {"id":"U001","name":"John Doe"}
```


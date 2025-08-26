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
destinations = ["stderr", {path = "./logs/app.log"}]
```

Sample output (JSON):

```json
{"time":"2025-08-20T11:26:00.021+05:30", "level":"INFO", "module":"myorg/foo", "message":"Authenticating user"}
```

> **Note:**
>
> - Destinations can be `stderr`, `stdout`, or a file destination points to a path with `.log` extension.
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

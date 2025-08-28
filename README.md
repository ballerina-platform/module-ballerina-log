# Ballerina Log Library

  [![Build](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-timestamped-master.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-timestamped-master.yml)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerina-log/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerina-log)
  [![Trivy](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/trivy-scan.yml)
  [![GraalVM Check](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-with-bal-test-graalvm.yml)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-log.svg)](https://github.com/ballerina-platform/module-ballerina-log/commits/master)
  [![Github issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-standard-library/module/log.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-standard-library/labels/module%2Flog)

This library provides APIs to log information when running applications, with support for contextual logging, configurable log levels, formats, destinations, and key-value context.

A sample log message logged from the `foo` module would look as follows:

```bash
time = 2021-05-12T11:20:29.362+05:30 level = ERROR module = myorg/foo message = "Something went wrong"
```

## Log Levels

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

## Logging API

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

## Log Output and Format

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

## Root Context

You can add a default context to all log messages:

```toml
[ballerina.log]
keyValues = {env = "prod", nodeId = "delivery-svc-001"}
```

## Contextual Logging

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

## Build from the source

### Set up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21 (from one of the following locations).

   - [Oracle](https://www.oracle.com/java/technologies/downloads/)
   - [OpenJDK](https://adoptium.net/)

   > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Export Github Personal access token with read package permissions as follows,

    ```console
    export packageUser=<Username>
    export packagePAT=<Personal access token>   
    ```  

### Build the source

Execute the commands below to build from source.

1. To build the package:

    ```console
    ./gradlew clean build
    ```

2. To run the tests:

    ```console
    ./gradlew clean test
    ```

3. To run a group of tests

    ```console
    ./gradlew clean test -Pgroups=<test_group_names>
    ```

4. To build the without the tests:

    ```console
    ./gradlew clean build -x test
    ```

5. To debug package implementation:

    ```console
    ./gradlew clean build -Pdebug=<port>
    ```

6. To debug with Ballerina language:

    ```console
    ./gradlew clean build -PbalJavaDebug=<port>
    ```

7. Publish the generated artifacts to the local Ballerina central repository:

    ```console
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina central repository:

    ```console
    ./gradlew clean build -PpublishToCentral=true
    ```

## Contribute to Ballerina

As an open source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

- Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
- Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
- For more information go to the [`log` library](https://lib.ballerina.io/ballerina/log/latest).
- For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/swan-lake/learn/by-example/).

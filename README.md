Ballerina Log Library
===================

  [![Build](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-timestamped-master.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-timestamped-master.yml)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerina-log/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerina-log)
  [![Trivy](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/trivy-scan.yml)
  [![GraalVM Check](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-log/actions/workflows/build-with-bal-test-graalvm.yml)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-log.svg)](https://github.com/ballerina-platform/module-ballerina-log/commits/master)
  [![Github issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-standard-library/module/log.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-standard-library/labels/module%2Flog)

This library provides APIs to log information when running applications.

A sample log message logged from the `foo` module would look as follows:
```bash
time = 2021-05-12T11:20:29.362+05:30 level = ERROR module = myorg/foo message = "Something went wrong"
```

### Log levels

The `log` module provides APIs to log at four levels, which are `DEBUG`, `ERROR`, `INFO`, and `WARN`. By default, all log messages are logged to the console at the `INFO` level.

The log level can be configured via a Ballerina configuration file.
To set the global log level, place the entry given below in the `Config.toml` file:

```
[ballerina.log]
level = "[LOG_LEVEL]"
```

Each module can also be assigned its own log level. To assign a log level to a module, provide the following entry in the `Config.toml` file:

```
[[ballerina.log.modules]]
name = "[ORG_NAME]/[MODULE_NAME]"
level = "[LOG_LEVEL]"
```

### Log output

Logs are written to the `stderr` stream by default.

To publish the logs to a file, redirect the `stderr` stream to a file as follows.
```bash
$ bal run program.bal 2> b7a-user.log
```

By default, logs are printed in the `LogFmt` format. To set the output format to JSON, place the entry given below in the `Config.toml` file.

```
[ballerina.log]
format = "json"
```

A sample log message logged from the `foo` module in JSON format would look as follows:
```bash
{"time":"2021-05-12T11:26:00.021+05:30", "level":"INFO", "module":"myorg/foo", "message":"Authenticating user"}
```

## Issues and projects

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina Standard Library. To report bugs, request new features, start new discussions, view project boards, etc. please visit Ballerina Standard Library [parent repository](https://github.com/ballerina-platform/ballerina-standard-library).

This repository only contains the source code for the package.

## Build from the source

### Set up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).
   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
   
   * [OpenJDK](https://adoptium.net/)
   
        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.
     
2. Export Github Personal access token with read package permissions as follows,
   
           export packageUser=<Username>
           export packagePAT=<Personal access token>     
                
### Build the source

Execute the commands below to build from source.

1. To build the package:
    ```    
    ./gradlew clean build
    ```
2. To run the tests:
    ```
    ./gradlew clean test
    ```

3. To run a group of tests
    ```
    ./gradlew clean test -Pgroups=<test_group_names>
    ```

4. To build the without the tests:
    ```
    ./gradlew clean build -x test
    ```

5. To debug package implementation:
    ```
    ./gradlew clean build -Pdebug=<port>
    ```

6. To debug with Ballerina language:
    ```
    ./gradlew clean build -PbalJavaDebug=<port>
    ```

7. Publish the generated artifacts to the local Ballerina central repository:
    ```
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina central repository:
    ```
    ./gradlew clean build -PpublishToCentral=true
    ```

## Contribute to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
* For more information go to the [`log` library](https://lib.ballerina.io/ballerina/log/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/swan-lake/learn/by-example/).

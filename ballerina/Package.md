## Package Overview

This package provides APIs to log information when running applications.

A sample log message logged from the `foo` module would look as follows:
```bash
time = 2021-05-12T11:20:29.362+05:30 level = ERROR module = myorg/foo message = "Something went wrong"
```

### Log Levels

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

### Log Output

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
## Report Issues

To report bugs, request new features, start new discussions, view project boards, etc., go to the [Ballerina standard library parent repository](https://github.com/ballerina-platform/ballerina-standard-library).

## Useful Links

- Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
- Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.

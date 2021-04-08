## Package Overview

This package provides a basic API for logging.

### Log record 

A log record contains the timestamp, log level, module name, and the log message.
Users can pass any number of key/value pairs which needs to be displayed in the log message.
These can be of `anydata` type including int, string and boolean.

A sample log record logged from the `foo` module would look as follows:
```bash
time = 2020-12-16 11:22:44,029 level = ERROR module = myorg/foo message = "Something went wrong."
```

### Log Output

Logs are written to the `stderr` stream (i.e., the console) by default in order to make the logs more container friendly.

To publish the logs to a file, redirect the `stderr` stream to a file.
```bash
$ ballerina run program.bal 2> b7a-user.log
```

To set the output format to JSON, place the entry given below in the `Config.toml` file.

```
[ballerina.log]
format = "json"
```

### Log Levels

This package provides functions to log at four levels, which are `DEBUG`, `ERROR`, `INFO`, and `WARN`. By default, all log messages are  logged to the console at the `INFO` level. 

The log level can be configured via a Ballerina configuration file.
To set the global log level, place the entry given below in the Config.toml file:

```
[ballerina.log]
level = "[LOG_LEVEL]"
```

Each module can also be assigned its own log level. To assign a log level to a module, provide the following entry in the Config.toml file:

```
[[ballerina.log.modules]]
name = "[ORG_NAME]/[MODULE_NAME]"
level = "[LOG_LEVEL]"
```

For information on the operation, which you can perform with this package, see the below Function. For examples on the usage of the operation, see [Log Api](https://ballerina.io/learn/by-example/log-api.html).

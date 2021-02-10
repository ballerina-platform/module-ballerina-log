## Module Overview

This module provides a basic API for logging.

### Loggers 

Each module in Ballerina has its own dedicated logger. A log record contains the timestamp, log level, module name, and the log message. The `printError()` function takes an optional `error` record apart from the log message. A sample log record logged from the `foo` module would look as follows:
```bash
time = 2020-12-16 11:22:44,029 level = ERROR module = myorg/foo message = "Something went wrong."
```

### Log Output

Logs are written to the `stderr` stream (i.e., the console) by default in order to make the logs more container friendly.

To publish the logs to a file, redirect the `stderr` stream to a file.
```bash
$ ballerina run program.bal 2> b7a-user.log
```

### Log Levels

This module provides functions to log at the `INFO`, and `ERROR` levels. There is no user configuration to control the log level and by default all the logs will get printed.

For information on the operation, which you can perform with this module, see the below Function. For examples on the usage of the operation, see [Log Api](https://ballerina.io/learn/by-example/log-api.html).

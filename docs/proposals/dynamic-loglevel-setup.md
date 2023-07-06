# Proposal: Support Data Mapping in CSV read/write operations

_Owners_: @daneshk   
_Reviewers_: @daneshk  
_Created_: 2023/07/06   
_Updated_: -
_Issues_: [#4633](https://github.com/ballerina-platform/ballerina-standard-library/issues/4633)

## Summary
Currently, the log module does not support dynamic log levels and the user has to restart the runtime to change the log level of the code. This proposal aims to add support for dynamic log levels for root and module levels.

## Goals

* Add dynamic log levels support for root level and module level.

* Add a new API.
    * ```setLogLevel()``` - To set the root and module log level.
## Motivation

Until now, user didn't have the support for dynamic log levels which can be a hindrance in large code bases. This feature is available in most of the popular programming languages. To support user requirements [discord thread](https://discord.com/channels/957996897782616114/1124006547857616916), we are adding these two new APIs.

## Description

We will be adding the new API with the following signature to set the root and module log levels depending on the input parameters.
`log:setLogLevel(string? organization = (), string? module = (), string level)`
If both `organization` and `module` are present, module log level is modified and otherwise the root log level is modified. The log levels mentioned in Config.toml is considered as the default level, and it won't be changed during the dynamic log level changes during runtime.


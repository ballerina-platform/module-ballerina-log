# Log Rotation Feature

## Overview

The Ballerina log module now supports automatic log rotation to prevent log files from growing indefinitely and consuming excessive disk space. This feature is essential for production deployments and long-running applications.

## Features

- **Size-based rotation**: Rotate logs when file size reaches a specified threshold
- **Time-based rotation**: Rotate logs after a specified time period
- **Combined rotation**: Rotate logs based on either size or time, whichever condition is met first
- **Automatic backup management**: Automatically manage and clean up old backup files
- **Configurable retention**: Control the number of backup files to retain

## Configuration

Log rotation is configured through the `FileOutputDestination` record's `rotation` field:

```ballerina
public type RotationConfig record {|
    # Rotation policy to use
    RotationPolicy policy = NONE;
    # Maximum file size in bytes before rotation (used with SIZE_BASED or BOTH policies)
    # Default: 10MB (10 * 1024 * 1024 bytes)
    int maxFileSize = 10485760;
    # Maximum age in milliseconds before rotation (used with TIME_BASED or BOTH policies)
    # Default: 24 hours (24 * 60 * 60 * 1000 ms)
    int maxAge = 86400000;
    # Maximum number of backup files to retain. Older files are deleted.
    # Default: 10 backup files
    int maxBackupFiles = 10;
|};
```

### Rotation Policies

The `RotationPolicy` enum provides four options:

- `SIZE_BASED`: Rotate logs based on file size only
- `TIME_BASED`: Rotate logs based on time only
- `BOTH`: Rotate logs when either size or time threshold is reached
- `NONE`: No automatic rotation (default)

## Usage Examples

### Example 1: Size-Based Rotation

Rotate logs when the file reaches 10MB, keeping up to 5 backup files:

```ballerina
import ballerina/log;

public function main() returns error? {
    log:Logger logger = check log:fromConfig(
        destinations = [
            {
                'type: log:FILE,
                path: "./logs/app.log",
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 10485760, // 10MB
                    maxBackupFiles: 5
                }
            }
        ]
    );

    logger.printInfo("Application started");
    // ... your application logic
}
```

### Example 2: Time-Based Rotation

Rotate logs every 24 hours, keeping up to 7 backup files (one week of logs):

```ballerina
import ballerina/log;

public function main() returns error? {
    log:Logger logger = check log:fromConfig(
        destinations = [
            {
                'type: log:FILE,
                path: "./logs/daily.log",
                rotation: {
                    policy: log:TIME_BASED,
                    maxAge: 86400000, // 24 hours in milliseconds
                    maxBackupFiles: 7
                }
            }
        ]
    );

    logger.printInfo("Daily logging started");
}
```

### Example 3: Combined Rotation (Production Recommended)

Rotate logs when file reaches 50MB OR after 12 hours, whichever comes first:

```ballerina
import ballerina/log;

public function main() returns error? {
    log:Logger logger = check log:fromConfig(
        format: log:JSON_FORMAT,
        destinations = [
            {
                'type: log:FILE,
                path: "./logs/production.log",
                rotation: {
                    policy: log:BOTH,
                    maxFileSize: 52428800, // 50MB
                    maxAge: 43200000, // 12 hours
                    maxBackupFiles: 10
                }
            }
        ]
    );

    logger.printInfo("Production service started");
}
```

### Example 4: Multiple Destinations with Different Rotation Policies

Configure different rotation policies for different log files:

```ballerina
import ballerina/log;

public function main() returns error? {
    log:Logger logger = check log:fromConfig(
        destinations = [
            {'type: log:STDERR}, // Console output (no rotation)
            {
                'type: log:FILE,
                path: "./logs/application.log",
                rotation: {
                    policy: log:SIZE_BASED,
                    maxFileSize: 20971520, // 20MB
                    maxBackupFiles: 5
                }
            },
            {
                'type: log:FILE,
                path: "./logs/audit.log",
                rotation: {
                    policy: log:BOTH,
                    maxFileSize: 104857600, // 100MB
                    maxAge: 604800000, // 7 days
                    maxBackupFiles: 30
                }
            }
        ]
    );

    logger.printInfo("Multi-destination logging configured");
}
```

### Example 5: Using Config.toml

You can also configure log rotation through `Config.toml`:

```toml
[[log.destinations]]
type = "file"
path = "./logs/app.log"
mode = "APPEND"

[log.destinations.rotation]
policy = "BOTH"
maxFileSize = 10485760  # 10MB
maxAge = 86400000       # 24 hours
maxBackupFiles = 7
```

Then in your Ballerina code:

```ballerina
import ballerina/log;

public function main() {
    log:printInfo("Using rotation config from Config.toml");
}
```

## Backup File Naming

When logs are rotated, backup files are created with a timestamp suffix:

```
app.log              # Current active log file
app-20251209-143022.log  # Backup from Dec 9, 2025 at 14:30:22
app-20251209-103015.log  # Earlier backup
app-20251208-183010.log  # Backup from previous day
```

The timestamp format is: `yyyyMMdd-HHmmss`

## Best Practices

### 1. Choose Appropriate Size Limits

- **Development**: 10-50 MB
- **Production**: 50-500 MB depending on log volume
- **High-traffic systems**: Consider smaller sizes (50-100 MB) with more frequent rotation

### 2. Set Reasonable Time Limits

- **Daily rotation**: `maxAge = 86400000` (24 hours)
- **Hourly rotation**: `maxAge = 3600000` (1 hour)
- **Weekly rotation**: `maxAge = 604800000` (7 days)

### 3. Balance Backup File Retention

- Keep enough backups for troubleshooting: typically 5-30 files
- Consider disk space constraints
- For compliance, adjust based on retention policies

### 4. Use Combined Policy for Production

The `BOTH` policy provides the best balance:

```ballerina
rotation: {
    policy: log:BOTH,
    maxFileSize: 52428800,  // 50MB - prevents huge files
    maxAge: 86400000,        // 24 hours - ensures daily rotation
    maxBackupFiles: 14       // 2 weeks of logs
}
```

### 5. Monitor Disk Space

Even with rotation, ensure adequate disk space:
- Monitor disk usage alerts
- Set `maxBackupFiles` based on available space
- Consider log compression for archived files (manual process)

### 6. Test Rotation Configuration

Before production deployment:

```ballerina
// Test with small values
rotation: {
    policy: log:SIZE_BASED,
    maxFileSize: 1024,  // 1KB for testing
    maxBackupFiles: 3
}
```

## Performance Considerations

- Rotation checks are performed before each write operation
- The check is lightweight and uses file metadata
- Actual rotation is synchronized to prevent concurrent rotation attempts
- Minimal performance impact on application logging

## Troubleshooting

### Issue: Logs not rotating

**Check:**
1. Verify rotation policy is not `NONE`
2. Ensure thresholds are being reached
3. Check file permissions for rotation operations
4. Verify disk space is available

### Issue: Too many backup files

**Solution:**
- Reduce `maxBackupFiles` value
- Implement external log archival/cleanup process

### Issue: Backup files not being cleaned up

**Check:**
1. File naming pattern matches expected format
2. File permissions allow deletion
3. No external processes holding file locks

## Migration from `setOutputFile`

If you're using the deprecated `setOutputFile` function, migrate to the new configuration:

**Old approach:**
```ballerina
check log:setOutputFile("./logs/app.log", log:APPEND);
```

**New approach with rotation:**
```ballerina
log:Logger logger = check log:fromConfig(
    destinations = [
        {
            'type: log:FILE,
            path: "./logs/app.log",
            mode: log:APPEND,
            rotation: {
                policy: log:SIZE_BASED,
                maxFileSize: 10485760,
                maxBackupFiles: 5
            }
        }
    ]
);
```

## Common Configuration Scenarios

### Microservices (High Volume)

```ballerina
rotation: {
    policy: log:BOTH,
    maxFileSize: 20971520,   // 20MB
    maxAge: 3600000,         // 1 hour
    maxBackupFiles: 24       // 24 hours of logs
}
```

### Batch Processing

```ballerina
rotation: {
    policy: log:TIME_BASED,
    maxAge: 86400000,        // Daily rotation
    maxBackupFiles: 30       // 30 days retention
}
```

### API Gateway

```ballerina
rotation: {
    policy: log:BOTH,
    maxFileSize: 104857600,  // 100MB
    maxAge: 43200000,        // 12 hours
    maxBackupFiles: 14       // Week retention
}
```

### Debug/Troubleshooting

```ballerina
rotation: {
    policy: log:SIZE_BASED,
    maxFileSize: 52428800,   // 50MB
    maxBackupFiles: 20       // More backups for analysis
}
```

## Security Considerations

- Rotated log files inherit the same file permissions as the original
- Ensure proper file permissions are set on the log directory
- Consider encrypting sensitive logs in backup files
- Implement appropriate access controls for log directories

## Future Enhancements

Potential future additions:
- Compression of rotated log files
- Custom rotation triggers
- Integration with log management systems
- Asynchronous rotation to minimize blocking

## Support

For issues, questions, or feature requests related to log rotation:
- GitHub Issues: [ballerina-platform/module-ballerina-log](https://github.com/ballerina-platform/module-ballerina-log/issues)
- Ballerina Discord: [discord.gg/ballerinalang](https://discord.gg/ballerinalang)

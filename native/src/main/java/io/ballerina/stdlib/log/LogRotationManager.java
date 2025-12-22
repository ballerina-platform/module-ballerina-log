/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.log;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.values.BError;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.locks.ReentrantLock;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;

/**
 * Manages log file rotation based on size and time policies.
 *
 * @since 2.2.0
 */
public class LogRotationManager {

    private static final ConcurrentHashMap<String, LogRotationManager> instances = new ConcurrentHashMap<>();
    private static final String SIZE_BASED = "SIZE_BASED";
    private static final String TIME_BASED = "TIME_BASED";
    private static final String BOTH = "BOTH";
    
    private final String filePath;
    private final String rotationPolicy;
    private final long maxFileSize;
    private final long maxAge;
    private final int maxBackupFiles;

    // Thread-safety fields for rotation
    private final ReentrantLock rotationLock;  // Protects the rotation operation itself

    // AtomicBoolean flag to prevent multiple threads from performing expensive rotation checks
    // simultaneously. This is a performance optimization to avoid redundant filesystem operations
    // (file.exists(), file.length()) when rotation is already in progress by another thread.
    private final AtomicBoolean rotationInProgress;

    // Volatile to ensure all threads see the latest rotation time without synchronization.
    // This allows fast, lock-free checks for time-based rotation conditions.
    private volatile long lastRotationTime;

    private LogRotationManager(String filePath, String rotationPolicy, long maxFileSize,
                               long maxAge, int maxBackupFiles) {
        this.filePath = filePath;
        this.rotationPolicy = rotationPolicy;
        this.maxFileSize = maxFileSize;
        this.maxAge = maxAge;
        this.maxBackupFiles = maxBackupFiles;
        this.rotationLock = new ReentrantLock();
        this.rotationInProgress = new AtomicBoolean(false);
        this.lastRotationTime = System.currentTimeMillis();
    }

    /**
     * Get or create a LogRotationManager instance for a specific file path.
     * Parameters should be validated in Ballerina before calling this method.
     *
     * @param filePath The log file path
     * @param rotationPolicy The rotation policy (SIZE_BASED, TIME_BASED, BOTH, or NONE)
     * @param maxFileSize Maximum file size in bytes before rotation
     * @param maxAgeInMillis Maximum age in milliseconds before rotation
     * @param maxBackupFiles Maximum number of backup files to keep
     * @return LogRotationManager instance
     */
    public static LogRotationManager getInstance(String filePath, String rotationPolicy,
                                                   long maxFileSize, long maxAgeInMillis, int maxBackupFiles) {
        return instances.computeIfAbsent(filePath, key ->
                new LogRotationManager(filePath, rotationPolicy, maxFileSize, maxAgeInMillis, maxBackupFiles));
    }

    /**
     * Public method to perform log rotation.
     * Called from Ballerina after determining rotation is needed.
     *
     * @return BError if rotation fails, null otherwise
     */
    public BError rotate() {
        // Try to acquire the rotation flag atomically
        if (rotationInProgress.compareAndSet(false, true)) {
            try {
                return performRotation();
            } finally {
                rotationInProgress.set(false);
            }
        }
        // Another thread is already rotating, skip
        return null;
    }

    /**
     * Get the current file size in bytes.
     *
     * @return File size in bytes, or 0 if file doesn't exist
     */
    public long getCurrentFileSize() {
        File file = new File(filePath);
        return file.exists() ? file.length() : 0;
    }

    /**
     * Get milliseconds since last rotation.
     *
     * @return Milliseconds since last rotation
     */
    public long getTimeSinceLastRotation() {
        return System.currentTimeMillis() - lastRotationTime;
    }

    /**
     * Get the rotation policy.
     *
     * @return Rotation policy string
     */
    public String getRotationPolicy() {
        return rotationPolicy;
    }

    /**
     * Get the maximum file size before rotation.
     *
     * @return Max file size in bytes
     */
    public long getMaxFileSize() {
        return maxFileSize;
    }

    /**
     * Get the maximum age before rotation.
     *
     * @return Max age in milliseconds
     */
    public long getMaxAge() {
        return maxAge;
    }

    /**
     * Perform the actual log file rotation.
     *
     * @return BError if rotation fails, null otherwise
     */
    private BError performRotation() {
        rotationLock.lock();
        try {
            File currentFile = new File(filePath);
            if (!currentFile.exists()) {
                return null;
            }

            // Generate rotated file name with timestamp.
            // Note: SimpleDateFormat is intentionally created per rotation for thread safety.
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd-HHmmss");
            String timestamp = dateFormat.format(new Date());
            int extensionIndex = filePath.lastIndexOf(".log");
            String baseName = extensionIndex > 0 ? filePath.substring(0, extensionIndex) : filePath;
            String rotatedFileName = baseName + "-" + timestamp + ".log";

            Path source = Paths.get(filePath);
            Path target = Paths.get(rotatedFileName);

            // Move current file to rotated file
            Files.move(source, target, StandardCopyOption.ATOMIC_MOVE);

            // Create new empty log file
            Files.createFile(source);

            // Update last rotation time
            lastRotationTime = System.currentTimeMillis();

            // Clean up old backup files
            return cleanupOldBackups();
        } catch (IOException e) {
            return ErrorCreator.createError(fromString(
                    "Failed to rotate log file: " + e.getMessage()));
        } finally {
            rotationLock.unlock();
        }
    }

    /**
     * Clean up old backup files based on maxBackupFiles configuration.
     */
    private BError cleanupOldBackups() {
        try {
            File currentFile = new File(filePath);
            File parentDir = currentFile.getParentFile();
            if (parentDir == null) {
                return ErrorCreator.createError(fromString(
                        "Failed to cleanup old backups: Parent directory is null."));
            }

            String fileName = currentFile.getName();
            int logIndex = fileName.lastIndexOf(".log");
            if (logIndex < 0) {
                return ErrorCreator.createError(fromString(
                        "Failed to cleanup old backups: log file name does not contain '.log' extension: "
                                + fileName));
            }
            String baseName = fileName.substring(0, logIndex);

            // Find all rotated backup files
            File[] backupFiles = parentDir.listFiles((dir, name) ->
                    name.startsWith(baseName + "-") && name.endsWith(".log"));

            if (backupFiles == null || backupFiles.length <= maxBackupFiles) {
                // No backups to clean up or already within limit - this is a success condition
                return null;
            }

            // Sort by creation time (oldest first)
            Arrays.sort(backupFiles, Comparator.comparingLong(File::lastModified));

            // Delete oldest files exceeding maxBackupFiles
            int filesToDelete = backupFiles.length - maxBackupFiles;
            List<String> failedDeletions = new ArrayList<>();
            for (int i = 0; i < filesToDelete; i++) {
                try {
                    Files.delete(backupFiles[i].toPath());
                } catch (IOException e) {
                    // Log the error but continue cleanup. Collect failed files and return as BError.
                    failedDeletions.add(backupFiles[i].getName());
                }
            }
            if (!failedDeletions.isEmpty()) {
                return ErrorCreator.createError(fromString(
                        "Failed to delete old backup files: " + String.join(", ", failedDeletions)));
            }
        } catch (Exception e) {
            return ErrorCreator.createError(fromString(
                    "Failed to cleanup old backups: " + e.getMessage()));
        }
        return null;
    }

    /**
     * Remove a LogRotationManager instance from the cache.
     * Useful for testing or when log configuration changes.
     *
     * @param filePath The file path to remove
     */
    public static void removeInstance(String filePath) {
        instances.remove(filePath);
    }

    /**
     * Clear all LogRotationManager instances.
     * Useful for testing.
     */
    public static void clearAllInstances() {
        instances.clear();
    }
}

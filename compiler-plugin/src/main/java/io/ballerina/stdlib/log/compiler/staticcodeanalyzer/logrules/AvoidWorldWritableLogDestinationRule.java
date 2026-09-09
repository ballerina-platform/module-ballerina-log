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

package io.ballerina.stdlib.log.compiler.staticcodeanalyzer.logrules;

import io.ballerina.compiler.syntax.tree.BinaryExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionCallExpressionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.stdlib.log.compiler.staticcodeanalyzer.LogFunctionContext;

import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.log.compiler.staticcodeanalyzer.LogRule.AVOID_WORLD_WRITABLE_LOG_DESTINATION;

/**
 * Rule to detect a log file written into a world-writable directory.
 * <p>
 * Logs routinely capture request details, identifiers and error context, so the log file is a sensitive artefact.
 * A world-writable directory such as {@code /tmp} is readable by every local account, and it also allows another
 * user to create the file first: the service then appends to a file it does not own, which lets that user read the
 * log as it is written, or replace it. Writing logs under a directory the service owns avoids both.
 * <p>
 * Both ways of naming a log file are covered: the deprecated {@code setOutputFile}, and the {@code path} of a file
 * destination in a logger configuration. The module-level {@code destinations} is a configurable and is normally
 * set outside the source, which no source analyzer can see.
 */
public class AvoidWorldWritableLogDestinationRule implements LogFunctionRule {

    private static final String SET_OUTPUT_FILE = "setOutputFile";
    private static final String FROM_CONFIG = "fromConfig";
    private static final String DESTINATIONS_FIELD = "destinations";
    private static final String PATH_FIELD = "path";
    private static final int PATH_POSITION = 0;
    private static final int CONFIG_POSITION = 0;

    /**
     * POSIX paths are compared exactly, because a case-sensitive filesystem treats {@code /TMP} and {@code /tmp}
     * as different directories.
     */
    private static final List<String> POSIX_WORLD_WRITABLE_DIRECTORIES = List.of(
            "/tmp", "/var/tmp", "/dev/shm", "/private/tmp", "/private/var/tmp");

    /**
     * Windows paths are compared case-insensitively, since the filesystem is.
     */
    private static final List<String> WINDOWS_WORLD_WRITABLE_DIRECTORIES = List.of(
            "c:\\windows\\temp", "c:\\temp", "c:/windows/temp", "c:/temp");

    /**
     * Environment variables that name the shared temporary directory. A path built from one of these lands in the
     * same place as a literal {@code /tmp}. The names are matched exactly: on POSIX the environment is
     * case-sensitive, so {@code tmpdir} is a different variable from {@code TMPDIR}.
     */
    private static final Set<String> TEMP_DIRECTORY_VARIABLES = Set.of("TMP", "TEMP", "TMPDIR");

    private static final String OS_MODULE_PREFIX = "os";
    private static final String OS_GET_ENV = "getEnv";

    @Override
    public void analyze(LogFunctionContext context) {
        if (SET_OUTPUT_FILE.equals(context.getFunctionName())) {
            context.getArgument(PATH_POSITION).ifPresent(path -> reportIfWorldWritable(context, path));
            return;
        }
        analyzeConfiguredDestinations(context);
    }

    /**
     * Read the file destinations of a logger configuration.
     * <p>
     * {@code destinations} arrives either inside a positional configuration record or as a named argument, since
     * {@code fromConfig} takes its configuration through an included record parameter.
     */
    private void analyzeConfiguredDestinations(LogFunctionContext context) {
        Optional<ExpressionNode> destinations = context.getNamedArgument(DESTINATIONS_FIELD)
                .or(() -> context.getArgument(CONFIG_POSITION)
                        .filter(MappingConstructorExpressionNode.class::isInstance)
                        .map(MappingConstructorExpressionNode.class::cast)
                        .flatMap(config -> findFieldValue(config, DESTINATIONS_FIELD)));
        if (destinations.isEmpty() || !(destinations.get() instanceof ListConstructorExpressionNode list)) {
            return;
        }
        for (Node destination : list.expressions()) {
            if (destination instanceof MappingConstructorExpressionNode fileDestination) {
                findFieldValue(fileDestination, PATH_FIELD)
                        .ifPresent(path -> reportIfWorldWritable(context, path));
            }
        }
    }

    private void reportIfWorldWritable(LogFunctionContext context, ExpressionNode path) {
        if (isWorldWritablePath(path)) {
            context.reportIssue(path.location(), getRuleId());
        }
    }

    private Optional<ExpressionNode> findFieldValue(MappingConstructorExpressionNode mappingConstructor,
                                                     String fieldName) {
        return mappingConstructor.fields().stream()
                .filter(field -> field.kind() == SyntaxKind.SPECIFIC_FIELD)
                .map(field -> (SpecificFieldNode) field)
                .filter(field -> fieldName.equals(field.fieldName().toSourceCode().trim()))
                .findFirst()
                .flatMap(SpecificFieldNode::valueExpr);
    }

    private boolean isWorldWritablePath(ExpressionNode path) {
        if (namesTemporaryDirectory(path)) {
            return true;
        }
        if (path instanceof BinaryExpressionNode binaryExpression
                && binaryExpression.operator().kind() == SyntaxKind.PLUS_TOKEN
                && binaryExpression.lhsExpr() instanceof ExpressionNode leftOperand
                && continuesWithSeparator(binaryExpression.rhsExpr())) {
            return isWorldWritablePath(leftOperand);
        }
        return getStringLiteralValue(path).map(this::isUnderWorldWritableDirectory).orElse(false);
    }

    /**
     * A literal suffix that does not open with a path separator lands beside the directory rather than inside it,
     * as in {@code "/tmp" + "file.log"} producing {@code /tmpfile.log}. A suffix that cannot be resolved to a
     * literal is assumed to carry its own separator, since every dynamic suffix in this rule's tests is written
     * that way, such as {@code os:getEnv("TMPDIR") + "/application.log"}.
     */
    private boolean continuesWithSeparator(Node rhs) {
        return getStringLiteralValue(rhs)
                .map(value -> value.startsWith("/") || value.startsWith("\\"))
                .orElse(true);
    }

    /**
     * Report a path anchored at a world-writable directory, and only there. A directory whose name merely begins
     * with one, such as {@code /tmpfiles}, is a different directory.
     */
    private boolean isUnderWorldWritableDirectory(String path) {
        String trimmed = path.trim();
        return POSIX_WORLD_WRITABLE_DIRECTORIES.stream().anyMatch(directory -> isUnderPosix(trimmed, directory))
                || WINDOWS_WORLD_WRITABLE_DIRECTORIES.stream()
                        .anyMatch(directory -> isUnderWindows(trimmed.toLowerCase(Locale.ROOT), directory));
    }

    /**
     * POSIX treats a backslash as an ordinary filename character, not a separator, so only a forward slash
     * closes the directory name here.
     */
    private boolean isUnderPosix(String path, String directory) {
        return path.equals(directory) || path.startsWith(directory + "/");
    }

    /**
     * Windows accepts both a backslash and a forward slash as a path separator.
     */
    private boolean isUnderWindows(String path, String directory) {
        return path.equals(directory) || path.startsWith(directory + "/") || path.startsWith(directory + "\\");
    }

    /**
     * Recognise {@code os:getEnv("TMPDIR")} and its variants, which resolve to the shared temporary directory.
     */
    private boolean namesTemporaryDirectory(ExpressionNode expression) {
        if (!(expression instanceof FunctionCallExpressionNode functionCall)
                || !(functionCall.functionName() instanceof QualifiedNameReferenceNode qualifiedName)
                || !OS_MODULE_PREFIX.equals(qualifiedName.modulePrefix().text())
                || !OS_GET_ENV.equals(qualifiedName.identifier().text())
                || functionCall.arguments().isEmpty()) {
            return false;
        }
        return getStringLiteralValue(functionCall.arguments().get(0))
                .map(name -> TEMP_DIRECTORY_VARIABLES.contains(name.trim()))
                .orElse(false);
    }

    /**
     * Extract a string literal's value, decoding an escaped backslash so a Windows path written the way Ballerina
     * requires, such as {@code "C:\\Temp\\file.log"}, is compared against {@link #WINDOWS_WORLD_WRITABLE_DIRECTORIES}
     * in its actual single-backslash form.
     */
    private Optional<String> getStringLiteralValue(Node node) {
        String source = node.toSourceCode().trim();
        if (source.length() >= 2 && source.startsWith("\"") && source.endsWith("\"")) {
            String content = source.substring(1, source.length() - 1);
            return Optional.of(content.replace("\\\\", "\\"));
        }
        return Optional.empty();
    }

    @Override
    public int getRuleId() {
        return AVOID_WORLD_WRITABLE_LOG_DESTINATION.getId();
    }

    @Override
    public boolean isApplicable(LogFunctionContext context) {
        return SET_OUTPUT_FILE.equals(context.getFunctionName())
                || FROM_CONFIG.equals(context.getFunctionName());
    }
}

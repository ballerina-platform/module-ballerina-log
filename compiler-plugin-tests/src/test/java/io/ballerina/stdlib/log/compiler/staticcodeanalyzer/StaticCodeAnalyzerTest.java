/*
 *  Copyright (c) 2025 WSO2 LLC. (http://www.wso2.com).
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
 *  OF ANY KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.log.compiler.staticcodeanalyzer;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import io.ballerina.projects.Project;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.scan.Issue;
import io.ballerina.scan.Rule;
import io.ballerina.scan.Source;
import io.ballerina.scan.test.Assertions;
import io.ballerina.scan.test.TestOptions;
import io.ballerina.scan.test.TestRunner;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

import static io.ballerina.scan.RuleKind.VULNERABILITY;
import static io.ballerina.stdlib.log.compiler.staticcodeanalyzer.LogRule.AVOID_LOGGING_CONFIGURABLE_VARIABLES;
import static java.nio.charset.StandardCharsets.UTF_8;

public class StaticCodeAnalyzerTest {
    private static final Path RESOURCE_PACKAGES_DIRECTORY = Paths
            .get("src", "test", "resources", "static_code_analyzer", "ballerina_packages").toAbsolutePath();
    private static final Path EXPECTED_OUTPUT_DIRECTORY = Paths
            .get("src", "test", "resources", "static_code_analyzer", "expected_output").toAbsolutePath();
    private static final Path JSON_RULES_FILE_PATH = Paths
            .get("../", "compiler-plugin", "src", "main", "resources", "rules.json").toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime");
    private static final String MODULE_BALLERINA_LOG = "module-ballerina-log";

    @Test
    public void validateRulesJson() throws IOException {
        String expectedRules = "[" + Arrays.stream(LogRule.values())
                .map(LogRule::toString).collect(Collectors.joining(",")) + "]";
        String actualRules = Files.readString(JSON_RULES_FILE_PATH);
        assertJsonEqual(actualRules, expectedRules);
    }

    @Test
    public void testStaticCodeRulesWithAPI() throws IOException {
        ByteArrayOutputStream console = new ByteArrayOutputStream();
        PrintStream printStream = new PrintStream(console, true, UTF_8);

        for (LogRule rule : LogRule.values()) {
            testIndividualRule(rule, console, printStream);
        }
    }

    private void testIndividualRule(LogRule rule, ByteArrayOutputStream console, PrintStream printStream)
            throws IOException {
        String targetPackageName = "rule" + rule.getId();
        Path targetPackagePath = RESOURCE_PACKAGES_DIRECTORY.resolve(targetPackageName);

        TestRunner testRunner = setupTestRunner(targetPackagePath, printStream);
        testRunner.performScan();

        validateRules(testRunner.getRules());
        validateIssues(rule, testRunner.getIssues());
        validateOutput(console, targetPackageName);

        console.reset();
    }

    private TestRunner setupTestRunner(Path targetPackagePath, PrintStream printStream) {
        Project project = BuildProject.load(getEnvironmentBuilder(), targetPackagePath);
        TestOptions options = TestOptions.builder(project).setOutputStream(printStream).build();
        return new TestRunner(options);
    }

    private void validateRules(List<Rule> rules) {
        Assertions.assertRule(
                rules,
                "ballerina/log:1",
                AVOID_LOGGING_CONFIGURABLE_VARIABLES.getDescription(),
                VULNERABILITY);
    }

    private void validateIssues(LogRule rule, List<Issue> issues) {
        switch (rule) {
            case AVOID_LOGGING_CONFIGURABLE_VARIABLES:
                Assert.assertEquals(issues.size(), 9);
                Assertions.assertIssue(issues, 0, "ballerina/log:1", "main.bal",
                        20, 20, Source.BUILT_IN);
                Assertions.assertIssue(issues, 1, "ballerina/log:1", "main.bal",
                        21, 21, Source.BUILT_IN);
                Assertions.assertIssue(issues, 2, "ballerina/log:1", "main.bal",
                        22, 22, Source.BUILT_IN);
                Assertions.assertIssue(issues, 3, "ballerina/log:1", "main.bal",
                        23, 23, Source.BUILT_IN);
                Assertions.assertIssue(issues, 4, "ballerina/log:1", "main.bal",
                        24, 24, Source.BUILT_IN);
                Assertions.assertIssue(issues, 5, "ballerina/log:1", "main.bal",
                        25, 25, Source.BUILT_IN);
                Assertions.assertIssue(issues, 6, "ballerina/log:1", "main.bal",
                        25, 25, Source.BUILT_IN);
                Assertions.assertIssue(issues, 7, "ballerina/log:1", "main.bal",
                        26, 26, Source.BUILT_IN);
                Assertions.assertIssue(issues, 8, "ballerina/log:1", "main.bal",
                        26, 26, Source.BUILT_IN);
                break;
            default:
                Assert.fail("Unhandled rule in validateIssues: " + rule);
                break;
        }
    }

    private void validateOutput(ByteArrayOutputStream console, String targetPackageName) throws IOException {
        String output = console.toString(UTF_8);
        String jsonOutput = extractJson(output);
        String expectedOutput = Files.readString(EXPECTED_OUTPUT_DIRECTORY.resolve(targetPackageName + ".json"));
        assertJsonEqual(jsonOutput, expectedOutput);
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private String extractJson(String consoleOutput) {
        int startIndex = consoleOutput.indexOf("[");
        int endIndex = consoleOutput.lastIndexOf("]");
        if (startIndex == -1 || endIndex == -1) {
            return "";
        }
        return consoleOutput.substring(startIndex, endIndex + 1);
    }

    private void assertJsonEqual(String actual, String expected) {
        Assert.assertEquals(normalizeString(actual), normalizeString(expected));
    }

    private static String normalizeString(String json) {
        try {
            ObjectMapper mapper = new ObjectMapper().configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true);
            JsonNode node = mapper.readTree(json);
            String normalizedJson = mapper.writeValueAsString(node)
                    .replaceAll(":\".*" + MODULE_BALLERINA_LOG, ":\"" + MODULE_BALLERINA_LOG);
            return isWindows() ? normalizedJson.replace("/", "\\\\") : normalizedJson;
        } catch (Exception ignore) {
            return json;
        }
    }

    private static boolean isWindows() {
        return System.getProperty("os.name").toLowerCase(Locale.ENGLISH).startsWith("windows");
    }
}

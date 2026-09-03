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

package io.ballerina.stdlib.log.compiler.staticcodeanalyzer;

import io.ballerina.compiler.syntax.tree.FunctionCallExpressionNode;
import io.ballerina.compiler.syntax.tree.ImportDeclarationNode;
import io.ballerina.compiler.syntax.tree.ImportOrgNameNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

/**
 * Analyzes calls into the {@code ballerina/log} module.
 * <p>
 * Registered on the call expression rather than the call statement, so a result that is bound or checked is seen as
 * readily as one that is discarded.
 */
public class LogFunctionCallAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private static final String LOG_MODULE = "log";
    private static final String BALLERINA_ORG = "ballerina";

    private final Reporter reporter;
    private final LogFunctionRulesEngine rulesEngine;

    public LogFunctionCallAnalyzer(Reporter reporter) {
        this.reporter = reporter;
        this.rulesEngine = new LogFunctionRulesEngine();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (!(context.node() instanceof FunctionCallExpressionNode functionCall)) {
            return;
        }
        Document document = context.currentPackage().module(context.moduleId()).document(context.documentId());
        Optional<String> functionName = getLogFunctionName(functionCall, collectLogPrefixes(document));
        if (functionName.isEmpty()) {
            return;
        }
        rulesEngine.executeRules(new LogFunctionContext(reporter, document, functionName.get(), functionCall));
    }

    private Optional<String> getLogFunctionName(FunctionCallExpressionNode functionCall, Set<String> logPrefixes) {
        if (!(functionCall.functionName() instanceof QualifiedNameReferenceNode qualifiedName)) {
            return Optional.empty();
        }
        if (!logPrefixes.contains(qualifiedName.modulePrefix().text())) {
            return Optional.empty();
        }
        return Optional.of(qualifiedName.identifier().text());
    }

    /**
     * Collect every prefix the {@code ballerina/log} module is imported under in the document being analyzed.
     */
    private Set<String> collectLogPrefixes(Document document) {
        Set<String> prefixes = new HashSet<>();
        if (!(document.syntaxTree().rootNode() instanceof ModulePartNode modulePart)) {
            return prefixes;
        }
        for (ImportDeclarationNode importDeclaration : modulePart.imports()) {
            Optional<ImportOrgNameNode> orgName = importDeclaration.orgName();
            boolean isLogImport = orgName.isPresent() && BALLERINA_ORG.equals(orgName.get().orgName().text())
                    && importDeclaration.moduleName().stream().anyMatch(name -> LOG_MODULE.equals(name.text()));
            if (isLogImport) {
                prefixes.add(importDeclaration.prefix().map(prefix -> prefix.prefix().text()).orElse(LOG_MODULE));
            }
        }
        return prefixes;
    }
}

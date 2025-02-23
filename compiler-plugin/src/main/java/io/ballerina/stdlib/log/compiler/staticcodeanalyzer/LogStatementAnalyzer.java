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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.VariableSymbol;
import io.ballerina.compiler.syntax.tree.BinaryExpressionNode;
import io.ballerina.compiler.syntax.tree.ChildNodeEntry;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionStatementNode;
import io.ballerina.compiler.syntax.tree.InterpolationNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.TemplateExpressionNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static io.ballerina.stdlib.log.compiler.staticcodeanalyzer.LogRule.AVOID_LOGGING_CONFIGURABLE_VARIABLES;

/**
 * This class analyzes the log statements and checks if the log statement is logging a configurable variable.
 *
 * @since 2.12.0
 */
public class LogStatementAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {

    public static final String CONFIGURABLE_QUALIFIER = "CONFIGURABLE";
    public static final String LOG_MODULE_PREFIX = "log";

    final List<String> logFunctions = Arrays.asList("printInfo", "printDebug", "printError", "printWarn");

    List<SemanticModel> semanticModels = new ArrayList<>();

    Document document = null;

    private final Reporter reporter;

    public LogStatementAnalyzer(Reporter reporter) {
        this.reporter = reporter;
    }
    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        // If semantic model is empty, we get semantic models of all the modules in the package and save it in a list
        if (semanticModels.isEmpty()) {
            context.currentPackage().modules().forEach(module -> {
                SemanticModel semanticModel = module.getCompilation().getSemanticModel();
                semanticModels.add(semanticModel);
            });
        }

        // If the document is null, we get the document of the context
        if (document == null) {
            document = context.currentPackage().module(context.moduleId()).document(context.documentId());
        }

        if (context.node() instanceof ExpressionStatementNode expressionStatementNode) {
            // Check if the log statement has a configurable qualifier
            List<ChildNodeEntry> childlist = expressionStatementNode.expression().childEntries().stream()
                    .toList();

            if (childlist.size() < 4) {
                return;
            }

            Node firstChild = childlist.getFirst().node().orElse(null);
            if (firstChild instanceof QualifiedNameReferenceNode qualifiedNameReferenceNode
                    && qualifiedNameReferenceNode.modulePrefix().text().equals(LOG_MODULE_PREFIX)
                    && logFunctions.contains(qualifiedNameReferenceNode.identifier().text())) {

                // The argument of the log function is the third child. second and fourth child are the parentheses
                NodeList<Node> logArgumentNodeList = childlist.get(2).nodeList();
                // collect all the log function arguments.
                List<Node> list = logArgumentNodeList.stream().filter(node -> node instanceof PositionalArgumentNode ||
                                node instanceof NamedArgumentNode)
                        .toList();

                for (Node node : list) {
                    if (node instanceof PositionalArgumentNode positionalArgumentNode) {
                        positionalArgumentNode.childEntries().forEach(childNodeEntry -> {
                            Node expression = childNodeEntry.node().orElse(null);
                            if (expression instanceof SimpleNameReferenceNode simpleNameReferenceNode) {
                                checkConfigurableQualifier(simpleNameReferenceNode);
                            } else if (expression instanceof TemplateExpressionNode templateExpressionNode) {
                                templateExpressionNode.content().forEach(content -> {
                                    if (content instanceof InterpolationNode interpolationNode) {
                                        interpolationNode.childEntries().forEach(interpolationChild -> {
                                            Node interpolationExpression = interpolationChild.node().orElse(null);
                                            if (interpolationExpression instanceof SimpleNameReferenceNode
                                                    simpleNameReferenceNode) {
                                                checkConfigurableQualifier(simpleNameReferenceNode);
                                            }
                                        });
                                    }
                                });
                            } else if (expression instanceof BinaryExpressionNode binaryExpressionNode) {
                                binaryExpressionNode.childEntries().forEach(childEntry -> {
                                    Node childNode = childEntry.node().orElse(null);
                                    if (childNode instanceof SimpleNameReferenceNode simpleNameReferenceNode) {
                                        checkConfigurableQualifier(simpleNameReferenceNode);
                                    }
                                });
                            }
                        });
                    } else if (node instanceof NamedArgumentNode namedArgumentNode) {
                        checkConfigurableQualifier(namedArgumentNode.expression());
                    }
                }
            }
        }
    }

    private void checkConfigurableQualifier(ExpressionNode argumentNode) {
        semanticModels.forEach(semanticModel -> {
            Symbol symbol = semanticModel.symbol(argumentNode).orElse(null);
            if (symbol instanceof VariableSymbol variableSymbol) {
                variableSymbol.qualifiers().stream().filter(qualifier -> qualifier
                        .toString().equals(CONFIGURABLE_QUALIFIER)).forEach(qualifier -> {
                    this.reporter.reportIssue(document,
                            argumentNode.location(),
                            AVOID_LOGGING_CONFIGURABLE_VARIABLES.getId());
                });
            }
        });
    }
}

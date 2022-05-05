/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.log.plugin;

import io.ballerina.compiler.syntax.tree.AbstractNodeFactory;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.FunctionCallExpressionNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.TreeModifier;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.plugins.CodeModifier;
import io.ballerina.projects.plugins.CodeModifierContext;

import java.util.ArrayList;
import java.util.List;

/**
 * log module code modifier.
 */
public class LogCodeModifier extends CodeModifier {

    @Override
    public void init(CodeModifierContext modifierContext) {
        modifierContext.addSourceModifierTask(sourceModifierContext -> {

            Package pkg = sourceModifierContext.currentPackage();

            for (ModuleId moduleId : pkg.moduleIds()) {
                Module module = pkg.module(moduleId);
                String moduleName = module.moduleName().toString().equals(".") ?
                        "" : pkg.packageOrg().toString() + "/" + module.moduleName().toString();

                for (DocumentId documentId : module.documentIds()) {
                    sourceModifierContext.modifySourceFile(getUpdatedSyntaxTree(
                            module, documentId, moduleName).textDocument(), documentId);
                }
                for (DocumentId documentId : module.testDocumentIds()) {
                    sourceModifierContext.modifyTestSourceFile(getUpdatedSyntaxTree(
                            module, documentId, moduleName).textDocument(), documentId);
                }
            }
        });
    }

    private SyntaxTree getUpdatedSyntaxTree(Module module, DocumentId documentId, String moduleName) {

        Document document = module.document(documentId);
        ModulePartNode rootNode = document.syntaxTree().rootNode();

        FunctionCallModifier functionCallModifier = new FunctionCallModifier(moduleName);
        ModulePartNode newRoot = (ModulePartNode) rootNode.apply(functionCallModifier);

        ModulePartNode newModulePart = rootNode.modify(rootNode.imports(), newRoot.members(), rootNode.eofToken());
        return document.syntaxTree().modifyWith(newModulePart);
    }

    private static class FunctionCallModifier extends TreeModifier {

        String moduleName;

        public FunctionCallModifier(String moduleName) {
            this.moduleName = moduleName;
        }

        @Override
        public FunctionCallExpressionNode transform(FunctionCallExpressionNode functionCall) {

            if (functionCall.functionName().toString().trim().equals("log:printError") ||
                    functionCall.functionName().toString().trim().equals("log:printWarn") ||
                    functionCall.functionName().toString().trim().equals("log:printInfo") ||
                    functionCall.functionName().toString().trim().equals("log:printDebug")) {

                List<Node> arguments = new ArrayList<>();
                for (FunctionArgumentNode arg: functionCall.arguments()) {
                    if (arguments.size() > 0) {
                        arguments.add(AbstractNodeFactory.createIdentifierToken(","));
                    }
                    arguments.add(arg);
                }
                NamedArgumentNode moduleName = NodeFactory.createNamedArgumentNode(
                        NodeFactory.createSimpleNameReferenceNode(
                                AbstractNodeFactory.createIdentifierToken("module")
                        ),
                        AbstractNodeFactory.createIdentifierToken("="),
                        NodeFactory.createBasicLiteralNode(
                                SyntaxKind.STRING_LITERAL,
                                AbstractNodeFactory.createIdentifierToken("\"" + this.moduleName + "\"")
                        )
                );
                arguments.add(AbstractNodeFactory.createIdentifierToken(","));
                arguments.add(moduleName);

                return NodeFactory.createFunctionCallExpressionNode(
                        NodeFactory.createSimpleNameReferenceNode(
                                AbstractNodeFactory.createIdentifierToken(functionCall.functionName().toString())
                        ),
                        AbstractNodeFactory.createIdentifierToken("("),
                        NodeFactory.createSeparatedNodeList(arguments),
                        AbstractNodeFactory.createIdentifierToken(")")
                );
            }
            return functionCall;
        }
    }
}

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
import io.ballerina.compiler.syntax.tree.NameReferenceNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.TreeModifier;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectKind;
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

                String moduleName = module.project().kind() == ProjectKind.SINGLE_FILE_PROJECT ?
                        "" : module.descriptor().org().toString() + "/" + module.descriptor().name().toString();

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

        return document.syntaxTree().modifyWith(newRoot);
    }

    private static class FunctionCallModifier extends TreeModifier {

        String moduleName;

        public FunctionCallModifier(String moduleName) {
            this.moduleName = moduleName;
        }

        @Override
        public FunctionCallExpressionNode transform(FunctionCallExpressionNode functionCall) {

            NameReferenceNode nameRef = functionCall.functionName();
            if (nameRef.kind() != SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                return functionCall;
            }

            QualifiedNameReferenceNode qualifiedNameRef = (QualifiedNameReferenceNode) nameRef;
            if (!qualifiedNameRef.modulePrefix().text().equals("log")) {
                return functionCall;
            }

            String text = qualifiedNameRef.identifier().text();
            if (!text.equals("printError") && !text.equals("printWarn") && !text.equals("printInfo") &&
                    !text.equals("printDebug")) {
                return functionCall;
            }

            List<Node> arguments = new ArrayList<>();
            for (FunctionArgumentNode arg: functionCall.arguments()) {
                if (arguments.size() > 0) {
                    arguments.add(NodeFactory.createToken(SyntaxKind.COMMA_TOKEN));
                }
                arguments.add(arg);
            }
            NamedArgumentNode moduleName = NodeFactory.createNamedArgumentNode(
                    NodeFactory.createSimpleNameReferenceNode(
                            AbstractNodeFactory.createIdentifierToken("module")
                    ),
                    NodeFactory.createToken(SyntaxKind.EQUAL_TOKEN),
                    NodeFactory.createBasicLiteralNode(
                            SyntaxKind.STRING_LITERAL,
                            AbstractNodeFactory.createLiteralValueToken(
                                    SyntaxKind.STRING_LITERAL_TOKEN,
                                    "\"" + this.moduleName + "\"",
                                    AbstractNodeFactory.createEmptyMinutiaeList(),
                                    AbstractNodeFactory.createEmptyMinutiaeList()
                            )
                    )
            );
            if (arguments.size() > 0) {
                arguments.add(NodeFactory.createToken(SyntaxKind.COMMA_TOKEN));
            }
            arguments.add(moduleName);

            return functionCall.modify().withArguments(NodeFactory.createSeparatedNodeList(arguments)).apply();
        }
    }
}

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
import io.ballerina.compiler.syntax.tree.InterpolationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TemplateExpressionNode;
import io.ballerina.stdlib.log.compiler.staticcodeanalyzer.LogFunctionContext;

import java.util.Set;

import static io.ballerina.stdlib.log.compiler.staticcodeanalyzer.LogRule.AVOID_LOGGING_CONFIGURABLE_VARIABLES;

/**
 * Rule to detect a configurable variable passed to a log statement.
 * <p>
 * Configurable variables carry the values supplied at deployment, which is where credentials, tokens and connection
 * secrets live. A log statement moves the value out of the deployment configuration and into the log store, where
 * it is retained and readable by a far wider set of people than can read the configuration itself.
 * <p>
 * Every argument of the call is checked, not just the message: a secret handed through the open {@code KeyValues}
 * key/value pairs is logged just as durably as one embedded in the message text.
 */
public class AvoidLoggingConfigurableVariablesRule implements LogFunctionRule {

    private static final Set<String> LOG_FUNCTIONS = Set.of("printDebug", "printInfo", "printWarn", "printError");

    @Override
    public void analyze(LogFunctionContext context) {
        for (ExpressionNode argument : context.getArguments()) {
            reportConfigurableValues(context, argument);
        }
    }

    /**
     * Report a configurable reached directly, through a string template interpolation, or through concatenation.
     */
    private void reportConfigurableValues(LogFunctionContext context, ExpressionNode argument) {
        if (argument instanceof TemplateExpressionNode template) {
            for (Node content : template.content()) {
                if (content instanceof InterpolationNode interpolation) {
                    reportConfigurableValues(context, interpolation.expression());
                }
            }
            return;
        }
        if (argument instanceof BinaryExpressionNode binaryExpression
                && binaryExpression.operator().kind() == SyntaxKind.PLUS_TOKEN) {
            // String concatenation builds the logged value from both operands, so each is checked in turn;
            // this also unwinds a chain such as "a" + b + c, since its left operand is itself a BinaryExpressionNode.
            reportConfigurableOperand(context, binaryExpression.lhsExpr());
            reportConfigurableOperand(context, binaryExpression.rhsExpr());
            return;
        }
        // Any other expression is offered to the symbol lookup as it stands, so a reference qualified with a
        // module prefix is read the same way as a plain one.
        reportIfConfigurable(context, argument);
    }

    private void reportConfigurableOperand(LogFunctionContext context, Node operand) {
        if (operand instanceof ExpressionNode expression) {
            reportConfigurableValues(context, expression);
        }
    }

    private void reportIfConfigurable(LogFunctionContext context, ExpressionNode expression) {
        if (context.isConfigurable(expression)) {
            context.reportIssue(expression.location(), getRuleId());
        }
    }

    @Override
    public int getRuleId() {
        return AVOID_LOGGING_CONFIGURABLE_VARIABLES.getId();
    }

    @Override
    public boolean isApplicable(LogFunctionContext context) {
        return LOG_FUNCTIONS.contains(context.getFunctionName());
    }
}

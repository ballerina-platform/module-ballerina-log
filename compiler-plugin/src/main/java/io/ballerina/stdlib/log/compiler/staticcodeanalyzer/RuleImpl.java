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

import io.ballerina.scan.Rule;
import io.ballerina.scan.RuleKind;

/**
 * {@code RuleFactory} contains the logic to create a {@link Rule}.
 *
 * @since 2.12.0
 */
class RuleImpl implements Rule {
    private final int id;
    private final String description;
    private final RuleKind kind;

    RuleImpl(int id, String description, RuleKind kind) {
        this.id = id;
        this.description = description;
        this.kind = kind;
    }

    @Override
    public String id() {
        return Integer.toString(this.id);
    }

    @Override
    public int numericId() {
        return this.id;
    }

    @Override
    public String description() {
        return this.description;
    }

    @Override
    public RuleKind kind() {
        return this.kind;
    }
}

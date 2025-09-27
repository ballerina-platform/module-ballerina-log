// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;

isolated function maskStringPartially(string input) returns string {
    int len = input.length();
    if len <= 6 {
        return "******";
    }
    string maskedString = input.substring(0, 3);
    foreach int i in 3 ... len - 4 {
        maskedString += "*";
    }
    maskedString += input.substring(len - 3);
    return maskedString;
};

function checkJsonParsing(string maskedStr) {
    map<json>|error parsedJson = maskedStr.fromJsonStringWithType();
    test:assertTrue(parsedJson is map<json>);
}

type User record {|
    string name;
    @SensitiveData
    string ssn;
    @SensitiveData {strategy: {replacement: "*****"}}
    string password;
    @SensitiveData {strategy: {replacement: maskStringPartially}}
    string mail;
    @SensitiveData {strategy: EXCLUDE}
    string creditCard;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedString() {
    User user = {
        name: "John Doe",
        ssn: "123-45-6789",
        password: "password123",
        mail: "john.doe@example.com",
        creditCard: "4111-1111-1111-1111"
    };
    string maskedUserStr = toMaskedString(user);
    string expectedStr = string `{"name":"John Doe","password":"*****","mail":"joh**************com"}`;
    test:assertEquals(maskedUserStr, expectedStr);
}

type RecordWithAnydataValues record {|
    string str;
    int|float num;
    boolean bool;
    map<json> jsonMap;
    table<map<string>> tableData;
    anydata[] arr;
    xml xmlRaw;
    xml:Text xmlText;
    [int, float, string] tuple;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithAnydataValues() {
    RecordWithAnydataValues anydataRec = {
        str: "Test String",
        num: 123.45,
        bool: true,
        jsonMap: {key1: "value1", key2: 2},
        tableData: table [
            {col1: "row1col1", col2: "row1col2"},
            {col1: "row2col1", col2: "row2col2"}
        ],
        arr: ["elem1", 2, {key: "value"}],
        xmlRaw: xml `<note><to>User</to><from>Admin</from><heading>Reminder</heading><body>Don't forget the meeting!</body></note>`,
        xmlText: xml `Just some text`,
        tuple: [1, 2.5, "three"]
    };
    string maskedAnydataRecStr = toMaskedString(anydataRec);
    string expectedStr = string `{"str":"Test String","num":123.45,"bool":true,"jsonMap":{"key1":"value1","key2":2},"tableData":[{"col1":"row1col1","col2":"row1col2"},{"col1":"row2col1","col2":"row2col2"}],"arr":["elem1",2,{"key":"value"}],"xmlRaw":"<note><to>User</to><from>Admin</from><heading>Reminder</heading><body>Don't forget the meeting!</body></note>","xmlText":"Just some text","tuple":[1,2.5,"three"]}`;
    test:assertEquals(maskedAnydataRecStr, expectedStr);
    checkJsonParsing(maskedAnydataRecStr);
}

type OpenAnydataRecord record {
    string name;
    @SensitiveData
    anydata sensitiveField;
};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithOpenAnydataRecord() {
    OpenAnydataRecord fieldRec = {
        name: "Field Record",
        sensitiveField: "Sensitive Data",
        "extraField": "extraValue"
    };

    OpenAnydataRecord openRec = {
        name: "Open Record",
        sensitiveField: {key1: "value1", key2: 2, key3: true},
        "extraField": "extraValue",
        "extraMapField": {mapKey: "mapValue"},
        "extraArrayField": [1, "two", 3.0],
        "extraRecordField": fieldRec
    };
    string maskedOpenRecStr = toMaskedString(openRec);
    string expectedStr = string `{"name":"Open Record","extraField":"extraValue","extraMapField":{"mapKey":"mapValue"},"extraArrayField":[1,"two",3.0],"extraRecordField":{"name":"Field Record","extraField":"extraValue"}}`;
    test:assertEquals(maskedOpenRecStr, expectedStr);
    checkJsonParsing(maskedOpenRecStr);
}

type Record1 record {|
    string field1;
    @SensitiveData
    Record2 field2;
    Record2 field3;
|};

type Record2 record {|
    string subField1;
    @SensitiveData {strategy: {replacement: "###"}}
    string subField2;
    @SensitiveData {strategy: {replacement: maskStringPartially}}
    string subField3;
    @SensitiveData {strategy: EXCLUDE}
    string subField4;
|};

type Record3 record {|
    string info;
    @SensitiveData
    string details;
|};

type NestedRecord record {|
    string name;
    @SensitiveData
    Record1 details1;
    Record1 details2;
    Record3[] records;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithNestedRecords() {
    NestedRecord nestedRec = {
        name: "Nested Record",
        details1: {
            field1: "Field1 Value",
            field2: {
                subField1: "SubField1 Value",
                subField2: "SubField2 Value",
                subField3: "SubField3 Value",
                subField4: "SubField4 Value"
            },
            field3: {
                subField1: "SubField1 Value",
                subField2: "SubField2 Value",
                subField3: "SubField3 Value",
                subField4: "SubField4 Value"
            }
        },
        details2: {
            field1: "Field1 Value",
            field2: {
                subField1: "SubField1 Value",
                subField2: "SubField2 Value",
                subField3: "SubField3 Value",
                subField4: "SubField4 Value"
            },
            field3: {
                subField1: "SubField1 Value",
                subField2: "SubField2 Value",
                subField3: "SubField3 Value",
                subField4: "SubField4 Value"
            }
        },
        records: [
            {info: "Record1 Info", details: "Record1 Details"},
            {info: "Record2 Info", details: "Record2 Details"}
        ]
    };
    string maskedNestedRecStr = toMaskedString(nestedRec);
    string expectedStr = string `{"name":"Nested Record","details2":{"field1":"Field1 Value","field3":{"subField1":"SubField1 Value","subField2":"###","subField3":"Sub*********lue"}},"records":[{"info":"Record1 Info"},{"info":"Record2 Info"}]}`;
    test:assertEquals(maskedNestedRecStr, expectedStr);
    checkJsonParsing(maskedNestedRecStr);
}

type NilableSensitiveFieldRecord record {|
    string name;
    @SensitiveData
    string? sensitiveField;
    int? id;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithNilableSensitiveField() {
    NilableSensitiveFieldRecord recWithNil = {
        name: "Nilable Record",
        sensitiveField: (),
        id: null
    };
    string maskedRecWithNilStr = toMaskedString(recWithNil);
    string expectedStr = string `{"name":"Nilable Record","id":null}`;
    test:assertEquals(maskedRecWithNilStr, expectedStr);
    checkJsonParsing(maskedRecWithNilStr);
}

type OptionalSensitiveFieldRecord record {|
    string name;
    @SensitiveData
    string sensitiveField?;
    int id?;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithOptionalSensitiveField() {
    OptionalSensitiveFieldRecord recWithOptional = {
        name: "Optional Record",
        id: 101
    };
    string maskedRecWithOptionalStr = toMaskedString(recWithOptional);
    string expectedStr = string `{"name":"Optional Record","id":101}`;
    test:assertEquals(maskedRecWithOptionalStr, expectedStr);
    checkJsonParsing(maskedRecWithOptionalStr);

    recWithOptional.sensitiveField = "Sensitive Data";
    string maskedRecWithOptionalSetStr = toMaskedString(recWithOptional);
    test:assertEquals(maskedRecWithOptionalSetStr, expectedStr);
    checkJsonParsing(maskedRecWithOptionalSetStr);

    recWithOptional.id = ();
    string maskedRecWithOptionalSetNilStr = toMaskedString(recWithOptional);
    string expectedStrWithoutId = string `{"name":"Optional Record"}`;
    test:assertEquals(maskedRecWithOptionalSetNilStr, expectedStrWithoutId);
    checkJsonParsing(maskedRecWithOptionalSetNilStr);
}

type NeverSensitiveFieldRecord record {|
    string name;
    @SensitiveData
    never sensitiveField?;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithNeverSensitiveField() {
    NeverSensitiveFieldRecord rec = {
        name: "Never Record",
        sensitiveField: ()
    };
    string maskedRecStr = toMaskedString(rec);
    string expectedStr = string `{"name":"Never Record"}`;
    test:assertEquals(maskedRecStr, expectedStr);
    checkJsonParsing(maskedRecStr);
}

type RecordWithRestField record {|
    string name;
    @SensitiveData
    string sensitiveField;
    string...;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithRestField() {
    RecordWithRestField rec = {
        name: "Rest Field Record",
        sensitiveField: "Sensitive Data",
        "extraField1": "extraValue1",
        "extraField2": "extraValue2"
    };
    string maskedRecStr = toMaskedString(rec);
    string expectedStr = string `{"name":"Rest Field Record","extraField1":"extraValue1","extraField2":"extraValue2"}`;
    test:assertEquals(maskedRecStr, expectedStr);
    checkJsonParsing(maskedRecStr);
}

type CyclicRecord record {|
    string name;
    CyclicRecord child?;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithCyclicRecord() {
    CyclicRecord rec = {
        name: "name"
    };
    rec.child = rec;
    string|error maskedRecStr = trap toMaskedString(rec);
    if maskedRecStr is string {
        test:assertFail("Expected an error due to cyclic value reference, but got a string");
    }
    test:assertEquals(maskedRecStr.message(), "Cyclic value reference detected in the record");
}

type RecordWithCyclicSensitiveField record {|
    string name;
    @SensitiveData
    RecordWithCyclicSensitiveField child?;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithCyclicSensitiveField() {
    RecordWithCyclicSensitiveField rec = {
        name: "name"
    };
    rec.child = rec;
    string maskedRecStr = toMaskedString(rec);
    string expectedStr = string `{"name":"name"}`;
    test:assertEquals(maskedRecStr, expectedStr);
    checkJsonParsing(maskedRecStr);
}

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithMap() {
    map<json> jsonMap = {
        key1: "value1",
        key2: 2,
        key3: true,
        key4: {nestedKey: "nestedValue"},
        key5: [1, "two", 3.0]
    };
    string maskedMapStr = toMaskedString(jsonMap);
    string expectedStr = string `{"key1":"value1","key2":2,"key3":true,"key4":{"nestedKey":"nestedValue"},"key5":[1,"two",3.0]}`;
    test:assertEquals(maskedMapStr, expectedStr);
    checkJsonParsing(maskedMapStr);

    User user = {
        name: "John Doe",
        ssn: "123-45-6789",
        password: "password123",
        mail: "john.doe@example.com",
        creditCard: "4111-1111-1111-1111"
    };
    map<json> mapWithSensitiveData = {
        normalKey: "normalValue",
        sensitiveKey: user
    };
    string maskedMapWithSensitiveDataStr = toMaskedString(mapWithSensitiveData);
    string expectedMapWithSensitiveDataStr = string `{"normalKey":"normalValue","sensitiveKey":{"name":"John Doe","password":"*****","mail":"joh**************com"}}`;
    test:assertEquals(maskedMapWithSensitiveDataStr, expectedMapWithSensitiveDataStr);
    checkJsonParsing(maskedMapWithSensitiveDataStr);
}

type SpecialCharFieldsRec record {|
    string field_with_underscores;
    string FieldWithCamelCase;
    string field\-With\$pecialChar\!;
    string 'type;
    string 'value\\\-Field;
|};

type SpecialCharSensitiveFieldsRec record {|
    @SensitiveData {strategy: {replacement: "*****"}}
    string field_with_underscores;
    @SensitiveData {strategy: {replacement: "#####"}}
    string FieldWithCamelCase;
    @SensitiveData {strategy: {replacement: "1!1!1!"}}
    string field\-With\$pecialChar\!;
    @SensitiveData {strategy: {replacement: "[REDACTED]"}}
    string 'type;
    @SensitiveData {strategy: {replacement: "~~~~~~"}}
    string 'value\\\-Field;
|};

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithSpecialCharFieldsAndSpecialCharValues() {
    SpecialCharFieldsRec rec = {
        field_with_underscores: "\"value1\",\"value2\"",
        FieldWithCamelCase: "value2",
        field\-With\$pecialChar\!: "value3 & 'value4' <value5>",
        'type: "exampleType\n\t",
        'value\\\-Field: "value"
    };
    string maskedRecStr = toMaskedString(rec);
    string expectedStr = string `{"field_with_underscores":"\"value1\",\"value2\"","FieldWithCamelCase":"value2","field-With$pecialChar!":"value3 & 'value4' <value5>","type":"exampleType\n\t","value\\-Field":"value"}`;
    test:assertEquals(maskedRecStr, expectedStr);
    checkJsonParsing(maskedRecStr);
}

@test:Config {
    groups: ["maskedString"]
}
function testMaskedStringWithSpecialCharFields() {
    SpecialCharSensitiveFieldsRec rec = {
        field_with_underscores: "\"value1\",\"value2\"",
        FieldWithCamelCase: "value2",
        field\-With\$pecialChar\!: "value3 & 'value4' <value5>",
        'type: "exampleType\n\t",
        'value\\\-Field: "value"
    };
    string maskedRecStr = toMaskedString(rec);
    string expectedStr = string `{"field_with_underscores":"*****","FieldWithCamelCase":"#####","field-With$pecialChar!":"1!1!1!","type":"[REDACTED]","value\\-Field":"~~~~~~"}`;
    test:assertEquals(maskedRecStr, expectedStr);
    checkJsonParsing(maskedRecStr);
}

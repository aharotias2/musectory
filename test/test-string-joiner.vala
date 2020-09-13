int main(string[] args) {
    test01();
    test02();
    test03();
    test04();
    test05();
    test06();
    return 0;
}

void test01() {
    string[] values = { "a", "b", "c", "d" };
    Tatam.StringJoiner tester = new Tatam.StringJoiner(", ", "[", "]");
    foreach (string value in values) {
        tester.add(value);
    }
    print(tester.to_string());
    print("\n");
}

void test02() {
    string[] values = { "a" };
    Tatam.StringJoiner tester = new Tatam.StringJoiner(", ", "[", "]");
    foreach (string value in values) {
        tester.add(value);
    }
    print(tester.to_string());
    print("\n");
}

void test03() {
    string[] values = {};
    Tatam.StringJoiner tester = new Tatam.StringJoiner(", ", "[", "]");
    foreach (string value in values) {
        tester.add(value);
    }
    print(tester.to_string());
    print("\n");
}

void test04() {
    string[] values = { "a", "b", "c", "d" };
    Tatam.StringJoiner tester = new Tatam.StringJoiner();
    foreach (string value in values) {
        tester.add(value);
    }
    print(tester.to_string());
    print("\n");
}

void test05() {
    string[] values = { "a", "b", "c", "d" };
    Tatam.StringJoiner tester = new Tatam.StringJoiner(null, "\"", "\"");
    foreach (string value in values) {
        tester.add(value);
    }
    print(tester.to_string());
    print("\n");
}

void test06() {
    string[] values = { "a", "b", "c", "d" };
    Tatam.StringJoiner tester = new Tatam.StringJoiner(" & ");
    foreach (string value in values) {
        tester.add(value);
    }
    print(tester.to_string());
    print("\n");
}

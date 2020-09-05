const string TIME_PATTERN = "^([0-9]*:)?([0-5]?[0-9]:)?[0-5]?[0-9](\\.[0-5])?$";
Regex time_regex;

int main(string[] args) {
    try {
        time_regex = new Regex(TIME_PATTERN);
        test("4:20:30.555");
        test("1:20:30.5");
        test("20:30.5");
        test("20:30", Tatam.SmallTime.FormatType.HOURS_MINUTES_SECONDS_DECISECONDS);
        test("2:30");
        test("2:03", Tatam.SmallTime.FormatType.HOURS_MINUTES_SECONDS_DECISECONDS);
        test("2:63");
        test("2:03.1");
        test("30.5", Tatam.SmallTime.FormatType.MINUTES_SECONDS_DECISECONDS);
        test("5");
        return 0;
    } catch (RegexError e) {
        stderr.printf(@"RegexError: $(e.message)\n");
        return 1;
    }
}

void test(string testee, Tatam.SmallTime.FormatType format_type = Tatam.SmallTime.FormatType.MINUMUM) {
    Tatam.SmallTime small_time = new Tatam.SmallTime.from_string(testee, format_type);
    print(@"original string: $(testee)\n");
    print(@"small_time.milliseconds: $(small_time.milliseconds)\n");
    print(@"small_time.to_string(): $(small_time.to_string())\n");
    print("\n");
}

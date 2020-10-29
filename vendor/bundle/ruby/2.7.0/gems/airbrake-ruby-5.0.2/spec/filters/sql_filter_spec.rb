RSpec.describe Airbrake::Filters::SqlFilter do
  shared_examples "query filtering" do |test|
    test[:dialects].each do |dialect|
      it "correctly filters SQL like `#{test[:input]}' (#{dialect} dialect)" do
        filter = described_class.new(dialect)
        q = OpenStruct.new(query: test[:input])
        filter.call(q)
        expect(q.query).to eq(test[:output])
      end
    end
  end

  shared_examples "query blocklisting" do |query, opts|
    it "ignores '#{query}'" do
      filter = described_class.new('postgres')
      q = Airbrake::Query.new(query: query, method: 'GET', route: '/', timing: 1)
      filter.call(q)

      expect(q.ignored?).to eq(opts[:should_ignore])
    end
  end

  ALL_DIALECTS = %i[mysql postgres sqlite cassandra oracle].freeze

  # rubocop:disable Layout/LineLength
  [
    {
      input: 'SELECT * FROM things;',
      output: 'SELECT * FROM things;',
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT `t001`.`c2` FROM `t001` WHERE `t001`.`c2` = 'value' AND c3=\"othervalue\" LIMIT ?",
      output: "SELECT `t001`.`c2` FROM `t001` WHERE `t001`.`c2` = ? AND c3=? LIMIT ?",
      dialects: %i[mysql],
    }, {
      input: "SELECT * FROM t WHERE foo=\"bar/*\" AND baz=\"whatever */qux\"",
      output: "SELECT * FROM t WHERE foo=? AND baz=?",
      dialects: %i[mysql],
    }, {
      input: "SELECT * FROM t WHERE foo='bar/*' AND baz='whatever */qux'",
      output: "SELECT * FROM t WHERE foo=? AND baz=?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT \"t001\".\"c2\" FROM \"t001\" WHERE \"t001\".\"c2\" = 'value' AND c3=1234 LIMIT 1",
      output: "SELECT \"t001\".\"c2\" FROM \"t001\" WHERE \"t001\".\"c2\" = ? AND c3=? LIMIT ?",
      dialects: %i[postgres oracle],
    }, {
      input: "SELECT * FROM t WHERE foo=\"bar--\" AND\n  baz=\"qux--\"",
      output: "SELECT * FROM t WHERE foo=? AND\n  baz=?",
      dialects: %i[mysql],
    }, {
      input: "SELECT * FROM t WHERE foo='bar--' AND\n  baz='qux--'",
      output: "SELECT * FROM t WHERE foo=? AND\n  baz=?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM foo WHERE bar='baz' /* Hide Me */",
      output: "SELECT * FROM foo WHERE bar=? ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM foobar WHERE password='hunter2'\n-- No peeking!",
      output: "SELECT * FROM foobar WHERE password=?\n?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT foo, bar FROM baz WHERE password='hunter2' # Secret",
      output: "SELECT foo, bar FROM baz WHERE password=? ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT \"col1\", \"col2\" from \"table\" WHERE \"col3\"=E'foo\\'bar\\\\baz' AND country=e'foo\\'bar\\\\baz'",
      output: "SELECT \"col1\", \"col2\" from \"table\" WHERE \"col3\"=E?",
      dialects: %i[postgres],
    }, {
      input: "INSERT INTO `X` values(\"test\",0, 1 , 2, 'test')",
      output: "INSERT INTO `X` values(?)",
      dialects: %i[mysql],
    }, {
      input: "INSERT INTO `X` values(\"test\",0, 1 , 2, 'test')",
      output: "INSERT INTO `X` values(?)",
      dialects: %i[mysql],
    }, {
      input: "SELECT c11.col1, c22.col2 FROM table c11, table c22 WHERE value='nothing'",
      output: "SELECT c11.col1, c22.col2 FROM table c11, table c22 WHERE value=?",
      dialects: ALL_DIALECTS,
    }, {
      input: "INSERT INTO X VALUES(1, 23456, 123.456, 99+100)",
      output: "INSERT INTO X VALUES(?)",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM table WHERE name=\"foo\" AND value=\"don't\"",
      output: "SELECT * FROM table WHERE name=? AND value=?",
      dialects: %i[mysql],
    }, {
      input: "SELECT * FROM table WHERE name='foo' AND value = 'bar'",
      output: "SELECT * FROM table WHERE name=? AND value = ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM table WHERE col='foo\\''bar'",
      output: "SELECT * FROM table WHERE col=?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM table WHERE col1='foo\"bar' AND col2='what\"ever'",
      output: "SELECT * FROM table WHERE col1=? AND col2=?",
      dialects: ALL_DIALECTS,
    }, {
      input: "select * from accounts where accounts.name != 'dude\n newline' order by accounts.name",
      output: "select * from accounts where accounts.name != ? order by accounts.name",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM table WHERE col1=\"don't\" AND col2=\"won't\"",
      output: "SELECT * FROM table WHERE col1=? AND col2=?",
      dialects: %i[mysql],
    }, {
      input: "INSERT INTO X values('', 'jim''s ssn',0, 1 , 'jim''s son''s son', \"\"\"jim''s\"\" hat\", \"\\\"jim''s secret\\\"\")",
      output: "INSERT INTO X values(?, ?,?, ? , ?, ?, ?",
      dialects: %i[mysql],
    }, {
      input: "SELECT * FROM table WHERE name='foo\\' AND color='blue'",
      output: "SELECT * FROM table WHERE name=?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM table WHERE foo=\"this string ends with a backslash\\\\\"",
      output: "SELECT * FROM table WHERE foo=?",
      dialects: %i[mysql],
    }, {
      input: "SELECT * FROM table WHERE foo='this string ends with a backslash\\\\'",
      output: "SELECT * FROM table WHERE foo=?",
      dialects: ALL_DIALECTS,
    }, {
      # TODO: fix this example.
      input: "SELECT * FROM table WHERE name='foo\'' AND color='blue'",
      output: "Error: Airbrake::Query was not filtered",
      dialects: ALL_DIALECTS,
    }, {
      input: "INSERT INTO X values('', 'a''b c',0, 1 , 'd''e f''s h')",
      output: "INSERT INTO X values(?)",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM t WHERE -- '\n  bar='baz' -- '",
      output: "SELECT * FROM t WHERE ?\n  bar=? ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM t WHERE /* ' */\n  bar='baz' -- '",
      output: "SELECT * FROM t WHERE ?\n  bar=? ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM t WHERE -- '\n  /* ' */ c2='xxx' /* ' */\n  c='x\n  xx' -- '",
      output: "SELECT * FROM t WHERE ?\n  ? c2=? ?\n  c=? ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM t WHERE -- '\n  c='x\n  xx' -- '",
      output: "SELECT * FROM t WHERE ?\n  c=? ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM foo WHERE col='value1' AND /* don't */ col2='value1' /* won't */",
      output: "SELECT * FROM foo WHERE col=? AND ? col2=? ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM table WHERE foo='bar' AND baz=\"nothing to see here'",
      output: "Error: Airbrake::Query was not filtered",
      dialects: %i[mysql],
    }, {
      input: "SELECT * FROM table WHERE foo='bar' AND baz='nothing to see here",
      output: "Error: Airbrake::Query was not filtered",
      dialects: ALL_DIALECTS,
    }, {
      input: "SELECT * FROM \"foo\" WHERE \"foo\" = $a$dollar quotes can be $b$nested$b$$a$ and bar = 'baz'",
      output: "SELECT * FROM \"foo\" WHERE \"foo\" = ? and bar = ?",
      dialects: %i[postgres],
    }, {
      input: "INSERT INTO \"foo\" (\"bar\", \"baz\", \"qux\") VALUES ($1, $2, $3) RETURNING \"id\"",
      output: "INSERT INTO \"foo\" (?) RETURNING \"id\"",
      dialects: %i[postgres],
    }, {
      input: "select * from foo where bar = 'some\\tthing' and baz = 10",
      output: "select * from foo where bar = ? and baz = ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "select * from users where user = 'user1\\' password = 'hunter 2' -- ->don't count this quote",
      output: "select * from users where user = ?",
      dialects: ALL_DIALECTS,
    }, {
      input: "select * from foo where bar=q'[baz's]' and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[oracle],
    }, {
      input: "select * from foo where bar=q'{baz's}' and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[oracle],
    }, {
      input: "select * from foo where bar=q'<baz's>' and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[oracle],
    }, {
      input: "select * from foo where bar=q'(baz's)' and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[oracle],
    }, {
      input: "select * from foo where bar=0xabcdef123 and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[cassandra sqlite],
    }, {
      input: "select * from foo where bar=0x2F and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[mysql cassandra sqlite],
    }, {
      input: "select * from foo where bar=1.234e-5 and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: ALL_DIALECTS,
    }, {
      input: "select * from foo where bar=01234567-89ab-cdef-0123-456789abcdef and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[postgres cassandra],
    }, {
      input: "select * from foo where bar={01234567-89ab-cdef-0123-456789abcdef} and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[postgres],
    }, {
      input: "select * from foo where bar=0123456789abcdef0123456789abcdef and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[postgtes],
    }, {
      input: "select * from foo where bar={012-345678-9abc-def012345678-9abcdef} and x=5",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[postgres],
    }, {
      input: "select * from foo where bar=true and x=FALSE",
      output: "select * from foo where bar=? and x=?",
      dialects: %i[mysql postgres cassandra sqlite],
    }
  ].each do |test|
    include_examples 'query filtering', test
  end
  # rubocop:enable Layout/LineLength

  [
    'COMMIT',
    'commit',
    'BEGIN',
    'begin',
    'SET time zone ?',
    'set time zone ?',
    'SHOW max_identifier_length',
    'show max_identifier_length',

    'WITH pk_constraint AS ( SELECT conrelid, unnest(conkey) AS connum ' \
    'FROM pg_constraint WHERE contype = ? AND conrelid = ?::regclass ), ' \
    'cons AS ( SELECT conrelid, connum, row_number() OVER() AS rownum FROM ' \
    'pk_constraint ) SELECT attr.attname FROM pg_attribute attr INNER JOIN ' \
    'cons ON attr.attrelid = cons.conrelid AND attr.attnum = cons.connum ' \
    'ORDER BY cons.rownum',

    'SELECT c.relname FROM pg_class c LEFT JOIN pg_namespace n ON ' \
    'n.oid = c.relnamespace WHERE n.nspname = ANY (?)',

    'SELECT a.attname FROM ( SELECT indrelid, indkey, generate_subscripts(?) ' \
    'idx FROM pg_index WHERE indrelid = ?::regclass AND indisprimary ) i ' \
    'JOIN pg_attribute a ON a.attrelid = i.indrelid AND ' \
    'a.attnum = i.indkey[i.idx] ORDER BY i.idx',

    'SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, r.rngsubtype, ' \
    't.typtype, t.typbasetype FROM pg_type as t LEFT JOIN pg_range as r ON ' \
    'oid = rngtypid WHERE t.typname IN (?) OR t.typtype IN (?) OR t.typinput ' \
    '= ?::regprocedure OR t.typelem != ?',

    'SELECT t.oid, t.typname FROM pg_type as t WHERE t.typname IN (?)',
  ].each do |query|
    include_examples 'query blocklisting', query, should_ignore: true
  end

  [
    'UPDATE "users" SET "last_sign_in_at" = ? WHERE "users"."id" = ?',
  ].each do |query|
    include_examples 'query blocklisting', query, should_ignore: false
  end
end

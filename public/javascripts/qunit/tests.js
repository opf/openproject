/**
 * Custom assertions
 *
 * Somehow, the same approach, that may be seen in other QUnit plugins -
 * extending QUnit itself and not QUnit.assert, does not work as expected. Also,
 * the patch below does not expose `not` to the test method, instead the assert
 * parameter passed to the test function must be used.
 */

QUnit.extend(QUnit.assert, {
  no: function (expected, message) {
    QUnit.ok(!expected, message);
  }
});


/**
 * OpenProject instance methods
 */
module("OpenProject instance");

test("`getFullUrl` with undefined urlRoot", function (assert) {
  var op = new OpenProject({});

  assert.strictEqual(op.getFullUrl('/foo'), '/foo', "works w/ leading slash");
  assert.strictEqual(op.getFullUrl('foo'),  '/foo', "works w/o leading slash");
  assert.strictEqual(op.getFullUrl(''),     '/', "works w/ empty string");
  assert.strictEqual(op.getFullUrl(),       '/', "works w/o parameter");
});

test("`getFullUrl` with empty string urlRoot", function (assert) {
  var op = new OpenProject({urlRoot : ''});

  assert.strictEqual(op.getFullUrl('/foo'), '/foo', "works w/ leading slash");
  assert.strictEqual(op.getFullUrl('foo'),  '/foo', "works w/o leading slash");
  assert.strictEqual(op.getFullUrl(''),     '/', "works w/ empty string");
  assert.strictEqual(op.getFullUrl(),       '/', "works w/o parameter");
});

test("`getFullUrl` with '/' urlRoot", function (assert) {
  var op = new OpenProject({urlRoot : '/'});

  assert.strictEqual(op.getFullUrl('/foo'), '/foo', "works w/ leading slash");
  assert.strictEqual(op.getFullUrl('foo'),  '/foo', "works w/o leading slash");
  assert.strictEqual(op.getFullUrl(''),     '/', "works w/ empty string");
  assert.strictEqual(op.getFullUrl(),       '/', "works w/o parameter");
});

test("`getFullUrl` with urlRoot w/ trailing slash", function (assert) {
  var op = new OpenProject({urlRoot : '/op/'});

  assert.strictEqual(op.getFullUrl('/foo'),  '/op/foo', "works w/ leading slash");
  assert.strictEqual(op.getFullUrl('foo'),   '/op/foo', "works w/o leading slash");
  assert.strictEqual(op.getFullUrl(''),      '/op/', "works w/ empty string");
  assert.strictEqual(op.getFullUrl(),        '/op/', "works w/o parameter");
});

test("`getFullUrl` with urlRoot w/o trailing slash", function (assert) {
  var op = new OpenProject({urlRoot : '/op'});

  assert.strictEqual(op.getFullUrl('/foo'),  '/op/foo', "works w/ leading slash");
  assert.strictEqual(op.getFullUrl('foo'),   '/op/foo', "works w/o leading slash");
  assert.strictEqual(op.getFullUrl(''),      '/op/', "works w/ empty string");
  assert.strictEqual(op.getFullUrl(),        '/op/', "works w/o parameter");
});

test("`fetchProjects` caches result", 1, function (assert) {
  var op = new OpenProject();
  op.projects = 'something';

  op.fetchProjects(function (projects) {
    assert.strictEqual(projects, 'something');
  });
});






/**
 * OpenProject.Helpers.Search
 */
QUnit.module("OpenProject.Helpers.Search");

QUnit.test("`tokenize` with one parameter", function (assert) {
  var t = OpenProject.Helpers.Search.tokenize;

  assert.deepEqual(t("abc"),       ["abc"]);
  assert.deepEqual(t("abc def"),   ["abc", "def"]);
  assert.deepEqual(t("abc  def"),  ["abc", "def"]);
  assert.deepEqual(t(" abc def"),  ["abc", "def"]);
  assert.deepEqual(t("abc/def-"),  ["abc", "def"]);
  assert.deepEqual(t("/abc-def/"), ["abc", "def"]);
});

QUnit.test("`tokenize` with array parameter", function (assert) {
  var t = OpenProject.Helpers.Search.tokenize;

  assert.deepEqual(t("abc",  ["b"]), ["a", "c"]);
  assert.deepEqual(t("abbc", ["b"]), ["a", "c"]);
  assert.deepEqual(t("abc ", ["b"]), ["a", "c "]);
});

QUnit.test("`tokenize` with RegExp parameter", function (assert) {
  var t = OpenProject.Helpers.Search.tokenize;

  assert.deepEqual(t("abc",  /b/), ["a", "c"]);
  assert.deepEqual(t("abbc", /b/), ["a", "c"]);
  assert.deepEqual(t("abc ", /b/), ["a", "c "]);
});

QUnit.test("`matcher` w/o token parameter", function (assert) {
  var matcher = OpenProject.Helpers.Search.matcher;

  // Basic search
  assert.ok(matcher("",      "abc"),     "matches when looking for empty string");
  assert.ok(matcher("ab",    "abc"),     "matches on sub strings");
  assert.ok(matcher("abc",   "abc"),     "matches on whole matches");
  assert.ok(matcher("AbC",   "aBc"),     "matches case insensitive");
  assert.ok(matcher("b",     "abc"),     "matches within words");
  assert.ok(matcher("ä",     "äbc"),     "matches umlauts");
  assert.ok(matcher("bc de", "abc def"), "matches including spaces");

  assert.no(matcher("abc", "def"), "no match when string not contained");

  // Token search
  assert.no(matcher("b c", "ab-cd"), "no match based on token");
});

QUnit.test("`matcher` w/ token parameter", function (assert) {
  var token_match = function(term, name) {
    return OpenProject.Helpers.Search.matcher(
      term,
      name,
      OpenProject.Helpers.Search.tokenize(name));
  };


  // Basic match
  assert.ok(token_match("",      "abc"),     "matches when looking for empty string");
  assert.ok(token_match("ab",    "abc"),     "matches on sub strings");
  assert.ok(token_match("abc",   "abc"),     "matches on whole matches");
  assert.ok(token_match("AbC",   "aBc"),     "matches case insensitive");
  assert.ok(token_match("b",     "abc"),     "matches within words");
  assert.ok(token_match("ä",     "äbc"),     "matches umlauts");
  assert.ok(token_match("bc de", "abc def"), "matches including spaces");


  assert.no(token_match("abc",   "def"),     "no match when string not contained");

  // Token match
  assert.ok(token_match("b c",    "ab c"),    "match when all token contained I");
  assert.ok(token_match("a a",    "ab a"),    "match when all token contained II");
  assert.ok(token_match("a b",    "ab b"),    "match when all token contained III");
  assert.ok(token_match("a b",    "b ab"),    "match when all token contained IV");
  assert.ok(token_match("a a",    "a a"),     "match when all token contained V");
  assert.ok(token_match("bc  de", "abc def"), "matches including spaces");

  assert.no(token_match("a-a", "a a"),  "tokenizes term at white space only");
});

//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

/**
 * OpenProject instance methods
 */
describe("OpenProject instance `getFullUrl`", function() {
  it("with undefined urlRoot", function() {
    var op = new OpenProject({});

    assert.strictEqual(op.getFullUrl('/foo'), '/foo', "works w/ leading slash");
    assert.strictEqual(op.getFullUrl('foo'),  '/foo', "works w/o leading slash");
    assert.strictEqual(op.getFullUrl(''),     '/', "works w/ empty string");
    assert.strictEqual(op.getFullUrl(),       '/', "works w/o parameter");
  });

  it("with empty string urlRoot", function() {
    var op = new OpenProject({urlRoot : ''});

    assert.strictEqual(op.getFullUrl('/foo'), '/foo', "works w/ leading slash");
    assert.strictEqual(op.getFullUrl('foo'),  '/foo', "works w/o leading slash");
    assert.strictEqual(op.getFullUrl(''),     '/', "works w/ empty string");
    assert.strictEqual(op.getFullUrl(),       '/', "works w/o parameter");
  });

  it("with '/' urlRoot", function() {
    var op = new OpenProject({urlRoot : '/'});

    assert.strictEqual(op.getFullUrl('/foo'), '/foo', "works w/ leading slash");
    assert.strictEqual(op.getFullUrl('foo'),  '/foo', "works w/o leading slash");
    assert.strictEqual(op.getFullUrl(''),     '/', "works w/ empty string");
    assert.strictEqual(op.getFullUrl(),       '/', "works w/o parameter");
  });

  it("with urlRoot w/ trailing slash", function() {
    var op = new OpenProject({urlRoot : '/op/'});

    assert.strictEqual(op.getFullUrl('/foo'),  '/op/foo', "works w/ leading slash");
    assert.strictEqual(op.getFullUrl('foo'),   '/op/foo', "works w/o leading slash");
    assert.strictEqual(op.getFullUrl(''),      '/op/', "works w/ empty string");
    assert.strictEqual(op.getFullUrl(),        '/op/', "works w/o parameter");
  });

  it("with urlRoot w/o trailing slash", function() {
    var op = new OpenProject({urlRoot : '/op'});

    assert.strictEqual(op.getFullUrl('/foo'),  '/op/foo', "works w/ leading slash");
    assert.strictEqual(op.getFullUrl('foo'),   '/op/foo', "works w/o leading slash");
    assert.strictEqual(op.getFullUrl(''),      '/op/', "works w/ empty string");
    assert.strictEqual(op.getFullUrl(),        '/op/', "works w/o parameter");
  });
});

describe("OpenProject instance `fetchProjects`", function() {

  var defaultOptions = {
    logging: false,
    url: new RegExp('.*/projects/level_list\\.json'),
    responseTime: 0
  };

  beforeEach(function() {
    jQuery.mockjax(jQuery.extend(defaultOptions, {
      responseText: '{"projects":[{"identifier":"bums","created_on":"2012-12-18T07:00:17Z","level":0,"updated_on":"2012-12-18T09:09:10Z","name":"Bums zzz","id":3},{"identifier":"things","created_on":"2012-12-14T14:01:27Z","level":0,"updated_on":"2012-12-14T14:01:27Z","name":"Things","id":1},{"identifier":"things-bums","created_on":"2012-12-18T06:59:50Z","level":1,"updated_on":"2012-12-18T14:26:05Z","name":"Thingsb-Bums","id":2},{"identifier":"bums-bums","created_on":"2012-12-18T08:57:46Z","level":2,"updated_on":"2012-12-18T08:57:46Z","name":"Bums Bums","id":5},{"identifier":"zzz","created_on":"2012-12-18T08:57:14Z","level":0,"updated_on":"2012-12-18T08:57:14Z","name":"ZZZ","id":4}],"size":5}'
    }));
  });

  afterEach(function() {
    jQuery.mockjax.clear();
  });


  it("calls /projects/level_list.json to fetch results", function() {
    var op = new OpenProject();

    op.fetchProjects(function (projects) {
      assert.strictEqual(projects.length, 5);
    });
  });

  it("adds hname to projects", function() {
    var op = new OpenProject(),
        hname = OpenProject.Helpers.hname;

    op.fetchProjects(function (projects) {
      assert.deepEqual(projects[0].hname, "Bums zzz");
      assert.deepEqual(projects[1].hname, "Things");
      assert.deepEqual(projects[2].hname, hname("Thingsb-Bums", 1));
      assert.deepEqual(projects[3].hname, hname("Bums Bums", 2));
      assert.deepEqual(projects[4].hname, "ZZZ");
    });
  });

  it("adds parents array to projects", function() {
    var op = new OpenProject();

    op.fetchProjects(function (projects) {
      assert.deepEqual(projects[0].parents, []);
      assert.deepEqual(projects[1].parents, []);
      assert.deepEqual(projects[2].parents, [projects[1]]);
      assert.deepEqual(projects[3].parents, [projects[1], projects[2]]);
      assert.deepEqual(projects[4].parents, []);
    });
  });

  it("adds tokens to projects", function() {
    var op = new OpenProject();

    op.fetchProjects(function (projects) {
      assert.deepEqual(projects[0].tokens, ["Bums", "zzz"]);
      assert.deepEqual(projects[1].tokens, ["Things"]);
      assert.deepEqual(projects[2].tokens, ["Thingsb", "Bums"]);
      assert.deepEqual(projects[3].tokens, ["Bums", "Bums"]);
      assert.deepEqual(projects[4].tokens, ["ZZZ"]);
    });
  });

  it("adds url to projects", function() {
    var op = new OpenProject();

    op.fetchProjects(function (projects) {
      assert.deepEqual(projects[0].url, "/projects/bums");
      assert.deepEqual(projects[1].url, "/projects/things");
      assert.deepEqual(projects[2].url, "/projects/things-bums");
      assert.deepEqual(projects[3].url, "/projects/bums-bums");
      assert.deepEqual(projects[4].url, "/projects/zzz");
    });
  });

  it("adds url to projects with different urlRoot", function() {
    var op = new OpenProject({urlRoot : "/foo"});

    op.fetchProjects(function (projects) {
      assert.deepEqual(projects[0].url, "/foo/projects/bums");
      assert.deepEqual(projects[1].url, "/foo/projects/things");
      assert.deepEqual(projects[2].url, "/foo/projects/things-bums");
      assert.deepEqual(projects[3].url, "/foo/projects/bums-bums");
      assert.deepEqual(projects[4].url, "/foo/projects/zzz");
    });
  });

  it("caches result", function() {
    var op = new OpenProject();
    op.projects = 'something';

    op.fetchProjects(function (projects) {
      assert.strictEqual(projects, 'something');
    });
  });
});


/**
 * OpenProject.Helpers
 */
describe("OpenProject.Helpers `hname`", function() {
  it("adds spaces and arrows to names when level > 0", function() {
    var hname = OpenProject.Helpers.hname;

    assert.strictEqual(hname("a", -1), "a");
    assert.strictEqual(hname("a",  0), "a");
    assert.strictEqual(hname("a",  1), "\u00A0\u00A0\u00A0\u00BB\u00A0a");
    assert.strictEqual(hname("a",  2), "\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00BB\u00A0a");
  });
});


describe("OpenProject.Helpers `regexpEscape`", function() {
  it("adds leading \\ to regexp special characters", function() {
    var esc = OpenProject.Helpers.regexpEscape;

    assert.strictEqual(esc("."), "\\.");
    assert.strictEqual(esc("?"), "\\?");
    assert.strictEqual(esc("["), "\\[");
    assert.strictEqual(esc("+"), "\\+");

    assert.strictEqual(esc("a"), "a");
  });
});


describe("OpenProject.Helpers `replace`", function() {
  it("replaces wrong with right in text once ignoring case", function() {
    var replace = OpenProject.Helpers.replace;

    // Basic functionality
    assert.strictEqual(replace("abc", "a", "b"), "bbc");
    assert.strictEqual(replace("aaa", "a", "b"), "baa");
    assert.strictEqual(replace("aaa", "d", "b"), "aaa");

    // Empty parameters
    assert.strictEqual(replace("aaa", "", "b"), "aaa");
    assert.strictEqual(replace("aaa", "a", ""), "aa");
    assert.strictEqual(replace("", "a", "b"), "");
    assert.strictEqual(replace("", "", ""), "");

    // Different lengths
    assert.strictEqual(replace("aaa", "a", "bb"), "bbaa");
    assert.strictEqual(replace("aaa", "aa", "b"), "ba");

    // Ignore case
    assert.strictEqual(replace("Aaa", "a", "b"), "baa");
    assert.strictEqual(replace("aaa", "A", "b"), "baa");
  });
});


describe("OpenProject.Helpers `withoutOnce`", function() {
  it("removes given element once from array", function() {
    var withoutOnce = OpenProject.Helpers.withoutOnce;

    assert.deepEqual(withoutOnce([1, 2, 3, 2, 1], 1), [2, 3, 2, 1]);
    assert.deepEqual(withoutOnce([1, 2, 3, 2, 1], 2), [1, 3, 2, 1]);
    assert.deepEqual(withoutOnce([1, 2, 3, 2, 1], 4), [1, 2, 3, 2, 1]);
  });
});


describe("OpenProject.Helpers `hname`", function() {
  it("adds spaces and arrows to names when level > 0", function() {
    var hname = OpenProject.Helpers.hname;

    assert.strictEqual(hname("a", -1), "a");
    assert.strictEqual(hname("a",  0), "a");
    assert.strictEqual(hname("a",  1), "\u00A0\u00A0\u00A0\u00BB\u00A0a");
    assert.strictEqual(hname("a",  2), "\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00BB\u00A0a");
  });
});


/**
 * OpenProject.Helpers.Search
 */
describe("OpenProject.Helpers.Search `tokenize`", function() {
  it("with one parameter", function() {
    var t = OpenProject.Helpers.Search.tokenize;

    assert.deepEqual(t("abc"),       ["abc"]);
    assert.deepEqual(t("abc def"),   ["abc", "def"]);
    assert.deepEqual(t("abc  def"),  ["abc", "def"]);
    assert.deepEqual(t(" abc def"),  ["abc", "def"]);
    assert.deepEqual(t("abc/def-"),  ["abc", "def"]);
    assert.deepEqual(t("/abc-def/"), ["abc", "def"]);
  });

  it("with array parameter", function() {
    var t = OpenProject.Helpers.Search.tokenize;

    assert.deepEqual(t("abc",  ["b"]), ["a", "c"]);
    assert.deepEqual(t("abbc", ["b"]), ["a", "c"]);
    assert.deepEqual(t("abc ", ["b"]), ["a", "c "]);
  });

  it("with RegExp parameter", function() {
    var t = OpenProject.Helpers.Search.tokenize;

    assert.deepEqual(t("abc",  /b/), ["a", "c"]);
    assert.deepEqual(t("abbc", /b/), ["a", "c"]);
    assert.deepEqual(t("abc ", /b/), ["a", "c "]);
  });
});


describe("OpenProject.Helpers.Search `formatter`", function() {
  it("w/o result.matches", function() {
    var formatter = OpenProject.Helpers.Search.formatter,
        a = "<span class='select2-match'>",
        o = "</span>";

    assert.deepEqual(formatter({text: "abc"},  undefined, {term: ''}),
                     "abc");
    assert.deepEqual(formatter({text: "abc"},  undefined, {term: 'b'}),
                     "a" + a + "b" + o + "c");
    assert.deepEqual(formatter({text: "abc"},  undefined, {term: 'c'}),
                     "ab" + a + "c" + o);
    assert.deepEqual(formatter({text: "abbc"}, undefined, {term: 'b'}),
                     "a" + a + "b" + o + "bc");
  });

  it("w/ empty query.term", function() {
    var formatter = OpenProject.Helpers.Search.formatter;

    assert.deepEqual(formatter({text: "abc", matches: [["abc", ""]]}, undefined, {term: ''}),
                     "abc");

    assert.deepEqual(formatter({text: "abc", matches: [["abc", ""]]}, undefined, {term: " "}),
                     "abc");
  });

  it("w/ single match", function() {
    var formatter = OpenProject.Helpers.Search.formatter,
        a = "<span class='select2-match'>",
        o = "</span>";

    assert.deepEqual(formatter({text: "abc", matches: [["abc", "b"]]}, undefined, {term: "b"}),
                     "a" + a + "b" + o + "c");

    assert.deepEqual(formatter({text: "abc", matches: [["abc", ""]]}, undefined, {term: ' '}),
                     "abc");
  });

  it("w/ multi match", function() {
    var formatter = OpenProject.Helpers.Search.formatter,
        a = "<span class='select2-match'>",
        o = "</span>";

    assert.deepEqual(formatter({text: "abc-def", matches: [["def", "e"], ["abc", "b"]]}, undefined, {term: "e b"}),
                     "a" + a + "b" + o + "c-d" + a + "e" + o + "f");

    assert.deepEqual(formatter({text: "abc-def", matches: [["abc", "b"], ["def", "e"]]}, undefined, {term: "b e"}),
                     "a" + a + "b" + o + "c-d" + a + "e" + o + "f");

    assert.deepEqual(formatter({text: "abc-abc", matches: [["abc", "b"], ["abc", "bc"]]}, undefined, {term: "b bc"}),
                     "a" + a + "bc" + o + "-a" + a + "b" + o + "c");

  });
});


describe("OpenProject.Helpers.Search `matcher`", function() {
  it("w/o token parameter", function() {
    var matcher = OpenProject.Helpers.Search.matcher;

    // Basic search
    assert.ok(matcher("",      "abc"),     "matches when looking for empty string");
    assert.ok(matcher("ab",    "abc"),     "matches on sub strings");
    assert.ok(matcher("abc",   "abc"),     "matches on whole matches");
    assert.ok(matcher("AbC",   "aBc"),     "matches case insensitive");
    assert.ok(matcher("b",     "abc"),     "matches within words");
    assert.ok(matcher("ä",     "äbc"),     "matches umlauts");
    assert.ok(matcher("bc de", "abc def"), "matches including spaces");

    assert.notOk(matcher("abc", "def"), "no match when string not contained");

    // Token search
    assert.notOk(matcher("b c", "ab-cd"), "no match based on token");
  });

  it("w/ token parameter", function() {
    var matcher = OpenProject.Helpers.Search.matcher,
        token_match = function(term, name) {
          return matcher(term, name, OpenProject.Helpers.Search.tokenize(name));
        };

    // Basic match
    assert.ok(token_match("",      "abc"),     "matches when looking for empty string");
    assert.ok(token_match("ab",    "abc"),     "matches on sub strings");
    assert.ok(token_match("abc",   "abc"),     "matches on whole matches");
    assert.ok(token_match("AbC",   "aBc"),     "matches case insensitive");
    assert.ok(token_match("b",     "abc"),     "matches within words");
    assert.ok(token_match("ä",     "äbc"),     "matches umlauts");
    assert.ok(token_match("bc de", "abc def"), "matches including spaces");


    assert.notOk(token_match("abc",   "def"),     "no match when string not contained");

    // Token match
    assert.ok(token_match("b c",    "ab c"),    "match when all token contained I");
    assert.ok(token_match("a a",    "ab a"),    "match when all token contained II");
    assert.ok(token_match("a b",    "ab b"),    "match when all token contained III");
    assert.ok(token_match("a b",    "b ab"),    "match when all token contained IV");
    assert.ok(token_match("a a",    "a a"),     "match when all token contained V");
    assert.ok(token_match("bc  de", "abc def"), "matches including spaces");

    assert.notOk(token_match("a-a", "a a"),  "tokenizes term at white space only");
  });
});


describe("OpenProject.Helpers.Search `projectQueryWithHierarchy`", function() {
  it("needs testing");
});

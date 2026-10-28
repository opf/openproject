# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraWikiMarkupConverter do
  subject(:result) { described_class.new(input).convert }

  describe "edge cases" do
    context "with nil-like blank input" do
      let(:input) { "" }

      it { is_expected.to eq("") }
    end

    context "with plain text (no markup)" do
      let(:input) { "Just some plain text." }

      it { is_expected.to eq("Just some plain text.") }
    end

    context "with escaped special characters" do
      let(:input) { 'This is not \{code\} and not \[a link\]' }

      it { is_expected.to eq("This is not {code} and not [a link]") }
    end

    context "with invalid UTF-8 byte sequences in the input" do
      it "drops a stray invalid byte and keeps the surrounding text" do
        input = "Hello \xFF world".dup
        expect(input.valid_encoding?).to be(false)
        expect(described_class.new(input).convert).to eq("Hello ? world")
      end

      it "drops a stray continuation byte" do
        input = "abc \x80 def".dup
        expect(input.valid_encoding?).to be(false)
        expect(described_class.new(input).convert).to eq("abc ? def")
      end

      it "drops a truncated multi-byte sequence" do
        input = "pre \xC3 post".dup
        expect(input.valid_encoding?).to be(false)
        expect(described_class.new(input).convert).to eq("pre ? post")
      end

      it "preserves valid multi-byte characters while dropping only the invalid byte" do
        input = "héllo \xFF world".dup
        expect(input.valid_encoding?).to be(false)
        expect(described_class.new(input).convert).to eq("héllo ? world")
      end

      it "still parses formatting around invalid bytes inside delimiters" do
        input = "*bold\xFFtext*".dup
        expect(input.valid_encoding?).to be(false)
        expect(described_class.new(input).convert).to eq("**bold?text**")
      end
    end

    context "with in between horizontal lines" do
      let(:input) do
        "start\n----\nGot it? Now click *Resolve this issue* " \
          "and add a comment to complete this request.\n----\nend"
      end

      it do
        expect(subject).to eq(
          "start\n<hr>\n\nGot it? Now click **Resolve this issue** " \
          "and add a comment to complete this request.\n<hr>\n\nend"
        )
      end
    end
  end

  describe "line ending normalization" do
    let(:input) { "line one\r\nline two\r\n" }

    it { is_expected.to eq("line one\n\nline two\n\n") }
  end

  describe "code blocks" do
    context "with a language specifier" do
      let(:input) { "{code:java}\npublic class Foo {}\n{code}" }

      it { is_expected.to eq("```java\npublic class Foo {}\n```") }
    end

    context "without a language specifier" do
      let(:input) { "{code}\nsome code\n{code}" }

      it { is_expected.to eq("```\nsome code\n```") }
    end

    context "with {noformat}" do
      let(:input) { "{noformat}\npreformatted text\n{noformat}" }

      it { is_expected.to eq("```\npreformatted text\n```") }
    end

    context "with {noformat} and parameters" do
      let(:input) { "{noformat:nopanel=true|borderStyle=solid}\npreformatted text\n{noformat}" }

      it { is_expected.to eq("```\npreformatted text\n```") }
    end

    context "when noformat blocks markers are all over the place" do
      let(:input) do
        "{noformat}\n" \
          "preformatted text {noformat}\n" \
          "{noformat}preformatted text{noformat}\n" \
          "{noformat}\npreformatted text{noformat}\n" \
          "{noformat}preformatted text\n{noformat}"
      end
      let(:output) do
        "```\npreformatted text\n```\n" \
          "```\npreformatted text\n```\n" \
          "```\npreformatted text\n```\n" \
          "```\npreformatted text\n```"
      end

      it "does produce all code blocks" do
        expect(result).to eq(output)
      end
    end

    context "with extra parameters in opening tag" do
      let(:input) { "{code:java|title=Bar.java|borderStyle=solid}\n// comment\n{code}" }

      it { is_expected.to eq("```java\n// comment\n```") }
    end

    context "with closing tag on the same line as content" do
      let(:input) { "{code:java}\n// inline {code}" }

      it { is_expected.to eq("```java\n// inline\n```") }
    end

    context "with extra parameters and closing tag on same line" do
      let(:input) do
        "{code:java|title=Bar.java|borderStyle=solid}\n " \
          "// Some comments here public String getFoo() { return foo; } {code}"
      end

      it { is_expected.to eq("```java\n // Some comments here public String getFoo() { return foo; }\n```") }
    end

    context "with parameters but no language" do
      let(:input) { "{code:title=Bar.java|borderStyle=solid}\n// comment\n{code}" }

      it { is_expected.to eq("```\n// comment\n```") }
    end

    context "with an empty language specifier" do
      let(:input) { "{code:}\n// comment\n{code}" }

      it { is_expected.to eq("```\n// comment\n```") }
    end

    context "with an empty language specifier and content on the opening line" do
      let(:input) { "{code:}// comment\n{code}" }

      it { is_expected.to eq("```\n// comment\n```") }
    end

    context "with a header consisting only of separators" do
      let(:input) { "See {code:||}// comment{code} above" }

      it { is_expected.to eq("See ```\n// comment\n``` above") }
    end

    context "when code block content is protected from other conversions" do
      let(:input) { "{code}\n*bold* and _italic_\n{code}" }

      it "does not convert formatting inside code blocks" do
        expect(result).to eq("```\n*bold* and _italic_\n```")
      end
    end

    context "when code blocks markers are all over the place" do
      let(:input) do
        "{code:java|title=Bar.java|borderStyle=solid}\n " \
          "// Some comments here public String getFoo() { return foo; } {code}\n" \
          "{code:java}// Some comments here public String getFoo() { return foo; } {code}\n" \
          "{code}\n// Some comments here public String getFoo() { return foo; }{code}\n" \
          "{code}// Some comments here public String getFoo() { return foo; }\n{code}"
      end
      let(:output) do
        "```java\n // Some comments here public String getFoo() { return foo; }\n```\n" \
          "```java\n// Some comments here public String getFoo() { return foo; } \n```\n" \
          "```\n// Some comments here public String getFoo() { return foo; }\n```\n" \
          "```\n// Some comments here public String getFoo() { return foo; }\n```"
      end

      it "does produce all code blocks" do
        expect(result).to eq(output)
      end
    end
  end

  describe "user mentions" do
    context "when the user exists" do
      let!(:user) { create(:user, login: "john.doe", firstname: "John", lastname: "Doe") }
      let(:input) { "Assigned to [~john.doe] for review." }

      it "converts to an OpenProject mention tag" do
        expect(result).to include('<mention class="mention"')
        expect(result).to include(%(data-id="#{user.id}"))
        expect(result).to include('data-type="user"')
        expect(result).to include('data-text="@John Doe"')
        expect(result).to include(">@John Doe</mention>")
      end
    end

    context "when the user does not exist" do
      let(:input) { "Assigned to [~unknown.user] for review." }

      it "falls back to @username" do
        expect(result).to eq("Assigned to @unknown.user for review.")
      end
    end
  end

  describe "headings" do
    (1..6).each do |level|
      context "with h#{level}" do
        let(:input) { "h#{level}. Heading level #{level}" }

        it { is_expected.to eq("#{'#' * level} Heading level #{level}") }
      end
    end
  end

  describe "text formatting" do
    context "with bold" do
      let(:input) { "This is *bold* text." }

      it { is_expected.to eq("This is **bold** text.") }
    end

    context "with italic" do
      let(:input) { "This is _italic_ text." }

      it { is_expected.to eq("This is *italic* text.") }
    end

    context "with strikethrough" do
      let(:input) { "This is -deleted- text." }

      it { is_expected.to eq("This is ~~deleted~~ text.") }
    end

    context "with underline" do
      let(:input) { "This is +underlined+ text." }

      it { is_expected.to eq("This is <u>underlined</u> text.") }
    end

    context "with inline code" do
      let(:input) { "Use {{monospace}} font." }

      it { is_expected.to eq("Use `monospace` font.") }
    end

    context "with citation" do
      let(:input) { "As ??someone famous?? once said." }

      it { is_expected.to eq("As <cite>someone famous</cite> once said.") }
    end

    context "with superscript" do
      let(:input) { "E = mc^2^" }

      it { is_expected.to eq("E = mc<sup>2</sup>") }
    end

    context "with subscript" do
      let(:input) { "H~2~O" }

      it { is_expected.to eq("H<sub>2</sub>O") }
    end

    context "with multi-byte UTF-8 characters inside formatting delimiters" do
      it "handles bold with multi-byte characters" do
        expect(described_class.new("This is *héllo* text.").convert)
          .to eq("This is **héllo** text.")
      end

      it "handles italic with multi-byte characters" do
        expect(described_class.new("This is _äöü_ text.").convert)
          .to eq("This is *äöü* text.")
      end

      it "handles strikethrough with multi-byte characters" do
        expect(described_class.new("This is -déléted- text.").convert)
          .to eq("This is ~~déléted~~ text.")
      end

      it "handles underline with multi-byte characters" do
        expect(described_class.new("This is +éàü+ text.").convert)
          .to eq("This is <u>éàü</u> text.")
      end

      it "handles subscript with multi-byte characters" do
        expect(described_class.new("H~äö~O").convert)
          .to eq("H<sub>äö</sub>O")
      end

      it "handles multiple formatted multi-byte segments in one line" do
        expect(described_class.new("*éé* and _öü_").convert)
          .to eq("**éé** and *öü*")
      end

      it "handles Arabic inside bold" do
        expect(described_class.new("*مرحبا*").convert).to eq("**مرحبا**")
      end

      it "handles Chinese inside bold" do
        expect(described_class.new("*你好*").convert).to eq("**你好**")
      end

      it "handles Japanese inside italic" do
        expect(described_class.new("_日本語_").convert).to eq("*日本語*")
      end

      it "handles Cyrillic inside bold" do
        expect(described_class.new("*Привет*").convert).to eq("**Привет**")
      end

      it "handles Hebrew inside bold" do
        expect(described_class.new("*שלום*").convert).to eq("**שלום**")
      end

      it "handles 4-byte emoji inside bold" do
        expect(described_class.new("*🎉*").convert).to eq("**🎉**")
      end

      it "handles subscript after a macro preceded by a multi-byte character" do
        # Regression: scanner.string[0...scanner.pos] mixed byte-pos with char-slicing,
        # causing "é*x*~2~" to spuriously "see" the closing ~ in the already-scanned
        # prefix and skip subscript parsing.
        expect(described_class.new("é*x*~2~").convert).to eq("é**x**<sub>2</sub>")
        expect(described_class.new("🎉*x*~2~").convert).to eq("🎉**x**<sub>2</sub>")
      end
    end
  end

  describe "links" do
    context "with text and URL" do
      let(:input) { "[OpenProject|https://www.openproject.org]" }

      it { is_expected.to eq("[OpenProject](https://www.openproject.org)") }
    end

    context "with bare URL" do
      let(:input) { "[https://www.openproject.org]" }

      it { is_expected.to eq("<https://www.openproject.org>") }
    end
  end

  describe "images" do
    context "with alt text" do
      let(:input) { "!screenshot.png|Screenshot of dashboard!" }

      it { is_expected.to eq("![Screenshot of dashboard](screenshot.png)") }
    end

    context "without alt text" do
      let(:input) { "!screenshot.png!" }

      it { is_expected.to eq("![](screenshot.png)") }
    end

    context "with spaces in the file name" do
      let(:input) { "!Screenshot 2025-06-07 at 16.28.33.png|thumbnail!" }

      it "references the name the attachment is stored under" do
        expect(result).to eq("![](Screenshot_2025-06-07_at_16.28.33.png)")
      end
    end

    context "with spaces in the file name and no parameters" do
      let(:input) { "!My Screenshot.png!" }

      it { is_expected.to eq("![](My_Screenshot.png)") }
    end

    context "with spaces in the file name, mid-sentence" do
      let(:input) { "See !My File.png|width=100! here" }

      it { is_expected.to eq("See ![](My_File.png) here") }
    end

    context "with characters the uploader replaces beyond spaces" do
      let(:input) { "!My (final) report #2.png!" }

      it "mirrors the stored name rather than only swapping spaces" do
        expect(result).to eq("![](My__final__report__2.png)")
      end
    end

    context "with non-latin characters in the file name" do
      let(:input) { "!Übersicht Diagramm.png!" }

      it "keeps them, since the uploader treats them as word characters" do
        expect(result).to eq("![](Übersicht_Diagramm.png)")
      end
    end

    context "with a remote URL rather than an attachment" do
      let(:input) { "!http://example.com/a b.png|width=10!" }

      it "leaves the URL alone and wraps it so CommonMark accepts it" do
        expect(result).to eq("![](<http://example.com/a b.png>)")
      end
    end

    context "with exclamation marks in ordinary prose" do
      let(:input) { "Stop! Don't do that! Really!" }

      it "does not read them as an image" do
        expect(result).to eq("Stop! Don't do that! Really!")
      end
    end

    context "without a file extension" do
      let(:input) { "!no extension!" }

      it "is still an embed, as Jira treats it" do
        expect(result).to eq("![](no_extension)")
      end
    end

    context "with whitespace before the extension" do
      let(:input) { "!bad .png!" }

      it "is an embed, since only the first character may not be whitespace" do
        expect(result).to eq("![](bad_.png)")
      end
    end

    context "with whitespace directly after the delimiter" do
      let(:input) { "! leading.png!" }

      it "is not an embed" do
        expect(result).to eq("! leading.png!")
      end
    end
  end

  describe "block quotes" do
    context "with bq. syntax" do
      let(:input) { "bq. This is a quote.\nNext line." }

      it "adds a blank line after the quote to prevent lazy continuation" do
        expect(result).to eq("> This is a quote.\n\nNext line.")
      end
    end

    context "with an empty bq. line" do
      let(:input) { "bq. " }

      it "renders nothing rather than a bare quote marker" do
        expect(result).to eq("")
      end
    end

    context "with an empty bq. line between paragraphs" do
      let(:input) { "before\nbq. \nafter" }

      it { is_expected.to eq("before\n\nafter") }
    end

    context "with an empty {quote} block" do
      let(:input) { "{quote}\n{quote}" }

      it { is_expected.to eq("") }
    end

    context "with an empty {quote} inside a line" do
      let(:input) { "a {quote}{quote} b" }

      it { is_expected.to eq("a\n\nb") }
    end

    context "with {quote} block" do
      let(:input) { "{quote}\nLine one\nLine two\n{quote}" }

      it { is_expected.to eq("> Line one\n> Line two\n") }
    end

    context "with {quote} followed by content" do
      let(:input) { "{quote}\nQuoted text\n{quote}\n[link title|https://example.com/]" }

      it "adds a blank line after the quote so the link is not inside the quote" do
        expect(result).to eq("> Quoted text\n\n[link title](https://example.com/)")
      end
    end

    context "with {quote} blocks" do
      let(:input) do
        "{{This is preformatted}}\n{quote}This is a paragraph quote\n{quote}\nAnd\n{quote}This is a block quote\n{quote}\n"
      end

      it "adds a blank line after the quote so the link is not inside the quote" do
        expect(result).to eq("`This is preformatted`\n> This is a paragraph quote\n\nAnd\n> This is a block quote\n\n\n")
      end
    end

    context "with content on the opening {quote} line spanning several lines" do
      let(:input) { "{quote}Line one\nLine two\n{quote}" }

      it "quotes every line instead of leaking the opening tag" do
        expect(result).to eq("> Line one\n> Line two\n")
      end
    end

    context "with a closing {quote} trailing the last quoted line" do
      let(:input) { "{quote}\nLine one\nLine two{quote}" }

      it { is_expected.to eq("> Line one\n> Line two\n") }
    end

    context "with an unterminated {quote} carrying content on the opening line" do
      let(:input) { "{quote}Line one\nLine two" }

      it { is_expected.to eq("> Line one\n> Line two\n") }
    end

    context "with content after a {quote} opened on the same line" do
      let(:input) { "{quote}Line one\nLine two\n{quote}\nAfterwards" }

      it "ends the quote at the closing tag" do
        expect(result).to eq("> Line one\n> Line two\n\nAfterwards")
      end
    end

    context "with a {quote} opened and closed inside a line of text" do
      let(:input) { "see {quote}first{quote} here" }

      it "breaks the paragraph around the quote" do
        expect(result).to eq("see\n> first\n\nhere")
      end
    end

    context "with a {quote} opened and closed on a line of its own" do
      let(:input) { "{quote}first{quote}" }

      it { is_expected.to eq("> first\n") }
    end

    context "with several {quote} macros on one line" do
      let(:input) { "a {quote}one{quote} b {quote}two{quote} c" }

      it { is_expected.to eq("a\n> one\n\nb\n> two\n\nc") }
    end

    context "with a {quote} inside a heading" do
      let(:input) { "h1. see {quote}first{quote} here" }

      it "keeps the quoted text, since a heading cannot hold a block quote" do
        expect(result).to eq("# see first here")
      end
    end
  end

  describe "tables" do
    context "with a header row" do
      let(:input) { "||Name||Age||\n|Alice|30|\n|Bob|25|" }

      it "converts to an HTML table" do
        expect(result).to eq(
          "<table>" \
          "<thead><tr><th>Name</th><th>Age</th></tr></thead>" \
          "<tbody><tr><td>Alice</td><td>30</td></tr><tr><td>Bob</td><td>25</td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "without a header row" do
      let(:input) { "|Zeile 1|Zeile 1|\n|Zeile 2|Zeile 2|" }

      it "converts to an HTML table with no head" do
        expect(result).to eq(
          "<table>" \
          "<tbody><tr><td>Zeile 1</td><td>Zeile 1</td></tr><tr><td>Zeile 2</td><td>Zeile 2</td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a run of header rows" do
      let(:input) { "||Field||Details||\n||OS||Windows 11||\n||App||v3.2.1||" }

      it "keeps them in one table rather than one table each" do
        expect(result).to eq(
          "<table>" \
          "<thead><tr><th>Field</th><th>Details</th></tr></thead>" \
          "<tbody><tr><th>OS</th><th>Windows 11</th></tr>" \
          "<tr><th>App</th><th>v3.2.1</th></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a header row in the middle of the body" do
      let(:input) { "||A||\n|1|\n||B||\n|2|" }

      it "keeps the later header row as a body row of header cells" do
        expect(result).to eq(
          "<table><thead><tr><th>A</th></tr></thead>" \
          "<tbody><tr><td>1</td></tr><tr><th>B</th></tr><tr><td>2</td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a header column" do
      let(:input) { "||Name|Alice|\n||Age|30|" }

      it "marks the leading cell of each row as a header cell" do
        expect(result).to eq(
          "<table><tbody>" \
          "<tr><th>Name</th><td>Alice</td></tr>" \
          "<tr><th>Age</th><td>30</td></tr>" \
          "</tbody></table>\n"
        )
      end
    end

    context "with both a header row and a header column" do
      let(:input) { "||  ||A||B||\n||R1|1|2|" }

      it "keeps the header row in the head and the header cell in the body row" do
        expect(result).to eq(
          "<table>" \
          "<thead><tr><th></th><th>A</th><th>B</th></tr></thead>" \
          "<tbody><tr><th>R1</th><td>1</td><td>2</td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a single row" do
      let(:input) { "|a|b|" }

      it { is_expected.to eq("<table><tbody><tr><td>a</td><td>b</td></tr></tbody></table>\n") }
    end

    context "with a header but no rows" do
      let(:input) { "||Name||Age||" }

      it { is_expected.to eq("<table><thead><tr><th>Name</th><th>Age</th></tr></thead></table>\n") }
    end

    context "with Jira markup inside cells" do
      let(:input) { "||*Head*||\n|*bold*|_italic_|" }

      it "renders cell contents as HTML" do
        expect(result).to eq(
          "<table>" \
          "<thead><tr><th><strong>Head</strong></th></tr></thead>" \
          "<tbody><tr><td><strong>bold</strong></td><td><em>italic</em></td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a link inside a cell" do
      let(:input) { "|[text|https://example.com/]|b|" }

      it "does not split the row on the link separator" do
        expect(result).to eq(
          "<table><tbody><tr>" \
          '<td><a href="https://example.com/">text</a></td><td>b</td>' \
          "</tr></tbody></table>\n"
        )
      end
    end

    context "with an image carrying parameters inside a cell" do
      let(:input) { "|!img.png|thumbnail!|b|" }

      it "does not split the row on the parameter separator" do
        expect(result).to eq(
          "<table><tbody><tr>" \
          '<td><img src="img.png" alt=""></td><td>b</td>' \
          "</tr></tbody></table>\n"
        )
      end
    end

    context "with an image whose file name contains spaces" do
      let(:input) { "||Head||\n|!My Shot.png|thumbnail!|caption|" }

      it "does not split the row inside the file name or its parameters" do
        expect(result).to eq(
          "<table><thead><tr><th>Head</th></tr></thead>" \
          '<tbody><tr><td><img src="My_Shot.png" alt=""></td><td>caption</td></tr></tbody>' \
          "</table>\n"
        )
      end
    end

    context "with an image whose parameters carry alt text" do
      let(:input) { "||!head.png|a head!||\n|see !img.png|width=100! here|b|" }

      it "keeps the image in one cell in both header and body" do
        expect(result).to eq(
          "<table>" \
          '<thead><tr><th><img src="head.png" alt="a head"></th></tr></thead>' \
          '<tbody><tr><td>see <img src="img.png" alt=""> here</td><td>b</td></tr></tbody>' \
          "</table>\n"
        )
      end
    end

    context "with a trailing exclamation mark in each cell" do
      let(:input) { "|5!|3!|" }

      it "is not mistaken for an image" do
        expect(result).to eq("<table><tbody><tr><td>5!</td><td>3!</td></tr></tbody></table>\n")
      end
    end

    context "with characters that are significant in HTML" do
      let(:input) { "|a < b|x & y|" }

      it "escapes them" do
        expect(result).to eq("<table><tbody><tr><td>a &lt; b</td><td>x &amp; y</td></tr></tbody></table>\n")
      end
    end

    context "with content following the table" do
      let(:input) { "||Head||\n|a|\n*bold after*" }

      it "separates the table so the following markdown is still formatted" do
        expect(result).to eq(
          "<table><thead><tr><th>Head</th></tr></thead><tbody><tr><td>a</td></tr></tbody></table>\n\n**bold after**"
        )
      end
    end

    context "with markup outside a table" do
      let(:input) { "*bold* and |a|b| inline" }

      it "leaves it as markdown" do
        expect(result).to eq("**bold** and |a|b| inline")
      end
    end

    context "with a cell holding a multi-line code macro" do
      let(:input) { "||Head||\n|a|{code:java}\nx = 1\n{code}|" }

      it "keeps the row together and renders the macro as HTML" do
        expect(result).to eq(
          "<table><thead><tr><th>Head</th></tr></thead>" \
          "<tbody><tr><td>a</td><td><pre><code class=\"language-java\">x = 1</code></pre></td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a cell holding a macro spanning several lines" do
      let(:input) { "|a|{code:java}\nx = 1\ny = 2\n{code}|" }

      it "encodes the line breaks so the table stays a single HTML block" do
        expect(result).to eq(
          "<table><tbody><tr><td>a</td>" \
          "<td><pre><code class=\"language-java\">x = 1&#10;y = 2</code></pre></td>" \
          "</tr></tbody></table>\n"
        )
      end
    end

    context "with a blank line inside a cell macro" do
      let(:input) { "|a|{code}\nx\n\ny\n{code}|\n|c|d|" }

      it "does not let the blank line end the HTML block" do
        expect(result).to eq(
          "<table><tbody>" \
          "<tr><td>a</td><td><pre><code>x&#10;&#10;y</code></pre></td></tr>" \
          "<tr><td>c</td><td>d</td></tr>" \
          "</tbody></table>\n"
        )
      end
    end

    context "with a cell holding a panel" do
      let(:input) { "||H||\n|a|{panel:title=Note}\nBe careful\n{panel}|" }

      it "flattens the panel instead of leaking its markup" do
        expect(result).to eq(
          "<table><thead><tr><th>H</th></tr></thead>" \
          "<tbody><tr><td>a</td><td><strong>Note</strong><br>Be careful</td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a cell holding an untitled panel" do
      let(:input) { "|a|{panel}\nbody\n{panel}|" }

      it { is_expected.to eq("<table><tbody><tr><td>a</td><td>body</td></tr></tbody></table>\n") }
    end

    context "with a cell separator inside a code macro" do
      let(:input) { "|a|{code}\nx || y\n{code}|" }

      it "does not split the row there" do
        expect(result).to eq(
          "<table><tbody><tr><td>a</td><td><pre><code>x || y</code></pre></td></tr></tbody></table>\n"
        )
      end
    end

    context "with an escaped cell separator" do
      let(:input) { "|a\\|b|c|" }

      it "keeps it inside the cell" do
        expect(result).to eq("<table><tbody><tr><td>a|b</td><td>c</td></tr></tbody></table>\n")
      end
    end

    context "with an escaped separator in a header cell" do
      let(:input) { "||a\\|b||c||\n|x|y|" }

      it "keeps the escaped separator inside the cell" do
        expect(result).to eq(
          "<table>" \
          "<thead><tr><th>a|b</th><th>c</th></tr></thead>" \
          "<tbody><tr><td>x</td><td>y</td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with an escaped separator abutting a live one" do
      let(:input) { "||a\\||b||c||" }

      it "swallows the live one, as Jira's escape token does" do
        expect(result).to eq("<table><thead><tr><th>a|b</th><th>c</th></tr></thead></table>\n")
      end
    end

    context "with both separators escaped" do
      let(:input) { "||a\\|\\|b||c||" }

      it "keeps both in the cell" do
        expect(result).to eq("<table><thead><tr><th>a||b</th><th>c</th></tr></thead></table>\n")
      end
    end

    context "with an escaped separator abutting a live one in a data row" do
      let(:input) { "|a\\||b|" }

      it "stays a single cell" do
        expect(result).to eq("<table><tbody><tr><td>a|b</td></tr></tbody></table>\n")
      end
    end

    context "with a separator inside a header cell macro" do
      let(:input) { "||{code}a||b{code}||c||" }

      it "does not split the header there" do
        expect(result).to eq(
          "<table><thead><tr>" \
          "<th><pre><code>a||b</code></pre></th><th>c</th>" \
          "</tr></thead></table>\n"
        )
      end
    end

    context "with a link whose separator is escaped" do
      let(:input) { "|[text\\|https://example.com/]|b|" }

      it "keeps the link intact" do
        expect(result).to eq(
          "<table><tbody><tr>" \
          '<td><a href="https://example.com/">text</a></td><td>b</td>' \
          "</tr></tbody></table>\n"
        )
      end
    end

    context "without the closing separator" do
      let(:input) { "||A||B\n|1|2" }

      it "still converts, since Jira allows it to be left off" do
        expect(result).to eq(
          "<table>" \
          "<thead><tr><th>A</th><th>B</th></tr></thead>" \
          "<tbody><tr><td>1</td><td>2</td></tr></tbody>" \
          "</table>\n"
        )
      end
    end

    context "with a header column and no closing separator" do
      let(:input) { "||Name|Alice" }

      it { is_expected.to eq("<table><tbody><tr><th>Name</th><td>Alice</td></tr></tbody></table>\n") }
    end

    context "with a line that starts with a separator but is not a row" do
      let(:input) { "|not a table" }

      it "needs a second separator to be a row" do
        expect(result).to eq("|not a table")
      end
    end

    context "with a line holding only separators" do
      let(:input) { "before\n||\nafter" }

      it "is not a row" do
        expect(result).to eq("before\n\n||\n\nafter")
      end
    end

    context "with a row whose macro never closes" do
      let(:input) { "|a|{code:java}\nnever closed" }

      it "does not swallow the rest of the document" do
        expect(result).to eq("|a|{code:java}\n\nnever closed")
      end
    end

    context "with two unclosed rows that open the same macro" do
      let(:input) { "|a|{code:java}\nfirst\n|b|{code:java}\nsecond" }

      it "does not read the second opener as closing the first" do
        expect(result).to eq("|a|{code:java}\n\nfirst\n\n|b|{code:java}\n\nsecond")
      end
    end

    context "with an unclosed macro that a later bare tag would close" do
      let(:input) { "|a|{code:java}\nstray\n\nUnrelated paragraph.\n\n{code}\nreal block\n{code}" }

      it "does not pull the document into the row" do
        expect(result).not_to include("<table")
        expect(result).to include("Unrelated paragraph.")
        expect(result).to end_with("```\nreal block\n```")
      end
    end

    context "with a header and a row whose macro never closes" do
      let(:input) { "||Head||\n|a|{code:java}\nnever closed\ntrailing text" }

      it "keeps the header table and the lines after the unclosed row" do
        expect(result).to eq(
          "<table><thead><tr><th>Head</th></tr></thead></table>\n\n" \
          "|a|{code:java}\n\nnever closed\n\ntrailing text"
        )
      end
    end

    context "with a closed row followed by a row whose macro never closes" do
      let(:input) { "|a|b|\n|c|{code}\nnever closed\ntrailing text" }

      it "keeps the closed row and the lines after the unclosed row" do
        expect(result).to eq(
          "<table><tbody><tr><td>a</td><td>b</td></tr></tbody></table>\n\n" \
          "|c|{code}\n\nnever closed\n\ntrailing text"
        )
      end
    end

    # The table is emitted as raw HTML, so only the formatting pipeline shows
    # whether CommonMark kept it in one piece.
    describe "rendered through the text formatting pipeline" do
      subject(:html) { OpenProject::TextFormatting::Renderer.format_text(result) }

      context "with an image whose attachment exists" do
        let(:work_package) { create(:work_package) }
        let(:input) { "|!My Shot.png|thumbnail!|b|" }

        before do
          create(:attachment, container: work_package, content_type: "image/png", filename: "My Shot.png")
        end

        it "resolves the cell image to the attachment" do
          rendered = OpenProject::TextFormatting::Renderer.format_text(result, object: work_package)
          expect(rendered).to match(%r{src="[^"]*/api/v3/attachments/\d+/content"})
        end
      end

      context "with a blank line inside a cell macro" do
        let(:input) { "|a|{code}\nx\n\ny\n{code}|\n|c|d|" }

        it "keeps the code block and the later rows inside the table" do
          expect(html).to include("<pre class=\"op-uc-code-block\">x\n\ny</pre>")
          expect(html).to include("<td class=\"op-uc-table--cell\">c</td>")
          expect(html).not_to include("<p class=\"op-uc-p\">")
        end
      end

      context "without a header row" do
        let(:input) { "|1|2|\n|3|4|" }

        it "is still one decorated table with no head" do
          expect(html.scan("<table").size).to eq(1)
          expect(html).to include("op-uc-table")
          expect(html).not_to include("<thead")
        end
      end

      context "with a header column" do
        let(:input) { "||Name|Alice|" }

        it "keeps the header cell and the data cell apart" do
          expect(html).to include(">Name</th>")
          expect(html).to include(">Alice</td>")
        end
      end

      context "with a run of header rows" do
        let(:input) { "||Field||Details||\n||OS||Windows 11||\n||App||v3.2.1||" }

        it "is one table rather than one per row" do
          expect(html.scan("<table").size).to eq(1)
          expect(html.scan("<tr").size).to eq(3)
        end
      end

      context "with markup that would be HTML if it were not escaped" do
        let(:input) { "|<script>alert(1)</script>|b|" }

        it "escapes it into the cell" do
          expect(html).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
          expect(html).not_to include("<script")
        end
      end

      context "with a cell holding a macro spanning several lines" do
        let(:input) { "|a|{code:java}\nx = 1\ny = 2\n{code}|" }

        it "decodes the encoded line breaks back into the code block" do
          expect(html).to include("<pre class=\"op-uc-code-block\">x = 1\ny = 2</pre>")
          expect(html).not_to include("&amp;#10;")
        end
      end

      context "with a cell holding a panel" do
        let(:input) { "|a|{panel:title=Note}\nBe careful\n{panel}|" }

        it "keeps the panel inside the cell" do
          expect(html).to include("<strong>Note</strong><br>")
          expect(html.scan("<table").size).to eq(1)
        end
      end

      context "with content following the table" do
        let(:input) { "||Head||\n|a|\n*bold after*" }

        it "formats the following markdown instead of swallowing it" do
          expect(html).to include("<p class=\"op-uc-p\"><strong>bold after</strong></p>")
        end
      end
    end
  end

  describe "lists" do
    context "with ordered list" do
      let(:input) { "# First\n# Second\n# Third" }

      it { is_expected.to eq("1. First\n1. Second\n1. Third") }
    end

    context "with nested ordered list" do
      let(:input) { "# First\n## Nested\n# Second" }

      it { is_expected.to eq("1. First\n   1. Nested\n1. Second") }
    end

    context "with unordered list" do
      let(:input) { "* First\n* Second" }

      it { is_expected.to eq("- First\n- Second") }
    end

    context "with nested unordered list" do
      let(:input) { "* First\n** Nested\n* Second" }

      it { is_expected.to eq("- First\n   - Nested\n- Second") }
    end

    context "with leading whitespace (Jira editor format)" do
      let(:input) { " * is\n * an\n * unordered\n ** list" }

      it { is_expected.to eq("- is\n- an\n- unordered\n   - list") }
    end

    context "with leading whitespace on ordered list" do
      let(:input) { " # is\n # an\n # ordered\n ## list" }

      it { is_expected.to eq("1. is\n1. an\n1. ordered\n   1. list") }
    end

    context "with mixed list types (#*)" do
      let(:input) { "# ordered\n#* unordered child\n# ordered again" }

      it { is_expected.to eq("1. ordered\n   - unordered child\n1. ordered again") }
    end

    context "with mixed list types (*#)" do
      let(:input) { "* unordered\n*# ordered child\n* unordered again" }

      it { is_expected.to eq("- unordered\n   1. ordered child\n- unordered again") }
    end

    context "with a block that opens deeper than the top level" do
      let(:input) { "#* mixed ordered then bullet\n*# mixed bullet then ordered" }

      it "keeps the items rather than dropping the whole block" do
        expect(result).to eq("- mixed ordered then bullet\n- mixed bullet then ordered")
      end
    end

    context "with a block of only nested markers" do
      let(:input) { "** a\n** b" }

      it { is_expected.to eq("- a\n- b") }
    end

    context "with a deeper item before any shallow one" do
      let(:input) { "** deep\n* shallow" }

      it "keeps the leading item" do
        expect(result).to eq("- deep\n- shallow")
      end
    end

    context "with a skipped nesting level" do
      let(:input) { "* a\n*** deeper" }

      it { is_expected.to eq("- a\n   - deeper") }
    end

    context "with dash list marker" do
      let(:input) { "- different\n- bullet\n- types" }

      it { is_expected.to eq("- different\n- bullet\n- types") }
    end
  end

  describe "horizontal rule" do
    let(:input) { "Above\n----\nBelow" }

    it { is_expected.to eq("Above\n<hr>\n\nBelow") }
  end

  describe "dashes" do
    context "with em dash (---)" do
      let(:input) { "word---word" }

      it { is_expected.to eq("word\u2014word") }
    end

    context "with en dash (--)" do
      let(:input) { "word--word" }

      it { is_expected.to eq("word\u2013word") }
    end

    context "with dashes and line breaks" do
      let(:input) { "HR:\n----\nEm-Dash\n---\nEn-Dash\n--\n" }

      it { is_expected.to eq("HR:\n<hr>\n\nEm-Dash\n\n\u2014\n\nEn-Dash\n\n\u2013\n\n") }
    end
  end

  describe "simple line breaks" do
    let(:input) { "this text is\nin two paragraphs" }

    it { is_expected.to eq("this text is\n\nin two paragraphs") }
  end

  describe "forced line breaks" do
    let(:input) { "Line one\\\\Line two" }

    it { is_expected.to eq("Line one  \nLine two") }
  end

  describe "emoticons" do
    context "with text smileys" do
      let(:input) { "Great work :) but not done :(" }

      it { is_expected.to eq("Great work \u{1F642} but not done \u{2639}\u{FE0F}") }
    end

    context "with parenthesized emoticons" do
      let(:input) { "Approved (y) Rejected (n)" }

      it { is_expected.to eq("Approved \u{1F44D} Rejected \u{1F44E}") }
    end

    context "with flag emoticons" do
      let(:input) { "(flag) Important (flagoff) Resolved" }

      it { is_expected.to eq("\u{1F6A9} Important \u{1F3F3}\u{FE0F} Resolved") }
    end
  end

  describe "color macros" do
    let(:input) { "{color:red}warning text{color}" }

    it { is_expected.to eq("warning text") }
  end

  describe "panel macros" do
    context "with title" do
      let(:input) { "{panel:title=My Panel}\nPanel content\n{panel}" }

      it { is_expected.to eq("**My Panel**\nPanel content") }
    end

    context "without title" do
      let(:input) { "{panel}\nPanel content\n{panel}" }

      it { is_expected.to eq("Panel content") }
    end

    context "with an empty title" do
      let(:input) { "{panel:title=}\nPanel content\n{panel}" }

      it "omits the title rather than emitting bare emphasis" do
        expect(result).to eq("Panel content")
      end
    end

    context "with a blank title" do
      let(:input) { "{panel:title= }\nPanel content\n{panel}" }

      it { is_expected.to eq("Panel content") }
    end

    context "with an empty title and content on the opening line" do
      let(:input) { "{panel:title=}Panel content{panel}" }

      it { is_expected.to eq("Panel content") }
    end

    context "with title and style parameters" do
      let(:input) { "{panel:title=My Title|borderStyle=dashed|borderColor=#ccc|bgColor=#FFFFCE}\nStyled content\n{panel}" }

      it "extracts the title and ignores style parameters" do
        expect(result).to eq("**My Title**\nStyled content")
      end
    end

    context "with a panel in the middle of a line" do
      let(:input) { "text {panel}body{panel} more" }

      it { is_expected.to eq("text body more") }
    end

    context "with a titled panel in the middle of a line" do
      let(:input) { "text {panel:title=T}body{panel} more" }

      it "emphasizes the title above the content" do
        expect(result).to eq("text **T**\nbody more")
      end
    end

    context "with markup in the body" do
      let(:input) { "{panel}\n*bold* and [~jdoe] and [text|https://e.com]\n{panel}" }

      it "converts the body rather than passing it through" do
        expect(result).to eq("**bold** and @jdoe and [text](https://e.com)")
      end
    end

    context "with markup in the body of every panel form" do
      it "converts all of them alike" do
        expect(described_class.new("{panel}\n*bold*\n{panel}").convert).to eq("**bold**")
        expect(described_class.new("{panel}*bold*{panel}").convert).to eq("**bold**")
        expect(described_class.new("text {panel}*bold*{panel} more").convert).to eq("text **bold** more")
      end
    end

    context "with markup in the title" do
      let(:input) { "|a|{panel:title=*T*}\nx\n{panel}|" }

      it "emphasizes the title once, since Jira does not parse it as markup" do
        expect(result).to eq("<table><tbody><tr><td>a</td><td><strong>*T*</strong><br>x</td></tr></tbody></table>\n")
      end
    end

    context "with a title holding characters significant in HTML" do
      let(:input) { "|a|{panel:title=A & B}\nx\n{panel}|" }

      it { is_expected.to eq("<table><tbody><tr><td>a</td><td><strong>A &amp; B</strong><br>x</td></tr></tbody></table>\n") }
    end

    context "when panel macros markers are all over the place" do
      let(:input) do
        "{panel}\n" \
          "panel text {panel}\n" \
          "{panel}panel text{panel}\n" \
          "{panel}\npanel text{panel}\n" \
          "{panel}panel text\n{panel}"
      end
      let(:output) do
        "panel text\n" \
          "panel text\n" \
          "panel text\n" \
          "panel text"
      end

      it "does produce all code blocks" do
        expect(result).to eq(output)
      end
    end

    context "having malformed parameters" do
      context "with empty segments" do
        let(:input) { "{panel:title=Test||another=value}\nPanel content\n{panel}" }

        it "gracefully handles empty parameter segments" do
          expect(result).to eq("**Test**\nPanel content")
        end
      end

      context "with empty string segments" do
        let(:input) { "{panel:title=Test| |another=value}\nPanel content\n{panel}" }

        it "gracefully handles empty string segments" do
          expect(result).to eq("**Test**\nPanel content")
        end
      end

      context "with empty key and value" do
        let(:input) { "{panel:title=Test|=|another=value}\nPanel content\n{panel}" }

        it "gracefully handles empty key and value" do
          expect(result).to eq("**Test**\nPanel content")
        end
      end

      context "with empty key" do
        let(:input) { "{panel:title=Test|=value|another=value}\nPanel content\n{panel}" }

        it "gracefully handles empty key" do
          expect(result).to eq("**Test**\nPanel content")
        end
      end

      context "with empty value" do
        let(:input) { "{panel:title=Test|key=|another=value}\nPanel content\n{panel}" }

        it "gracefully handles empty value" do
          expect(result).to eq("**Test**\nPanel content")
        end
      end

      context "without equals sign" do
        let(:input) { "{panel:title=Test|invalid_param}\nPanel content\n{panel}" }

        it "gracefully handles missing equals sign" do
          expect(result).to eq("**Test**\nPanel content")
        end
      end
    end
  end

  describe "combined formatting" do
    let(:input) do
      <<~JIRA.chomp
        h1. Project Overview

        This project is *important* and _urgent_.

        {code:ruby}
        def hello
          puts "world"
        end
        {code}

        bq. A famous quote

        ||Feature||Status||
        |Auth|Done|
        |API|WIP|

        ----

        See [docs|https://example.com] for more.
      JIRA
    end

    it "converts all markup correctly" do
      expect(result).to include("# Project Overview")
      expect(result).to include("**important**")
      expect(result).to include("*urgent*")
      expect(result).to include("```ruby\ndef hello")
      expect(result).to include("> A famous quote")
      expect(result).to include("<thead><tr><th>Feature</th><th>Status</th></tr></thead>")
      expect(result).to include("<tbody><tr><td>Auth</td><td>Done</td></tr><tr><td>API</td><td>WIP</td></tr></tbody>")
      expect(result).to include("<hr>")
      expect(result).to include("[docs](https://example.com)")
    end
  end
end

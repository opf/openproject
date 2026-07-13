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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
  end

  describe "block quotes" do
    context "with bq. syntax" do
      let(:input) { "bq. This is a quote.\nNext line." }

      it "adds a blank line after the quote to prevent lazy continuation" do
        expect(result).to eq("> This is a quote.\n\nNext line.")
      end
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
  end

  describe "tables" do
    context "with header row" do
      let(:input) { "||Name||Age||\n|Alice|30|\n|Bob|25|" }

      it "converts to markdown table with separator" do
        expect(result).to eq("| Name | Age |\n| --- | --- |\n|Alice|30|\n|Bob|25|")
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

    context "with title and style parameters" do
      let(:input) { "{panel:title=My Title|borderStyle=dashed|borderColor=#ccc|bgColor=#FFFFCE}\nStyled content\n{panel}" }

      it "extracts the title and ignores style parameters" do
        expect(result).to eq("**My Title**\nStyled content")
      end
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
      expect(result).to include("| Feature | Status |")
      expect(result).to include("| --- | --- |")
      expect(result).to include("---")
      expect(result).to include("[docs](https://example.com)")
    end
  end
end

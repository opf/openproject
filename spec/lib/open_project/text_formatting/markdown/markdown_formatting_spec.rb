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
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting::Formats::Markdown::Formatter do
  it "preserves sibling text while decorating its elements" do
    document = Nokogiri::HTML.fragment(to_html("<div><p>one</p>\n<p>two</p></div>", autolink: { enabled: false }))
    paragraphs = document.css("div > p.op-uc-p")

    expect(paragraphs.map(&:text)).to eq(%w[one two])
    expect(paragraphs.first.next_sibling).to be_text
    expect(paragraphs.first.next_sibling.text).to eq("\n")
  end

  it "drops carriage returns before parsing Markdown" do
    html = to_html("a\rb\r\n\r\n```\r\nx\r\n```")
    document = Nokogiri::HTML.fragment(html)

    expect(html).not_to include("\r")
    expect(document.at_css("p").text).to eq("ab")
    expect(document.at_css("pre").text).to eq("x\n")
  end

  it "inlines syntax highlighting styles for mail" do
    pre = Nokogiri::HTML.fragment(to_html("```ruby\ndef x; end\n```", inline_css: true)).at_css("pre")

    expect(pre["class"].split).to include("highlight-ruby")
    expect(pre.css("span[style]")).to be_present
    expect(pre.css("span[class]")).to be_empty
    expect(pre.text).to eq("def x; end\n")
  end

  it "leaves code in an unknown language unhighlighted" do
    pre = Nokogiri::HTML.fragment(to_html("```nosuchlang\nx\n```")).at_css("pre")

    expect(pre["class"].split).to eq(%w[op-uc-code-block])
    expect(pre.children.map(&:name)).to eq(%w[text])
    expect(pre.text).to eq("x\n")
  end

  it "leaves code unhighlighted when highlighting times out" do
    allow(Rouge).to receive(:highlight).and_raise(Timeout::Error)
    pre = Nokogiri::HTML.fragment(to_html("```ruby\nx = 1\n```")).at_css("pre")

    expect(pre["class"].split).to eq(%w[op-uc-code-block])
    expect(pre.text).to eq("x = 1\n")
  end

  it "leaves a bare task marker followed by a newline as text" do
    document = Nokogiri::HTML.fragment(to_html("<ul><li>[x]\n</li></ul>"))
    expect(document.at_css("ul.op-uc-list_task-list li").text).to eq("[x]\n")
    expect(document.css("input")).to be_empty
  end

  it "renders a checked editor task inside its table cell" do
    html = <<~HTML
      <table><tr><td><ul><li><label class="todo-list__label">
        <input type="checkbox" checked="checked"><span>Send invoice</span>
      </label></li></ul></td></tr></table>
    HTML
    item = Nokogiri::HTML.fragment(to_html(html)).at_css("td ul.op-uc-list_task-list > li")

    expect(item.css("input[type=checkbox][checked][disabled]").size).to eq(1)
    expect(item.text.strip).to eq("Send invoice")
  end

  it "links duplicate headings to distinct destinations in document order" do
    markdown = "<macro class=\"toc op-uc-placeholder\"></macro>\n\n## Agenda\n\n## Agenda"
    document = Nokogiri::HTML.fragment(to_html(markdown))
    ids = document.css("h2").pluck("id")

    expect(ids).to match(["op-frag-agenda", a_string_starting_with("op-frag-agenda")])
    expect(ids.uniq.size).to eq(2)
    expect(document.css("nav a").pluck("href")).to eq(ids.map { |id| "##{id}" })
  end

  it "wraps the existing image container together with its text and link" do
    document = Nokogiri::HTML.fragment(to_html('<div>Before<img src="/a.png"><a href="/details">After</a></div>'))

    expect(document.css("figure").size).to eq(1)
    content = document.at_css("figure.op-uc-figure > div.op-uc-figure--content")
    expect(content.children.compact_blank.map(&:name)).to eq(%w[text img a])
    expect(content.text.strip).to eq("BeforeAfter")
    expect(content.at_css("img.op-uc-image")["src"]).to eq("/a.png")
    expect(content.at_css("a.op-uc-link")["href"]).to eq("/details")
  end

  it "unwraps an orphan list item and keeps its inline content" do
    document = Nokogiri::HTML.fragment(to_html("<li>Keep <em>this</em></li>"))

    expect(document.css("li")).to be_empty
    expect(document.text.strip).to eq("Keep this")
    expect(document.at_css("em").text).to eq("this")
  end

  it "preserves an already-prefixed fragment and its destination" do
    html = '<p id="op-frag-agenda">Agenda</p><a href="#op-frag-agenda">Jump</a>'
    document = Nokogiri::HTML.fragment(to_html(html))

    expect(document.at_css("p")["id"]).to eq("op-frag-agenda")
    expect(document.at_css("a")["href"]).to eq("#op-frag-agenda")
  end

  it "modifierses" do
    assert_html_output(
      "**bold**" => "<strong>bold</strong>",
      "before **bold**" => "before <strong>bold</strong>",
      "**bold** after" => "<strong>bold</strong> after",
      "**two words**" => "<strong>two words</strong>",
      "**two*words**" => "<strong>two*words</strong>",
      "**two * words**" => "<strong>two * words</strong>",
      "**two** **words**" => "<strong>two</strong> <strong>words</strong>",
      "**(two)** **(words)**" => "<strong>(two)</strong> <strong>(words)</strong>"
    )
  end

  it "strips script tags" do
    assert_html_output(
      "this is a <script>" => "this is a "
    )
  end

  it "doubles dashes should not strikethrough" do
    assert_html_output(
      "double -- dashes -- test" => "double -- dashes -- test",
      "double -- **dashes** -- test" => "double -- <strong>dashes</strong> -- test"
    )
  end

  it "does not mangle brackets" do
    expect(to_html("[msg1][msg2]")).to eq '<p class="op-uc-p">[msg1][msg2]</p>'
  end

  private

  def assert_html_output(to_test, options = {})
    options = { expect_paragraph: true }.merge options
    expect_paragraph = options.delete :expect_paragraph

    to_test.each do |text, expected|
      expected = "<p class=\"op-uc-p\">#{expected}</p>" if expect_paragraph
      expect(to_html(text, options)).to be_html_eql expected
    end
  end

  def to_html(text, options = {})
    described_class.new(options).to_html(text)
  end
end

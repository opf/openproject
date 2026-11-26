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

  it "labels Markdown task checkboxes with their text" do
    page = Capybara.string(to_html("- [ ] open\n- [x] done"))

    expect(page).to have_unchecked_field("open", exact: true, disabled: true)
    expect(page).to have_checked_field("done", exact: true, disabled: true)
  end

  it "keeps bullets on plain items of a mixed list" do
    page = Capybara.string(to_html("- [ ] task\n- plain"))

    expect(page).to have_css("li.op-uc-list--item_task", count: 1)
    expect(page).to have_css("li:not(.op-uc-list--item_task)", text: "plain")
  end

  it "renders the OP-20319 table in editor order" do
    page = Capybara.string(to_html(<<~HTML))
      <figure class="table op-uc-figure_align-center op-uc-figure"><table class="op-uc-table"><thead class="op-uc-table--head"><tr class="op-uc-table--row"><th class="op-uc-table--cell op-uc-table--cell_head" scope="col"><p class="op-uc-p">Table</p></th></tr></thead><tbody><tr class="op-uc-table--row"><td class="op-uc-table--cell"><ul class="todo-list op-uc-list_task-list op-uc-list"><li class="op-uc-list--item" data-list-item-id="ebc1f3f26c2465d0a24ce1f3df0a954bc"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">1 Flat todo list</span></label></li><li class="op-uc-list--item" data-list-item-id="ee60c18fbcf3eeb93ccfe15c7fe0ca556"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">2</span></label></li><li class="op-uc-list--item" data-list-item-id="e20b727c5bc58ac5f02a15938898b1ecc"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">3</span></label></li><li class="op-uc-list--item" data-list-item-id="ed4302452d28ca5a5f1b5282ec7e09ecf"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">4</span></label></li></ul></td></tr><tr class="op-uc-table--row"><td class="op-uc-table--cell"><ul class="todo-list op-uc-list_task-list op-uc-list"><li class="op-uc-list--item" data-list-item-id="e85680bb83510d21bcde20ed4ccd27b5d"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">1 Nested todo list</span></label><ul class="todo-list op-uc-list_task-list op-uc-list"><li class="op-uc-list--item" data-list-item-id="effca5d56fb5bda7f7e5086954541c210"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">1.1 Test</span></label></li><li class="op-uc-list--item" data-list-item-id="e5504c00dcf8ee58006dcd0246f9fb8b7"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">1.2 Test</span></label></li></ul></li><li class="op-uc-list--item" data-list-item-id="eac31a4860d80b9ab6371a77b487144a2"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">2</span></label></li><li class="op-uc-list--item" data-list-item-id="e8df29811f9136289017eb5cc5f6e79e3"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">3</span></label></li></ul></td></tr></tbody></table></figure>
    HTML
    item = page.find("tbody tr:nth-of-type(2) td > ul > li:first-child")

    expect(item).to have_unchecked_field("1 Nested todo list", exact: true, disabled: true)
    expect(item.native.element_children.map(&:name)).to eq(%w[label ul])
    expect(item).to have_unchecked_field("1.1 Test", exact: true, disabled: true)
    expect(item).to have_unchecked_field("1.2 Test", exact: true, disabled: true)
  end

  it "renders the checked editor task inside its table cell" do
    html = <<~HTML
      <table><tr><td><ul><li><label class="todo-list__label">
        <input type="checkbox" checked="checked"><span>Send invoice</span>
      </label></li></ul></td></tr></table>
    HTML

    expect(Capybara.string(to_html(html))).to have_checked_field("Send invoice", exact: true, disabled: true)
  end

  it "leaves a bare task marker as text" do
    page = Capybara.string(to_html("- [x]\n"))

    expect(page).to have_css("li", exact_text: "[x]")
    expect(page).to have_no_field
  end

  describe "with a mention in a task item" do
    shared_let(:user) { create(:user) }

    current_user { create(:admin) }

    it "keeps mentions and links in the label" do
      attributes = %(class="mention" data-id="#{user.id}" data-type="user" data-text="@#{user.name}")
      mention = "<mention #{attributes}>@#{user.name}</mention>"
      page = Capybara.string(to_html("- [ ] ping [docs](/docs) #{mention}"))
      label = page.find("label")

      expect(page).to have_unchecked_field("ping docs #{user.name}", exact: true, disabled: true)
      expect(label).to have_link("docs", href: "/docs")
      expect(label).to have_link(user.name, class: "user-mention")
    end
  end

  it "labels a three-level nested editor list" do
    html = <<~HTML.squish
      <table><tr><td><ul class="todo-list op-uc-list_task-list">
        <li><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description">Level one</span></label>
          <ul class="todo-list op-uc-list_task-list">
            <li><label class="todo-list__label"><input type="checkbox" disabled="disabled" checked="checked"><span class="todo-list__label__description">Level two</span></label>
              <ul class="todo-list op-uc-list_task-list">
                <li><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description">Level three</span></label></li>
              </ul>
            </li>
          </ul>
        </li>
      </ul></td></tr></table>
    HTML
    page = Capybara.string(to_html(html))

    expect(page).to have_unchecked_field("Level one", exact: true, disabled: true)
    expect(page).to have_checked_field("Level two", exact: true, disabled: true)
    expect(page).to have_unchecked_field("Level three", exact: true, disabled: true)
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

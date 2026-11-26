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

RSpec.describe OpenProject::TextFormatting::Filters::TaskItemTransformer do
  def sanitize(html, plain_text: false)
    base = OpenProject::TextFormatting::Filters::SanitizationFilter::BASE_ALLOWLIST
    config = Sanitize::Config.merge(
      base,
      transformers: base[:transformers] + [described_class.new(plain_text:)],
      attributes: { "li" => %w[data-task], "span" => %w[data-task], "ul" => %w[data-task-list], "ol" => %w[data-task-list] }
    )
    Nokogiri::HTML.fragment(Sanitize.fragment(html, config))
  end

  it "maps a Markdown task item" do
    doc = sanitize('<ul><li><input type="checkbox" checked="" disabled="" /> done <em>now</em></li></ul>')

    expect(doc.at_css("ul[data-task-list]")).to be_present
    expect(doc.at_css('li[data-task] > span[data-task="checked"]').inner_html).to eq("done <em>now</em>")
    expect(doc.at_css("input")).to be_nil
  end

  it "keeps a nested list after the item text" do
    doc = sanitize(<<~HTML.squish)
      <ul><li><input type="checkbox" disabled="" /> a<ul><li><input type="checkbox" disabled="" /> b</li></ul></li></ul>
    HTML

    expect(doc.at_css("li").element_children.map(&:name)).to eq(%w[span ul])
    expect(doc.css("span[data-task]").pluck("data-task")).to eq(%w[unchecked unchecked])
    expect(doc.css("span[data-task]").map(&:text)).to eq(%w[a b])
  end

  it "labels the first paragraph of a loose item" do
    doc = sanitize(%(<ul><li><input type="checkbox" disabled="" /> \n<p>first</p><p>second</p></li></ul>))

    expect(doc.at_css("li > p:first-of-type > span[data-task]").text).to eq("first")
    expect(doc.css("li > p").map(&:text)).to eq(%w[first second])
  end

  it "maps an editor to-do item before its nested list" do
    doc = sanitize(<<~HTML.squish)
      <table><tbody><tr class="op-uc-table--row"><td class="op-uc-table--cell"><ul class="todo-list op-uc-list_task-list op-uc-list"><li class="op-uc-list--item" data-list-item-id="e85680bb83510d21bcde20ed4ccd27b5d"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">1 Nested todo list</span></label><ul class="todo-list op-uc-list_task-list op-uc-list"><li class="op-uc-list--item" data-list-item-id="effca5d56fb5bda7f7e5086954541c210"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">1.1 Test</span></label></li><li class="op-uc-list--item" data-list-item-id="e5504c00dcf8ee58006dcd0246f9fb8b7"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">1.2 Test</span></label></li></ul></li><li class="op-uc-list--item" data-list-item-id="eac31a4860d80b9ab6371a77b487144a2"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">2</span></label></li><li class="op-uc-list--item" data-list-item-id="e8df29811f9136289017eb5cc5f6e79e3"><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description op-uc-p">3</span></label></li></ul></td></tr></tbody></table>
    HTML

    outer = doc.at_css("td > ul > li")
    first = outer.element_children.first
    expect(first.name).to eq("span")
    expect(first["data-task"]).to eq("unchecked")
    expect(first.text).to eq("1 Nested todo list")
    expect(first.next_element.name).to eq("ul")
    expect(doc.css("span[data-task]").map(&:text)).to eq(["1 Nested todo list", "1.1 Test", "1.2 Test", "2", "3"])
    expect(doc.css("label, input")).to be_empty
  end

  it "recognizes an unclassed label inside a task list" do
    doc = sanitize(<<~HTML.squish)
      <ul class="op-uc-list_task-list"><li><label><input type="checkbox" checked="checked"><span>x</span></label></li></ul>
    HTML

    expect(doc.at_css('li[data-task] > span[data-task="checked"]').text).to eq("x")
  end

  it "merges CKEditor's split labels" do
    doc = sanitize(<<~HTML.squish)
      <ul class="todo-list"><li><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description">Foo </span></label><label class="todo-list__label todo-list__label_without-description"><a href="/x">Bar</a></label></li></ul>
    HTML

    span = doc.at_css("li > span[data-task]")
    expect(span.text).to eq("Foo Bar")
    expect(span.at_css("a").text).to eq("Bar")
  end

  it "finds an editor label wrapped in code" do
    doc = sanitize(<<~HTML.squish)
      <ul class="op-uc-list_task-list"><li><code><label class="op-uc-list__label"><input type="checkbox" disabled="disabled"><span class="op-uc-list__label__description">asdf</span></label></code></li></ul>
    HTML

    expect(doc.at_css('li[data-task] > span[data-task="unchecked"] > code').text).to eq("asdf")
    expect(doc.css("label, input")).to be_empty
  end

  it "finds an editor label wrapped in a link" do
    doc = sanitize(<<~HTML.squish)
      <ul class="op-uc-list_task-list"><li><a href="https://example.com/"><label class="op-uc-list__label"><input type="checkbox" checked="checked"><span class="op-uc-list__label__description">asdfasd</span></label><span> asdf</span></a></li></ul>
    HTML

    expect(doc.at_css('li[data-task] > span[data-task="checked"] > a').text).to eq("asdfasd asdf")
    expect(doc.css("label, input")).to be_empty
  end

  it "finds an editor checkbox wrapped in strong" do
    doc = sanitize(<<~HTML.squish)
      <ul class="op-uc-list_task-list"><li><label class="op-uc-list__label"><strong><input type="checkbox" disabled="disabled"></strong><span class="op-uc-list__label__description"><strong>asdf</strong></span></label></li></ul>
    HTML

    span = doc.at_css('li[data-task] > span[data-task="unchecked"]')
    expect(span.text).to eq("asdf")
    expect(span.at_css("strong", text: "asdf")).to be_present
    expect(doc.css("label, input")).to be_empty
  end

  it "ignores a checkbox inside a nested list when detecting the outer item" do
    doc = sanitize(<<~HTML.squish)
      <ul class="op-uc-list_task-list"><li>plain<ul><li><label><input type="checkbox" disabled="disabled"><span>inner</span></label></li></ul></li></ul>
    HTML

    expect(doc.at_css("li")["data-task"]).to be_nil
    expect(doc.at_css("li li > span[data-task]").text).to eq("inner")
  end

  it "keeps block content out of the label" do
    doc = sanitize(<<~HTML.squish)
      <ul class="todo-list"><li><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description">text<div>block</div></span></label></li></ul>
    HTML

    span = doc.at_css("li > span[data-task]")
    expect(span.text).to eq("text")
    expect(span.next_element.name).to eq("div")
    expect(span.next_element.text).to eq("block")
  end

  it "leaves an empty item's marker as text" do
    doc = sanitize('<ul><li><input type="checkbox" checked="" disabled="" /> </li></ul>')

    expect(doc.at_css("li").text).to eq("[x]")
    expect(doc.css("[data-task], [data-task-list]")).to be_empty
  end

  [
    ["a comment", "<!-- c -->"],
    ["a script", "<script>x</script>"],
    ["an empty element", "<em></em>"]
  ].each do |description, content|
    it "leaves the marker as text for an item holding only #{description}" do
      doc = sanitize(%(<ul><li><input type="checkbox" disabled="" /> #{content}</li></ul>))

      expect(doc.at_css("li").text).to eq("[ ]")
      expect(doc.css("[data-task], [data-task-list]")).to be_empty
    end
  end

  it "writes markers as text for plain-text output" do
    doc = sanitize(<<~HTML.squish, plain_text: true)
      <ul><li><input type="checkbox" checked="" disabled="" /> done</li><li><input type="checkbox" disabled="" /> open</li></ul>
    HTML

    expect(doc.css("li").map(&:text)).to eq(["[x] done", "[ ] open"])
    expect(doc.css("[data-task], [data-task-list]")).to be_empty
  end

  it "separates editor items in plain-text output" do
    doc = sanitize(<<~HTML.squish, plain_text: true)
      <table><tbody><tr><td><ul class="todo-list"><li><label class="todo-list__label"><input type="checkbox" checked="checked" disabled="disabled"><span class="todo-list__label__description">p1</span></label><ul class="todo-list"><li><label class="todo-list__label"><input type="checkbox" disabled="disabled"><span class="todo-list__label__description">p2</span></label></li></ul></li></ul></td></tr></tbody></table>
    HTML

    expect(doc.text).to match(/\[x\] p1\s+\[ \] p2/)
  end

  it "labels an image-only item by its alt text" do
    doc = sanitize('<ul><li><input type="checkbox" disabled="" /> <img src="/x.png" alt="shot"></li></ul>')

    expect(doc.at_css('li[data-task] > span[data-task="unchecked"] > img')).to be_present
    expect(doc.at_css("input")).to be_nil
  end

  [["an empty alt", ' alt=""'], ["no alt", ""]].each do |description, alt|
    it "leaves the marker as text for an image with #{description}" do
      doc = sanitize(%(<ul><li><input type="checkbox" disabled="" /> <img src="/x.png"#{alt}></li></ul>))

      expect(doc.at_css("li").text).to eq("[ ]")
      expect(doc.css("[data-task], [data-task-list]")).to be_empty
    end
  end

  it "strips hand-written task attributes" do
    doc = sanitize(<<~HTML.squish)
      <ul data-task-list><li data-task="checked&quot; onclick=&quot;x">t</li><li><span data-task="checked">s</span></li></ul>
    HTML

    expect(doc.css("[data-task], [data-task-list]")).to be_empty
    expect(doc.css("li").map(&:text)).to eq(%w[t s])
  end

  it "ignores an orphan task item" do
    doc = sanitize('<li><input type="checkbox" disabled="" /> orphan</li>')

    expect(doc.text).to include("orphan")
    expect(doc.css("[data-task-list]")).to be_empty
  end
end

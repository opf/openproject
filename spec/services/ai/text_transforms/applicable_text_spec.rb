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

RSpec.describe AI::TextTransforms::ApplicableText do
  def applicable(text, input: "") = described_class.call(text, input:)

  it "keeps plain markdown byte for byte" do
    text = "# Title\n\n- a < b & c\n- [link](https://example.com)\n\n```\ncode\n```\n"

    expect(applicable(text)).to eq(text)
  end

  def nodes_of(markdown)
    Commonmarker.parse(markdown).to_enum(:walk).map(&:type)
  end

  it "removes macros in any spelling" do
    text = %(Before\n\n<macro class="toc"></macro>\n\n<MACRO class='embedded-table' data-query-props="{}" />\n\nAfter)

    expect(applicable(text)).to eq("Before\n\n\n\n\n\nAfter")
  end

  it "removes macros together with their content, like the preview" do
    text = %(a <macro class="toc">private ![x](y.png)</macro> b\n\n) +
           %(<macro class="toc">\n<macro>nested</macro>\nsecret\n</macro>\n\nc)

    expect(applicable(text)).to eq("a  b\n\n\n\nc")
  end

  it "ends an unclosed macro where the preview's HTML parser closes it" do
    expect(applicable(%(x <macro class="toc"> y\n\nz))).to eq("x \n\nz")
    expect(applicable(%(x\n\n<macro class="toc">\n\ny\n\nz))).to eq("x\n\n")
  end

  it "ignores macro tags in comments and attribute values, like the preview's HTML parser" do
    commented = "<!-- <macro> -->\n\nVisible answer"
    in_attribute = %(Intro <span title="<macro>">x</span> kept?\n\nNext paragraph)

    expect(applicable(commented)).to eq(commented)
    expect(applicable(in_attribute)).to eq(in_attribute)
    expect(applicable("<macro>\n<!-- </macro> -->\nHIDDEN\n</macro>\n\nshown")).to eq("\n\nshown")
  end

  it "keeps code spans and blocks untouched" do
    text = %(`![x](y.png)` and `<macro class="toc"></macro>`\n\n```html\n<img src="logo.png" alt="logo">\n```\n)

    expect(applicable(text)).to eq(text)
  end

  describe "mentions" do
    shared_let(:user) { create(:user, login: "ann") }
    let(:ann) { %(<mention class="mention" data-id="#{user.id}" data-type="user" data-text="@Ann">@Ann</mention>) }
    let(:devs) { %(<mention class="mention" data-id="3" data-type="group" data-text="@Devs">@Devs</mention>) }
    let(:work_package) { %(<mention class="mention" data-id="4" data-type="work_package" data-text="#4">#4</mention>) }

    def converted?(text, input: "")
      described_class.new(text, input:).mentions_converted?
    end

    def notified_by(text)
      text.scan(Notifications::CreateFromModelService::MENTION_PATTERN)
    end

    it "keeps the users and groups the input mentioned, in any form" do
      text = %(#{ann} #{devs} user##{user.id} group#3 user:"ann")
      input = %(Hi user:"ann" and #{devs})

      expect(applicable(text, input:)).to eq(text)
      expect(converted?(text, input:)).to be(false)
    end

    it "turns new user and group mentions into plain text that notifies nobody, and keeps work packages" do
      text = %(#{ann} #{devs} #{work_package} user#2 group#3 user:"ann")

      replaced = applicable(text, input: "Hi #{work_package}")

      expect(replaced).to eq(%(@Ann @Devs #{work_package} user 2 group 3 user: "ann"))
      expect(notified_by(replaced)).to be_empty
      expect(converted?(text, input: "Hi")).to be(true)
    end

    it "recognizes new mention tags regardless of attribute quoting" do
      expect(applicable(%(Hi <MENTION data-type='group' data-id=3>@Devs</MENTION> and <mention data-type=user>@Ann</mention>)))
        .to eq("Hi @Devs and @Ann")
    end

    it "converts new mentions in code and alt text as well, since saving finds them there too" do
      expect(applicable("`user#2` and\n\n```\ngroup#3\n```\n")).to eq("`user 2` and\n\n```\ngroup 3\n```\n")
      expect(applicable("![group#3](a.png)")).to eq("[Image: group 3](a.png)")
    end

    it "converts new mentions that escapes or entities spell out" do
      replaced = applicable(%(group\\#3, group&#35;3, us&#101;r#2 and &lt;mention data-type="group" data-id="3"&gt;x))

      expect(notified_by(Commonmarker.to_html(replaced).then { Nokogiri::HTML5.fragment(it).text })).to be_empty
      expect(converted?(%(group&#35;3))).to be(true)
    end

    it "removes new mention tags with their closing tag in code as well" do
      expect(applicable(%(`<mention data-type="group" data-id="3">@Devs</mention>`))).to eq("`@Devs`")
    end

    it "keeps other elements whole and only drops the attribute that would notify" do
      expect(applicable(%(<span data-id="5" data-type="user">hi</span>))).to eq(%(<span data-id="5">hi</span>))
      expect(applicable(%(```html\n<b data-id="5" data-type="group">hi</b>\n```\n)))
        .to eq(%(```html\n<b data-id="5">hi</b>\n```\n))
    end

    it "turns links and images whose address mentions someone new into their text" do
      expect(applicable("[profile](https://example.com/user#12) and ![chart](https://example.com/group#3.png)"))
        .to eq("profile and Image: chart")
      expect(applicable(%(<img src="https://example.com/user#12" alt="chart">))).to eq("Image: chart")
    end

    it "does not count mentions the input only quoted, as saving ignores them there too" do
      expect(applicable("As user#5 said, fix it.", input: "> as user#5 said")).to eq("As user 5 said, fix it.")
    end

    it "falls back to plain text when markup hides a new mention" do
      replaced = applicable(%(**Hi** <span title="group&#35;3">x</span> [a](https://example.com/user&#35;2)))

      expect(replaced).to eq("Hi x a")
    end
  end

  it "turns markdown images into links" do
    expect(applicable(%(See ![chart](https://example.com/a.png "Title") and ![](/api/v3/attachments/1/content))))
      .to eq("See [Image: chart](https://example.com/a.png) and " \
             "[Image: /api/v3/attachments/1/content](/api/v3/attachments/1/content)")
  end

  it "turns reference images and images with brackets in their alt text into links" do
    expect(applicable("![chart][1] ![a [b]](x.png)\n\n[1]: https://example.com/t.png\n"))
      .to eq("[Image: chart](https://example.com/t.png) [Image: a \\[b\\]](x.png)\n\n[1]: https://example.com/t.png\n")
  end

  it "keeps decoded alt text as text when the link is parsed again" do
    group = %(&lt;mention data-type="group" data-id="3"&gt;@Devs&lt;/mention&gt;)
    replaced = applicable(%(![&lt;img src=x&gt;](https://example.com/a.png) ![#{group}](b.png) ![*a* &amp;lt;](<c d.png>)))

    rendered = Nokogiri::HTML5.fragment(Commonmarker.to_html(replaced))

    expect(nodes_of(replaced)).not_to include(:image, :html_inline)
    expect(rendered.css("img, mention")).to be_empty
    expect(rendered.css("a").map(&:text))
      .to eq(["Image: <img src=x>", "Image: @Devs", "Image: a &lt;"])
    expect(rendered.css("a").last["href"]).to eq("c%20d.png")
  end

  it "finds images after bare CR and CRLF line breaks" do
    expect(applicable("a\r![alt](url)")).to eq("a\r[Image: alt](url)")
    expect(applicable("a\r\n\r\n![alt](url)")).to eq("a\r\n\r\n[Image: alt](url)")
  end

  it "turns HTML images into links, or into text without a source" do
    expect(applicable(%(Ünïcode <IMG src='https://example.com/b.png' alt="a > bee"> <img alt="ghost">)))
      .to eq(%(Ünïcode <a href="https://example.com/b.png">Image: a &gt; bee</a> Image: ghost))
  end

  it "turns images inside HTML blocks into links" do
    expect(applicable(%(<div>\n<img src="c.png" alt="cat">\n</div>\n)))
      .to eq(%(<div>\n<a href="c.png">Image: cat</a>\n</div>\n))
  end
end

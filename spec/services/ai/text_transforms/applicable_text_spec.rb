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
  def applicable(text) = described_class.call(text)

  it "keeps plain markdown byte for byte" do
    text = "# Title\n\n- a < b & c\n- [link](https://example.com)\n\n```\ncode\n```\n"

    expect(applicable(text)).to eq(text)
  end

  it "removes macros in any spelling, closed or not" do
    text = %(Before\n\n<macro class="toc"></macro>\n\n<MACRO class='embedded-table' data-query-props="{}" />\n\n) +
           %(x <macro class="create_work_package_link"> y)

    expect(applicable(text)).to eq("Before\n\n\n\n\n\nx  y")
  end

  it "keeps code spans and blocks untouched" do
    text = %(`![x](y.png)` and `<macro class="toc"></macro>`\n\n```html\n<img src="logo.png" alt="logo">\n```\n)

    expect(applicable(text)).to eq(text)
  end

  it "turns group mentions into their text and keeps user and work package mentions" do
    user = %(<mention class="mention" data-id="2" data-type="user" data-text="@Ann">@Ann</mention>)
    group = %(<mention class="mention" data-id="3" data-type="group" data-text="@Devs">@Devs</mention>)
    work_package = %(<mention class="mention" data-id="4" data-type="work_package" data-text="#4">#4</mention>)

    expect(applicable("#{user} #{group} #{work_package}")).to eq("#{user} @Devs #{work_package}")
  end

  it "recognises group mentions regardless of attribute quoting" do
    expect(applicable(%(Hi <MENTION data-type='group' data-id=3>@Devs</MENTION> and <mention data-type=group>@Ops</mention>)))
      .to eq("Hi @Devs and @Ops")
  end

  it "turns markdown images into links" do
    expect(applicable(%(See ![chart](https://example.com/a.png "Title") and ![](/api/v3/attachments/1/content))))
      .to eq("See [Image: chart](https://example.com/a.png) and " \
             "[Image: /api/v3/attachments/1/content](/api/v3/attachments/1/content)")
  end

  it "turns reference images and images with brackets in their alt text into links" do
    expect(applicable("![chart][1] ![a [b]](x.png)\n\n[1]: https://example.com/t.png\n"))
      .to eq("[Image: chart](https://example.com/t.png) [Image: a b](x.png)\n\n[1]: https://example.com/t.png\n")
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

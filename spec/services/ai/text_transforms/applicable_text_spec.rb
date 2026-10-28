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

  it "removes macros" do
    text = %(Before\n\n<macro class="toc"></macro>\n\n<macro class="embedded-table" data-query-props="{}" />\n\nAfter)

    expect(applicable(text)).to eq("Before\n\n\n\n\n\nAfter")
  end

  it "turns group mentions into their text and keeps user and work package mentions" do
    user = %(<mention class="mention" data-id="2" data-type="user" data-text="@Ann">@Ann</mention>)
    group = %(<mention class="mention" data-id="3" data-type="group" data-text="@Devs">@Devs</mention>)
    work_package = %(<mention class="mention" data-id="4" data-type="work_package" data-text="#4">#4</mention>)

    expect(applicable("#{user} #{group} #{work_package}")).to eq("#{user} @Devs #{work_package}")
  end

  it "turns markdown images into links" do
    expect(applicable(%(See ![chart](https://example.com/a.png "Title") and ![](/api/v3/attachments/1/content))))
      .to eq("See [Image: chart](https://example.com/a.png) and " \
             "[Image: /api/v3/attachments/1/content](/api/v3/attachments/1/content)")
  end

  it "turns HTML images into links, or into text without a source" do
    expect(applicable(%(<img src="https://example.com/b.png" alt="bee"> <img alt="ghost">)))
      .to eq("[Image: bee](https://example.com/b.png) Image: ghost")
  end
end

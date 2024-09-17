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

require "rails_helper"

RSpec.describe AttributeGroups::AttributeKeyValueComponent, type: :component do
  it "renders the attribute key and value" do
    render_inline(described_class.new(key: "Attribute Key", value: "Attribute Value"))

    expect(page).to have_css(".attributes-key-value--key", text: "Attribute Key") &
      have_css(".attributes-key-value--value.-text", text: "Attribute Value")
  end

  it "preserve html in the value if it's a safe string" do
    render_inline(described_class.new(key: "Attribute Key", value: "<div>Some value</div>".html_safe))

    expect(page).to have_no_css(".attributes-key-value--value.-text", text: "<div>Some value</div>")
    expect(page).to have_css(".attributes-key-value--value.-text", text: "Some value")
  end

  context "with value and content" do
    it "renders the content" do
      render_inline(described_class.new(key: "Attribute Key", value: "Attribute Value")) do
        "<p class='test--content'>Content Value</p>"
      end

      expect(page).to have_css(".attributes-key-value--key", text: "Attribute Key") &
        have_css(".attributes-key-value--value.-text", text: "Attribute Value") &
        have_css(".attributes-key-value--value.-text", text: "<p class='test--content'>Content Value</p>")
    end
  end

  context "with content, no value" do
    it "renders the content" do
      render_inline(described_class.new(key: "Attribute Key")) do
        "<p class='test--content'>Content Value</p>"
      end

      expect(page).to have_css(".attributes-key-value--key", text: "Attribute Key") &
        have_css(".attributes-key-value--value.-text", text: "<p class='test--content'>Content Value</p>")
    end
  end
end

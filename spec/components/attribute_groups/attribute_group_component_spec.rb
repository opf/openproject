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

RSpec.describe AttributeGroups::AttributeGroupComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new) do |component|
      component.with_header(title: "A Title")

      component.with_attributes(
        [{ key: "Attribute Key 1", value: "Attribute Value 1" },
         { key: "Attribute Key 2", value: "Attribute Value 2" }]
      )
    end

    aggregate_failures "group header" do
      expect(page).to have_css(".attributes-group")
      expect(page).to have_css("h3.attributes-group--header-text", text: "A Title")
    end

    aggregate_failures "attribute key value" do
      expect(page).to have_css(".attributes-key-value")
      expect(page).to have_css(".attributes-key-value--key", text: "Attribute Key 1") &
       have_css(".attributes-key-value--value.-text", text: "Attribute Value 1")
      expect(page).to have_css(".attributes-key-value--key", text: "Attribute Key 2") &
       have_css(".attributes-key-value--value.-text", text: "Attribute Value 2")
    end
  end

  it "renders content when provided" do
    render_inline(described_class.new) do |component|
      component.with_header(title: "A Title")

      "Raw Content"
    end

    expect(page).to have_css(".attributes-group--content", text: "Raw Content")

    aggregate_failures "group header" do
      expect(page).to have_css(".attributes-group")
      expect(page).to have_css("h3.attributes-group--header-text", text: "A Title")
    end
  end
end

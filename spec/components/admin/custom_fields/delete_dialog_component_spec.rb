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

RSpec.describe Admin::CustomFields::DeleteDialogComponent, type: :component do
  let(:custom_field) { build_stubbed(:work_package_custom_field, id: 4242, name: "Field666") }

  it "includes the name of the custom field in the dialog title" do
    render_inline(described_class.new(custom_field:))
    expect(page).to have_css("h1", text: "Delete custom field Field666", visible: :all)
  end

  it "includes the name of the custom field in the dialog heading" do
    render_inline(described_class.new(custom_field:))
    expect(page).to have_css("h2", text: "Do you want to delete the custom field Field666?", visible: :visible)
  end

  it "does not render any button to open the dialog" do
    render_inline(described_class.new(custom_field:))
    expect(page).to have_no_element("[data-show-dialog-id]")
  end

  it "submits a DELETE request to the custom field's admin path" do
    render_inline(described_class.new(custom_field:))

    expect(page).to have_element(:form, action: "/admin/settings/work_package_custom_fields/4242")
    form = page.find("form")
    expect(form).to have_field("_method", type: :hidden, with: "delete")
  end

  it "renders an optional description message" do
    render_inline(described_class.new(custom_field:))
    expect(page).to have_no_css(".blankslate-description")

    render_inline(described_class.new(custom_field:, description: "This is a more thorough warning…"))
    expect(page).to have_css("p.blankslate-description", text: "This is a more thorough warning…")
  end

  %i[work_package_custom_field version_custom_field group_custom_field time_entry_custom_field user_custom_field
     project_custom_field].each do |type|
    context "for a #{type.to_s.humanize.downcase}" do
      let(:custom_field) { build_stubbed(type, id: 4242, name: "Field666") }

      it "has the corresponding form" do
        render_inline(described_class.new(custom_field:))

        expect(page).to have_element(:form, action: "/admin/settings/#{type}s/4242")
        form = page.find("form")
        expect(form).to have_field("_method", type: :hidden, with: "delete")
      end
    end
  end
end

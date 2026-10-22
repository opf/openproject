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

require "rails_helper"

RSpec.describe Admin::Settings::CustomFields::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:table) { Admin::Settings::CustomFields::TableComponent.new(rows: [custom_field], work_package:, project_counts: {}) }

  # Only custom field types administered through CustomFieldsBaseController render this
  # component; project/user custom fields have their own section-grouped row component.
  def controller_for(custom_field)
    {
      work_package_custom_field: Admin::Settings::WorkPackageCustomFieldsController,
      group_custom_field: Admin::Settings::GroupCustomFieldsController,
      time_entry_custom_field: Admin::Settings::TimeEntryCustomFieldsController,
      version_custom_field: Admin::Settings::VersionCustomFieldsController
    }.fetch(custom_field.class.name.underscore.to_sym)
  end

  subject(:rendered_component) do
    with_controller_class(controller_for(custom_field)) do
      render_inline(described_class.new(row: custom_field, table:))
    end
  end

  context "for a work package custom field, which cannot be reordered" do
    let(:work_package) { true }
    let(:custom_field) { build_stubbed(:work_package_custom_field, id: 4242, name: "Field666") }

    it "renders no drag handle, since the row cannot be reordered" do
      expect(rendered_component).to have_no_css(".DragHandle")
    end

    it "renders a button to asynchronously open the deletion dialog" do
      expect(rendered_component).to have_link(href: "/admin/settings/work_package_custom_fields/4242/deletion_dialog")
      expect(rendered_component).to have_css("a[data-controller='async-dialog']")
      expect(rendered_component).to have_element("tool-tip", text: "Delete")
    end

    it "renders no action menu" do
      expect(rendered_component).to have_no_css("action-menu")
    end
  end

  context "for custom field types that can be reordered" do
    let(:work_package) { false }

    %i[group_custom_field time_entry_custom_field version_custom_field].each do |type|
      context "for a #{type.to_s.humanize.downcase}" do
        let(:custom_field) { build_stubbed(type, id: 4242, name: "Field666") }

        it "renders a drag handle wired as the sortable-lists item's handle, since the row can be reordered" do
          expect(rendered_component).to have_css(".DragHandle[data-sortable-lists--item-target~='handle']")
        end

        it "offers deletion through the action menu's delete item" do
          expect(rendered_component).to have_link(href: "/admin/settings/#{type}s/4242/deletion_dialog")
          expect(rendered_component).to have_css("a[data-controller='async-dialog']")
        end
      end
    end
  end
end

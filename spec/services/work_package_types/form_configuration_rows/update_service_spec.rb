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

require "spec_helper"

module WorkPackageTypes
  module FormConfigurationRows
    RSpec.describe UpdateService, type: :service, with_ee: %i[edit_attribute_groups] do
      let(:user) { create(:admin) }
      let(:type) { create(:type, name: "Legacy type") }

      subject(:service) { described_class.new(user:, type:, row_key: "priority") }

      before do
        type.update_column(:attribute_groups, [
                             ["", ["assignee"]],
                             [:details, ["priority"]]
                           ])
      end

      it "normalizes unnamed legacy groups while updating rows" do
        result = service.call(target_id: "inactive", position: 1)

        expect(result).to be_success

        normalized_group = type.reload.attribute_groups.find do |group|
          group.translated_key == I18n.t("types.edit.form_configuration.untitled_group")
        end

        expect(normalized_group).to be_present
        expect(normalized_group.key).to eq(I18n.t("types.edit.form_configuration.untitled_group"))
      end

      it "finds legacy symbol attribute keys when moving rows" do
        type.update_column(:attribute_groups, [
                             [:details, [:version]]
                           ])

        result = described_class.new(user:, type:, row_key: "version").call(target_id: "inactive", position: 1)

        expect(result).to be_success
        expect(type.reload.attribute_groups.flat_map(&:members)).not_to include("version")
      end

      it "removes unavailable attributes from legacy form configurations when updating rows" do
        custom_field = create(:work_package_custom_field, field_format: "string")
        deleted_custom_field_attribute = "custom_field_1"
        type.update_column(:attribute_groups, [
                             ["Legacy custom group", [deleted_custom_field_attribute, "priority"]]
                           ])

        result = described_class
          .new(user:, type:, row_key: custom_field.attribute_name)
          .call(target_id: "Legacy custom group", position: 1)

        expect(result).to be_success

        members = type.reload.attribute_groups.first.members
        expect(members).to include(custom_field.attribute_name, "priority")
        expect(members).not_to include(deleted_custom_field_attribute)
        expect(type.custom_field_ids).to contain_exactly(custom_field.id)
      end
    end
  end
end

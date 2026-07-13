# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe CustomFields::Scopes::Visible do
  # Since there would be very many tests here, only test the integration aspect of this method which
  # calls the visible scopes of each custom field class.
  # See the individual specs for the individual scopes.
  describe ".visible" do
    subject { CustomField.visible(current_user) }

    shared_current_user { create(:user) }

    context "for a project custom field" do
      let(:type) { create(:type) }
      let!(:visible_project_cf) { create(:string_project_custom_field) }
      let!(:invisible_project_cf) { create(:string_project_custom_field) }
      let!(:project) do
        create(:project, members: { current_user => create(:project_role, permissions: %i[view_project_attributes]) }) do |p|
          p.project_custom_fields << visible_project_cf
        end
      end

      it "returns the visible project custom field" do
        expect(subject).to contain_exactly(visible_project_cf)
      end
    end

    context "for a work package custom field" do
      let(:type) { create(:type) }
      let!(:visible_wp_cf) { create(:string_wp_custom_field) }
      let!(:invisible_wp_cf) { create(:string_wp_custom_field) }
      let!(:project) do
        create(:project, types: [type], members: { current_user => create(:project_role) }) do |p|
          p.work_package_custom_fields << visible_wp_cf
          type.custom_fields = [visible_wp_cf, invisible_wp_cf]
        end
      end

      it "returns the visible work package custom field" do
        expect(subject).to contain_exactly(visible_wp_cf)
      end
    end

    context "for a user custom field" do
      let!(:visible_user_cf) { create(:user_custom_field, admin_only: false) }
      let!(:invisible_user_cf) { create(:user_custom_field, admin_only: true) }

      it "returns the visible user custom field" do
        expect(subject).to contain_exactly(visible_user_cf)
      end
    end

    context "for a group custom field" do
      let!(:visible_group_cf) { create(:group_custom_field, admin_only: false) }
      let!(:invisible_group_cf) { create(:group_custom_field, admin_only: true) }

      it "returns the visible group custom field" do
        expect(subject).to contain_exactly(visible_group_cf)
      end
    end

    context "for a version custom field" do
      # There are no invisible version cfs
      let!(:visible_version_cf) { create(:version_custom_field) }

      it "returns the visible version field" do
        expect(subject).to contain_exactly(visible_version_cf)
      end
    end

    context "for a time_entry custom field" do
      # There are no invisible time_entry cfs
      let!(:visible_time_entry_cf) { create(:time_entry_custom_field) }

      it "returns the visible time_entry field" do
        expect(subject).to contain_exactly(visible_time_entry_cf)
      end
    end
  end
end

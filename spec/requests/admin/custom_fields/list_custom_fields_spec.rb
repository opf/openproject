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
require_relative "list_custom_field_administration_examples"

RSpec.describe "List custom field administration", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  let(:create_attributes) { {} }

  before { login_as admin }

  context "for work packages" do
    let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[pear apple]) }

    it_behaves_like "list custom field administration", "WorkPackageCustomField",
                    create_route: :custom_fields, redirect_route: :edit_custom_field, items_route: :custom_field
  end

  context "for groups" do
    let(:custom_field) { create(:group_custom_field, :list, possible_values: %w[pear apple]) }

    it_behaves_like "list custom field administration", "GroupCustomField",
                    create_route: :custom_fields, redirect_route: :edit_custom_field, items_route: :custom_field
  end

  context "for versions" do
    let(:custom_field) { create(:version_custom_field, :list, possible_values: %w[pear apple]) }

    it_behaves_like "list custom field administration", "VersionCustomField",
                    create_route: :custom_fields, redirect_route: :edit_custom_field, items_route: :custom_field
  end

  context "for spent time" do
    let(:custom_field) { create(:time_entry_custom_field, :list, possible_values: %w[pear apple]) }

    it_behaves_like "list custom field administration", "TimeEntryCustomField",
                    create_route: :custom_fields, redirect_route: :edit_custom_field, items_route: :custom_field
  end

  context "for projects" do
    let(:custom_field) { create(:list_project_custom_field, possible_values: %w[pear apple]) }
    let(:create_attributes) { { custom_field_section_id: create(:project_custom_field_section).id } }

    it_behaves_like "list custom field administration", "ProjectCustomField",
                    create_route: :admin_settings_project_custom_fields,
                    redirect_route: :admin_settings_project_custom_field,
                    items_route: :admin_settings_project_custom_field
  end

  context "for users" do
    let(:custom_field) { create(:user_custom_field, :list, possible_values: %w[pear apple]) }
    let(:create_attributes) { { custom_field_section_id: create(:user_custom_field_section).id } }

    it_behaves_like "list custom field administration", "UserCustomField",
                    create_route: :admin_settings_user_custom_fields,
                    redirect_route: :edit_admin_settings_user_custom_field,
                    items_route: :admin_settings_user_custom_field
  end
end

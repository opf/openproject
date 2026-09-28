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

  before { login_as admin }

  generic_area = ->(type) do
    { create_route: :"admin_settings_#{type}_custom_fields", redirect_route: :"edit_admin_settings_#{type}_custom_field",
      items_route: :custom_field }
  end

  {
    "work packages" => { factory: :wp_custom_field, **generic_area.("work_package") },
    "groups" => { factory: :group_custom_field, **generic_area.("group") },
    "versions" => { factory: :version_custom_field, **generic_area.("version") },
    "spent time" => { factory: :time_entry_custom_field, **generic_area.("time_entry") },
    "projects" => { factory: :project_custom_field, section: :project_custom_field_section,
                    create_route: :admin_settings_project_custom_fields,
                    redirect_route: :admin_settings_project_custom_field,
                    items_route: :admin_settings_project_custom_field },
    "users" => { factory: :user_custom_field, section: :user_custom_field_section,
                 create_route: :admin_settings_user_custom_fields,
                 redirect_route: :edit_admin_settings_user_custom_field,
                 items_route: :admin_settings_user_custom_field }
  }.each do |entity, area|
    context "for #{entity}" do
      let(:custom_field) { create(area[:factory], :list, possible_values: %w[pear apple]) }
      let(:create_attributes) { area[:section] ? { custom_field_section_id: create(area[:section]).id } : {} }

      it_behaves_like "list custom field administration", **area.slice(:create_route, :redirect_route, :items_route)
    end
  end
end

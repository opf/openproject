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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# The admin areas that manage the items of a hierarchical custom field. Each builds `custom_field`
# from the including spec's `custom_field_traits`, for example
# `let(:custom_field_traits) { [:list, { possible_values: %w[One Two] }] }`.
module CustomFieldAdminAreas
  CONTEXTS = [
    "in the work package custom field admin area",
    "in the project custom field admin area",
    "in the user custom field admin area"
  ].freeze
end

RSpec.shared_context "in the work package custom field admin area" do
  let(:custom_field) { create(:wp_custom_field, *custom_field_traits) }
  let(:items_path) { "/admin/settings/work_package_custom_fields/#{custom_field.id}/items" }
end

RSpec.shared_context "in the project custom field admin area" do
  let(:custom_field) { create(:project_custom_field, *custom_field_traits) }
  let(:items_path) { "/admin/settings/project_custom_fields/#{custom_field.id}/items" }
end

RSpec.shared_context "in the user custom field admin area" do
  let(:custom_field) { create(:user_custom_field, *custom_field_traits) }
  let(:items_path) { "/admin/settings/user_custom_fields/#{custom_field.id}/items" }
end

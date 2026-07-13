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

RSpec.shared_context "given a visible setup" do
  shared_let(:feature) { create(:type_feature) }
  shared_let(:task) { create(:type_task) }
  shared_let(:bug) { create(:type_bug) }

  shared_let(:project_with_user_and_feature) { create(:project, types: [feature]) }
  shared_let(:project_without_user) { create(:project, types: [feature, task]) }
  shared_let(:project_with_user_and_bug) { create(:project, types: [bug]) }

  shared_let(:user) do
    create(:user, member_with_permissions: { project_with_user_and_feature => [],
                                             project_with_user_and_bug => [] })
  end

  # User cannot see this field:
  #   * the type is not enabled in any project
  shared_let(:type_non_enabled_in_project_cf) do
    create(:text_wp_custom_field, projects: [project_with_user_and_feature, project_without_user], types: [])
  end
  # User cannot see this field:
  #   * The field is not enabled in any project the user can see
  shared_let(:not_a_member_cf) { create(:integer_wp_custom_field, projects: [project_without_user], types: [feature, task]) }
  # User cannot see this field:
  #   * the field is for all
  #   * the type is not enabled in any project the user can see
  shared_let(:type_disabled_for_all_cf) { create(:text_wp_custom_field, is_for_all: true, projects: [], types: [task]) }
  # User cannot see this field:
  #   * the type is enabled in a project the user can see
  #   * the field is enabled in a different project the user can see
  shared_let(:type_enabled_in_different_project_than_member_cf) do
    create(:text_wp_custom_field, projects: [project_with_user_and_feature], types: [bug])
  end

  # User can see this field:
  #   * the type is enabled in a project the user can see
  #   * the field is enabled in that same project
  shared_let(:type_enabled_and_member_cf) do
    create(:boolean_wp_custom_field, projects: [project_with_user_and_feature], types: [feature, task])
  end
  # User can see this field:
  #   * the type is enabled in a project the user can see
  #   * the field is for all projects (including the one the user is member in)
  shared_let(:type_enabled_for_all_cf) { create(:text_wp_custom_field, is_for_all: true, projects: [], types: [feature, task]) }
end

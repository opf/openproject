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

  shared_let(:cf_on_no_type) do
    create(:text_wp_custom_field, types: [])
  end
  shared_let(:cf_on_type_outside_visible_projects) { create(:text_wp_custom_field, is_for_all: true, types: [task]) }

  shared_let(:integer_cf_on_visible_type) { create(:integer_wp_custom_field, types: [feature, task]) }
  shared_let(:cf_on_bug_type) do
    create(:text_wp_custom_field, types: [bug])
  end
  shared_let(:boolean_cf_on_visible_type) do
    create(:boolean_wp_custom_field, types: [feature, task])
  end
  shared_let(:for_all_cf_on_visible_type) { create(:text_wp_custom_field, is_for_all: true, types: [feature, task]) }
end

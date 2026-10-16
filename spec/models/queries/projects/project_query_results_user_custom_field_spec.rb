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

RSpec.describe ProjectQuery, "results of a user custom field filter" do
  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:user_project) { create(:project) }
  shared_let(:group_project) { create(:project) }
  shared_let(:placeholder_project) { create(:project) }
  shared_let(:projects) { [user_project, group_project, placeholder_project] }
  shared_let(:project_roles) { projects.index_with { [role] } }
  shared_let(:user) { create(:user, member_with_roles: project_roles) }
  shared_let(:group) { create(:group, members: [user], member_with_roles: project_roles) }
  shared_let(:other_group) { create(:group) }
  shared_let(:placeholder_user) { create(:placeholder_user, member_with_roles: project_roles) }
  shared_let(:custom_field) do
    create(:user_project_custom_field, projects: [user_project, group_project, placeholder_project]).tap do |field|
      user_project.update!(custom_field_values: { field.id => [user.id] })
      group_project.update!(custom_field_values: { field.id => [group.id] })
      placeholder_project.update!(custom_field_values: { field.id => [placeholder_user.id] })
    end
  end

  current_user { admin }

  def results_for(principal)
    described_class.new
                   .where(custom_field.column_name, "=", [principal.id.to_s])
                   .results
  end

  it "finds a project by its user value" do
    expect(results_for(user)).to contain_exactly(user_project, group_project)
  end

  it "finds a user value through one of the user's groups" do
    group_project.update!(custom_field_values: { custom_field.id => [group.id] })

    expect(results_for(group)).to contain_exactly(user_project, group_project)
  end

  it "updates the results when a user value is cleared" do
    expect(results_for(other_group)).to be_empty

    user_project.update!(custom_field_values: { custom_field.id => [] })

    expect(results_for(user)).to contain_exactly(group_project)
    expect(results_for(other_group)).to be_empty
  end

  it "finds a project by its placeholder user value" do
    expect(results_for(placeholder_user)).to contain_exactly(placeholder_project)
  end
end

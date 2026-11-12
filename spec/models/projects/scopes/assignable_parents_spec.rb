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

require "spec_helper"

RSpec.describe Projects::Scopes::AssignableParents do
  shared_let(:add_subprojects_role) { create(:project_role, permissions: %i[add_subprojects]) }
  shared_let(:view_role) { create(:project_role, permissions: %i[]) }

  shared_let(:user) { create(:user) }

  shared_let(:portfolio_with_permission) { create(:portfolio, members: { user => add_subprojects_role }) }
  shared_let(:program_with_permission) { create(:program, members: { user => add_subprojects_role }) }
  shared_let(:project_with_permission) { create(:project, members: { user => add_subprojects_role }) }
  shared_let(:portfolio_without_permission) { create(:portfolio, members: { user => view_role }) }
  shared_let(:program_without_permission) { create(:program, members: { user => view_role }) }
  shared_let(:project_without_permission) { create(:project, members: { user => view_role }) }

  # part of hierarchy used for test is not valid
  shared_let(:parent_portfolio) { create(:portfolio, members: { user => add_subprojects_role }) }
  shared_let(:parent_program) { create(:program, parent: parent_portfolio, members: { user => add_subprojects_role }) }
  shared_let(:parent_project) { create(:project, parent: parent_program, members: { user => add_subprojects_role }) }
  shared_let(:children) do
    [
      create(:portfolio, members: { user => add_subprojects_role }),
      create(:program, members: { user => add_subprojects_role }),
      create(:project, members: { user => add_subprojects_role })
    ]
  end

  let!(:subject_workspace) do
    create(:project, workspace_type:, parent: parent_project, children:, members: { user => add_subprojects_role })
  end

  context "for a project" do
    let(:workspace_type) { :project }

    it "returns all types of projects the user has the add_subprojects permission in but without self or descendants" do
      expect(Project.assignable_parents(user, subject_workspace))
        .to contain_exactly(
          portfolio_with_permission,
          program_with_permission,
          project_with_permission,
          parent_portfolio,
          parent_program,
          parent_project
        )
    end
  end

  context "for a portfolio" do
    let(:workspace_type) { :portfolio }

    it "is empty since portfolios are always root elements" do
      expect(Project.assignable_parents(user, subject_workspace))
        .to be_empty
    end
  end

  context "for a program" do
    let(:workspace_type) { :program }

    it "returns portfolios the user has the add_subprojects permission in" do
      expect(Project.assignable_parents(user, subject_workspace))
      .to contain_exactly(
        portfolio_with_permission,
        parent_portfolio
      )
    end
  end

  context "for an unknown workspace type" do
    let!(:subject_workspace) do
      create(:project, :skip_validations, workspace_type: :unknown,
                                          parent: parent_project,
                                          children:,
                                          members: { user => add_subprojects_role })
    end

    it do
      expect(Project.assignable_parents(user, subject_workspace))
        .to be_empty
    end
  end
end

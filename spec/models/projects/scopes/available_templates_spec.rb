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

RSpec.describe Projects::Scopes::AvailableTemplates do
  shared_let(:copy_projects_role) { create(:project_role, permissions: %i[copy_projects]) }
  shared_let(:view_role) { create(:project_role, permissions: %i[view_projects]) }

  shared_let(:user) { create(:user) }

  shared_let(:template_project_with_permission) { create(:project, :template, members: { user => copy_projects_role }) }
  shared_let(:template_project_without_permission) { create(:project, :template, members: { user => view_role }) }
  shared_let(:non_template_project_with_permission) do
    create(:project, members: { user => copy_projects_role })
  end

  shared_let(:template_program_with_permission) { create(:program, :template, members: { user => copy_projects_role }) }
  shared_let(:template_program_without_permission) { create(:program, :template, members: { user => view_role }) }
  shared_let(:non_template_program_with_permission) do
    create(:program, members: { user => copy_projects_role })
  end

  shared_let(:template_portfolio_with_permission) { create(:portfolio, :template, members: { user => copy_projects_role }) }
  shared_let(:template_portfolio_without_permission) { create(:portfolio, :template, members: { user => view_role }) }
  shared_let(:non_template_portfolio_with_permission) do
    create(:portfolio, members: { user => copy_projects_role })
  end

  current_user { user }

  context "for a project" do
    it "returns all projects the user has the copy_projects permission in" do
      expect(Project.available_templates(:project))
        .to contain_exactly(template_project_with_permission)
    end
  end

  context "for a portfolio" do
    it "returns all portfolios the user has the copy_projects permission in" do
      expect(Project.available_templates(:portfolio))
        .to contain_exactly(template_portfolio_with_permission)
    end
  end

  context "for a program" do
    it "returns all programs the user has the copy_projects permission in" do
      expect(Project.available_templates(:program))
        .to contain_exactly(template_program_with_permission)
    end
  end

  context "for an unknown workspace type" do
    it "returns all programs the user has the copy_projects permission in" do
      expect(Project.available_templates(:bogus))
        .to be_empty
    end
  end
end

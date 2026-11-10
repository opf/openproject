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

RSpec.describe "WorkPackage project phase journaling" do # rubocop:disable RSpec/DescribeClass
  shared_let(:project) { create(:project) }
  shared_let(:project_phase) { create(:project_phase, project:) }
  shared_let(:work_package) do
    create(:work_package, project:, project_phase_definition: project_phase.definition)
  end

  let(:journal) { work_package.journals.last }
  let(:phase_name) { project_phase.definition.name }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  context "when the user has :view_project_phases" do
    let(:permissions) { %i[view_work_packages view_project_phases] }

    %i[html plain].each do |format|
      it "renders the project phase in #{format} format" do
        result = journal.render_detail("project_phase_definition_id", html: format == :html)

        expect(result).to include(phase_name)
        expect(result).not_to include(I18n.t(:text_journal_permission_denied))
      end
    end
  end

  context "when the user lacks :view_project_phases" do
    let(:permissions) { %i[view_work_packages] }

    %i[html plain].each do |format|
      it "renders a permission denied message instead of the project phase in #{format} format" do
        result = journal.render_detail("project_phase_definition_id", html: format == :html)

        expect(result).to include(I18n.t(:text_journal_permission_denied))
        expect(result).not_to include(phase_name)
      end
    end
  end
end

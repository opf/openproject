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

RSpec.describe Projects::CopyService, "integration", type: :model do
  let(:current_user) do
    create(:user, member_with_roles: { source => role })
  end
  let(:project_copy) { subject.result }
  let(:board_copies) { Boards::Grid.where(project: project_copy) }
  let(:board_copy) { board_copies.first }
  let!(:source) { create(:project, enabled_module_names: %w[boards work_package_tracking]) }
  let(:role) { create(:project_role, permissions: %i[copy_projects]) }
  let(:instance) do
    described_class.new(source:, user: current_user)
  end
  let(:only_args) { %w[work_packages boards] }
  let(:target_project_params) do
    { name: "Some name", identifier: "some-identifier" }
  end
  let(:params) do
    { target_project_params:, only: only_args }
  end

  subject { instance.call(params) }

  describe "for an automatically generated sprint board" do
    let!(:board_view) do
      create(
        :board_grid,
        project: source,
        linked: create(:sprint, project: source),
        options: {
          "filters" => [{ "sprint_id" => { "operator" => "=", "values" => ["123"] } }]
        }
      )
    end

    before do
      login_as current_user
    end

    it "removes the sprint linkage from the copy" do
      expect(subject).to be_success
      expect(board_copies.count).to eq 1
      expect(board_copy.linked).to be_nil
    end
  end
end

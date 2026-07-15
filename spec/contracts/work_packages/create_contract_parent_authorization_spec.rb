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

RSpec.describe WorkPackages::CreateContract,
               with_settings: { cross_project_work_package_relations: true } do
  shared_let(:type) { create(:type) }
  shared_let(:status) { create(:status) }
  shared_let(:priority) { create(:priority) }
  shared_let(:child_project) { create(:project, types: [type]) }
  shared_let(:parent_project) { create(:project, types: [type]) }
  shared_let(:user) { create(:user) }

  shared_let(:parent) { create(:work_package, project: parent_project, type:) }

  let(:work_package) do
    WorkPackage.new(project: child_project,
                    subject: "Some subject",
                    type:,
                    priority:,
                    status:) do |wp|
      wp.extend(OpenProject::ChangedBySystem)
      wp.change_by_system { wp.author = user }
      wp.parent = parent
    end
  end

  subject(:contract) { described_class.new(work_package, user) }

  before do
    allow(parent).to receive(:visible?).and_return(true)
  end

  context "when the user has manage_subtasks in the parent's project as well" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project :add_work_packages, :manage_subtasks, project: child_project
        mock.allow_in_project :view_work_packages, :manage_subtasks, project: parent_project
      end
    end

    it "is permitted" do
      contract.validate
      expect(contract.errors[:parent_id]).to be_empty
    end
  end

  context "when the user only has access to view the parent but not manage_subtasks there" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project :add_work_packages, :manage_subtasks, project: child_project
        mock.allow_in_project :view_work_packages, project: parent_project
      end
    end

    it "is rejected" do
      contract.validate
      expect(contract.errors.symbols_for(:parent_id)).to include(:error_unauthorized)
    end
  end
end

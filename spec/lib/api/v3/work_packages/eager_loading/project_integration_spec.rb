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
#++require 'rspec'

require "spec_helper"
require_relative "eager_loading_mock_wrapper"

RSpec.describe API::V3::WorkPackages::EagerLoading::Project do
  let!(:parent_work_package1) { create(:work_package, project: parent_project) }
  let!(:work_package1) { create(:work_package, project:, parent: parent_work_package1) }
  let!(:work_package2) { create(:work_package, project:, parent: parent_work_package1) }
  let!(:child_work_package1) { create(:work_package, project: child_project, parent: work_package1) }
  let!(:child_work_package2) { create(:work_package, project: child_project, parent: work_package2) }
  let!(:project) { create(:project) }
  let!(:parent_project) { create(:project) }
  let!(:child_project) { create(:project) }

  describe ".apply" do
    it "preloads the projects of the work packages, their parents and children" do
      wrapped = EagerLoadingMockWrapper.wrap(described_class, [work_package1, work_package2])

      wrapped.each do |w|
        expect(w.association(:project))
          .to be_loaded

        expect(w.project).to eql project

        expect(w.parent.association(:project))
          .to be_loaded

        expect(w.parent.project).to eql parent_project

        w.children.each do |child|
          expect(child.association(:project))
            .to be_loaded

          expect(child.project).to eql child_project
        end
      end
    end
  end
end

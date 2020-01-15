#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage, type: :model do
  let(:user) { FactoryBot.create(:admin) }
  let(:role) { FactoryBot.create(:role) }
  let(:project) do
    project = FactoryBot.create(:project_with_types)
    project.add_member!(user, role)
    project
  end

  let(:project2) { FactoryBot.create(:project_with_types, types: project.types) }
  let(:work_package) {
    FactoryBot.create(:work_package, project: project,
                                      type: project.types.first,
                                      author: user)
  }
  let!(:cost_entry) { FactoryBot.create(:cost_entry, work_package: work_package, project: project, units: 3, spent_on: Date.today, user: user, comments: 'test entry') }
  let!(:cost_object) { FactoryBot.create(:cost_object, project: project) }

  def move_to_project(work_package, project)
    service = WorkPackages::MoveService.new(work_package, user)

    service.call(project)
  end

  it 'should update cost entries on move' do
    expect(work_package.project_id).to eql project.id
    expect(move_to_project(work_package, project2)).not_to be_falsey
    expect(cost_entry.reload.project_id).to eql project2.id
  end

  it 'should allow to set cost_object to nil' do
    work_package.cost_object = cost_object
    work_package.save!
    expect(work_package.cost_object).to eql cost_object

    work_package.reload
    work_package.cost_object = nil
    expect { work_package.save! }.not_to raise_error
  end
end

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage, type: :model do
  let(:stub_work_package) { FactoryGirl.build_stubbed(:work_package) }
  let(:stub_version) { FactoryGirl.build_stubbed(:version) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project) }
  let(:work_package) { FactoryGirl.create(:work_package) }
  let(:user) { FactoryGirl.create(:user) }

  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:status) { FactoryGirl.create(:status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:work_package) {
    WorkPackage.new.tap do |w|
      w.attributes = { project_id: project.id,
                       type_id: type.id,
                       author_id: user.id,
                       status_id: status.id,
                       priority: priority,
                       subject: 'test_create',
                       description: 'WorkPackage#create',
                       estimated_hours: '1:30' }
    end
  }
  describe '#new_statuses_allowed_to' do
    let(:role) { FactoryGirl.create(:role) }
    let(:type) { FactoryGirl.create(:type) }
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    let(:statuses) { (1..5).map { |_i| FactoryGirl.create(:status) } }
    let(:priority) { FactoryGirl.create :priority, is_default: true }
    let(:status) { statuses[0] }
    let(:project) do
      FactoryGirl.create(:project, types: [type]).tap { |p| p.add_member(user, role).save }
    end
    let(:workflow_a) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[1].id,
                                    author: false,
                                    assignee: false)
    }
    let(:workflow_b) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[2].id,
                                    author: true,
                                    assignee: false)
    }
    let(:workflow_c) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[3].id,
                                    author: false,
                                    assignee: true)
    }
    let(:workflow_d) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[4].id,
                                    author: true,
                                    assignee: true)
    }
    let(:workflows) { [workflow_a, workflow_b, workflow_c, workflow_d] }

    it 'should respect workflows w/o author and w/o assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, false, false))
        .to match_array([statuses[1]])
      expect(status.find_new_statuses_allowed_to([role], type, false, false))
        .to match_array([statuses[1]])
    end

    it 'should respect workflows w/ author and w/o assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, true, false))
        .to match_array([statuses[1], statuses[2]])
      expect(status.find_new_statuses_allowed_to([role], type, true, false))
        .to match_array([statuses[1], statuses[2]])
    end

    it 'should respect workflows w/o author and w/ assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, false, true))
        .to match_array([statuses[1], statuses[3]])
      expect(status.find_new_statuses_allowed_to([role], type, false, true))
        .to match_array([statuses[1], statuses[3]])
    end

    it 'should respect workflows w/ author and w/ assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, true, true))
        .to match_array([statuses[1], statuses[2], statuses[3], statuses[4]])
      expect(status.find_new_statuses_allowed_to([role], type, true, true))
        .to match_array([statuses[1], statuses[2], statuses[3], statuses[4]])
    end

    it 'should respect workflows w/o author and w/o assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        priority: priority,
                                        project: project)
      expect(work_package.new_statuses_allowed_to(user)).to match_array([statuses[0], statuses[1]])
    end

    it 'should respect workflows w/ author and w/o assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        priority: priority,
                                        project: project,
                                        author: user)
      expect(work_package.new_statuses_allowed_to(user))
        .to match_array([statuses[0], statuses[1], statuses[2]])
    end

    it 'should respect workflows w/o author and w/ assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        subject: 'test',
                                        priority: priority,
                                        project: project,
                                        assigned_to: user,
                                        author: other_user)
      expect(work_package.new_statuses_allowed_to(user))
        .to match_array([statuses[0], statuses[1], statuses[3]])
    end

    it 'should respect workflows w/ author and w/ assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        subject: 'test',
                                        priority: priority,
                                        project: project,
                                        author: user,
                                        assigned_to: user)
      expect(work_package.new_statuses_allowed_to(user))
        .to match_array([statuses[0], statuses[1], statuses[2], statuses[3], statuses[4]])
    end
  end
end

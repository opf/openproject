#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Status, type: :model do
  describe '#find_new_statuses_allowed_to and #new_statuses_allowed_to' do
    let(:role) { FactoryGirl.create(:role) }
    let(:type) { FactoryGirl.create(:type) }
    let(:user) { FactoryGirl.create(:user) }
    let(:statuses) { (1..5).map { |_i| FactoryGirl.create(:status) } }
    let(:status) { statuses[0] }
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

    before do
      workflows
    end

    it 'should respect workflows w/o author and w/o assignee' do
      expect(status.new_statuses_allowed_to([role], type, false, false))
        .to match_array([statuses[1]])
      expect(status.find_new_statuses_allowed_to([role], type, false, false))
        .to match_array([statuses[1]])
    end

    it 'should respect workflows w/ author and w/o assignee' do
      expect(status.new_statuses_allowed_to([role], type, true, false))
        .to match_array([statuses[1], statuses[2]])
      expect(status.find_new_statuses_allowed_to([role], type, true, false))
        .to match_array([statuses[1], statuses[2]])
    end

    it 'should respect workflows w/o author and w/ assignee' do
      expect(status.new_statuses_allowed_to([role], type, false, true))
        .to match_array([statuses[1], statuses[3]])
      expect(status.find_new_statuses_allowed_to([role], type, false, true))
        .to match_array([statuses[1], statuses[3]])
    end

    it 'should respect workflows w/ author and w/ assignee' do
      expect(status.new_statuses_allowed_to([role], type, true, true))
        .to match_array([statuses[1], statuses[2], statuses[3], statuses[4]])
      expect(status.find_new_statuses_allowed_to([role], type, true, true))
        .to match_array([statuses[1], statuses[2], statuses[3], statuses[4]])
    end
  end
end

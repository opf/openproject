#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
require 'features/work_packages/work_packages_page'

describe 'Copy work package', type: :feature do
  let(:user) { FactoryGirl.create(:admin) }

  let(:role_0) { FactoryGirl.create(:role) }
  let(:type_0) { FactoryGirl.create(:type) }
  let(:type_1) { FactoryGirl.create(:type) }
  let(:project) { FactoryGirl.create(:project, types: [type_0, type_1]) }
  let(:work_package) { FactoryGirl.create(:work_package,
                                          project: project,
                                          status: status_0) }
  let!(:member) { FactoryGirl.create(:member,
                                     user: user,
                                     project: project,
                                     roles: [role_0]) }

  let!(:status_0) { FactoryGirl.create(:status) }
  let!(:status_1) { FactoryGirl.create(:status) }
  let!(:status_2) { FactoryGirl.create(:status) }
  let!(:status_3) { FactoryGirl.create(:status) }
  let!(:status_4) { FactoryGirl.create(:status) }
  let!(:status_5) { FactoryGirl.create(:status) }
  let!(:workflow_0a) { FactoryGirl.create(:workflow,
                                          old_status: status_0,
                                          new_status: status_1,
                                          type_id: type_0.id,
                                          role: role_0) }
  let!(:workflow_0b) { FactoryGirl.create(:workflow,
                                          old_status: status_0,
                                          new_status: status_2,
                                          type_id: type_0.id,
                                          role: role_0) }

  let!(:workflow_2) { FactoryGirl.create(:workflow,
                                         old_status: status_0,
                                         new_status: status_3,
                                         type_id: type_1.id,
                                         role: role_0) }
  let!(:workflow_3) { FactoryGirl.create(:workflow,
                                         old_status: status_0,
                                         new_status: status_4,
                                         type_id: type_1.id,
                                         role: role_0) }
  let!(:workflow_4) { FactoryGirl.create(:workflow,
                                         old_status: status_0,
                                         new_status: status_5,
                                         type_id: type_1.id,
                                         role: role_0) }

  let(:work_packages_page) { WorkPackagesPage.new(project) }

  context 'when no type is selected' do
    before do
      allow(User).to receive(:current).and_return(user)
      work_packages_page.visit_copy(work_package.id)
    end

    it 'should display all statuses' do
      expect(expect(page.find('#status_id').text).to include(status_2.name,
                                                             status_1.name,
                                                             status_3.name,
                                                             status_4.name,
                                                             status_5.name))
    end
  end

  context 'when select first type', js: true do
    before do
      allow(User).to receive(:current).and_return(user)
      work_packages_page.visit_copy(work_package.id)
      find('#new_type_id option', text: type_0.name).select_option
    end

    it 'should loaded statuses for selected type' do
      expect(expect(page.find('#status_id').text).to include(status_2.name, status_1.name))
    end
  end
end

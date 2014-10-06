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

describe 'Bulk edit work package', type: :feature_type do
  let(:user) { FactoryGirl.create(:admin) }

  let(:role) { FactoryGirl.create(:role) }
  let(:bug_type) { FactoryGirl.create(:type, name: 'Bug') }
  let(:feature_type) { FactoryGirl.create(:type, name: 'Feature') }
  let(:project) { FactoryGirl.create(:project, types: [bug_type, feature_type]) }
  let!(:work_package) do
    FactoryGirl.create(:work_package,
                       project: project,
                       status: status_0,
                       type: bug_type)
  end
  let!(:work_package_1) do
    FactoryGirl.create(:work_package,
                       status: status_0,
                       project: project,
                       type: feature_type)
  end
  let!(:member) do
    FactoryGirl.create(:member,
                       user: user,
                       project: project,
                       roles: [role])
  end

  let!(:status_0) { FactoryGirl.create(:status) }
  let!(:status_1) { FactoryGirl.create(:status) }
  let!(:status_2) { FactoryGirl.create(:status) }
  let!(:status_3) { FactoryGirl.create(:status) }
  let!(:status_4) { FactoryGirl.create(:status) }
  let!(:status_5) { FactoryGirl.create(:status) }
  let!(:workflow_0a) do
    FactoryGirl.create(:workflow,
                       old_status: status_0,
                       new_status: status_1,
                       type_id: bug_type.id,
                       role: role)
  end
  let!(:workflow_0b) do
    FactoryGirl.create(:workflow,
                       old_status: status_0,
                       new_status: status_2,
                       type_id: bug_type.id,
                       role: role)
  end
  let!(:workflow_2) do
    FactoryGirl.create(:workflow,
                       old_status: status_0,
                       new_status: status_3,
                       type_id: feature_type.id,
                       role: role)
  end
  let!(:workflow_3) do
    FactoryGirl.create(:workflow,
                       old_status: status_0,
                       new_status: status_4,
                       type_id: feature_type.id,
                       role: role)
  end
  let!(:workflow_4) do
    FactoryGirl.create(:workflow,
                       old_status: status_0,
                       new_status: status_5,
                       type_id: feature_type.id,
                       role: role)
  end

  before do
    allow(User).to receive(:current).and_return(user)
    visit edit_work_packages_bulk_path(ids: [work_package.id, work_package_1.id])
  end
  context 'when no type is selected', js: true do
    it 'should display all statuses' do
      expect(expect(page.find('#work_package_status_id').text).to include(status_1.name,
                                                             status_2.name))
    end
  end

  context 'when change the type', js: true do
    before do
      find('#work_package_type_id option', text: feature_type.name).select_option
    end

    it 'should loaded statuses for selected type' do
      expect(page.find('#work_package_status_id').text).to include(status_3.name, status_4.name, status_5.name)
    end
  end
end

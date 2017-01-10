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

describe 'WorkPackage-Visibility', type: :model do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:anonymous) { FactoryGirl.create(:anonymous) }
  let(:user) { FactoryGirl.create(:user) }
  let(:public_project) { FactoryGirl.create(:project, is_public: true) }
  let(:private_project) { FactoryGirl.create(:project, is_public: false) }
  let(:other_project) { FactoryGirl.create(:project, is_public: true) }
  let(:view_work_packages) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:view_work_packages_role2) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }

  describe 'of public projects' do
    subject { FactoryGirl.create(:work_package, project: public_project) }

    it 'is viewable by anonymous, with the view_work_packages permissison' do
      # it is not really clear, where these kind of "preconditions" belong to: This setting
      # is a default in Redmine::DefaultData::Loader - but this not loaded in the tests: here we
      # just make sure, that the workpackage is visible, when this permission is set
      Role.anonymous.add_permission! :view_work_packages
      expect(WorkPackage.visible(anonymous)).to match_array [subject]
    end
  end

  describe 'of private projects' do
    subject { FactoryGirl.create(:work_package, project: private_project) }

    it 'is visible for the admin, even if the project is private' do
      expect(WorkPackage.visible(admin)).to match_array [subject]
    end

    it 'is not visible for anonymous users, when the project is private' do
      expect(WorkPackage.visible(anonymous)).to match_array []
    end

    it 'is visible for members of the project, with the view_work_packages permissison' do
      FactoryGirl.create(:member,
                         user: user,
                         project: private_project,
                         role_ids: [view_work_packages.id])

      expect(WorkPackage.visible(user)).to match_array [subject]
    end

    it 'is only returned once for members with two roles having view_work_packages permission' do
      subject

      FactoryGirl.create(:member,
                         user: user,
                         project: private_project,
                         role_ids: [view_work_packages.id,
                                    view_work_packages_role2.id])

      expect(WorkPackage.visible(user).pluck(:id)).to match_array [subject.id]
    end

    it 'is not visible for non-members of the project without the view_work_packages permissison' do
      expect(WorkPackage.visible(user)).to match_array []
    end

    it 'is not visible for members of the project, without the view_work_packages permissison' do
      no_permission = FactoryGirl.create(:role, permissions: [:no_permission])
      FactoryGirl.create(:member,
                         user: user,
                         project: private_project,
                         role_ids: [no_permission.id])

      expect(WorkPackage.visible(user)).to match_array []
    end
  end
end

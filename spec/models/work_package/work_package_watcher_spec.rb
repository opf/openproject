#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe WorkPackage do
  describe :watcher do
    let(:user) { FactoryGirl.create(:user) }
    let(:project) { FactoryGirl.create(:project) }
    let(:role) { FactoryGirl.create(:role,
                                    permissions: [:view_work_packages]) }
    let(:project_member) { FactoryGirl.create(:member,
                                              project: project,
                                              principal: user,
                                              roles: [role]) }
    let(:work_package) { FactoryGirl.create(:work_package,
                                            project: project) }

    context :recipients do
      let(:watcher) { Watcher.new(watchable: work_package,
                                  user: user) }


      before do
        project_member

        watcher.save!

        role.remove_permission! :view_work_packages

        work_package.reload
      end

      context :watcher do
        subject { work_package.watched_by?(user) }

        it { should be_true }
      end

      context :recipients do
        subject { work_package.watcher_recipients }

        it { should_not include(user.mail) }
      end
    end

    context '#possible_watcher_users' do
      let!(:user_allowed_to_view_work_packages) do
        FactoryGirl.create(:user).tap { |user| project.add_member!(user, role) }
      end

      it 'contains exactly those users who are allowed to view work packages' do
        work_package.possible_watcher_users.should == [user_allowed_to_view_work_packages]
      end
    end
  end
end

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

describe WorkPackage, type: :model do
  describe ActionMailer::Base do
    let(:user_1) {
      FactoryGirl.build(:user,
                        mail: 'dlopper@somenet.foo',
                        member_in_project: project)
    }
    let(:user_2) {
      FactoryGirl.build(:user,
                        mail: 'jsmith@somenet.foo',
                        member_in_project: project)
    }
    let(:project) { FactoryGirl.create(:project) }
    let(:work_package) { FactoryGirl.build(:work_package, project: project) }

    before do
      allow(work_package).to receive(:recipients).and_return([user_1])
      allow(work_package).to receive(:watcher_recipients).and_return([user_2])

      work_package.save
    end

    subject { ActionMailer::Base.deliveries.size }

    it { is_expected.to eq(2) }

    context 'stale object' do
      before do
        wp = WorkPackage.find(work_package.id)

        wp.subject = 'Subject update'
        wp.save!

        ActionMailer::Base.deliveries.clear

        work_package.subject = 'A different subject update'
        work_package.save! rescue nil
      end

      it { is_expected.to eq(0) }
    end

    context 'no notification' do
      before do
        ActionMailer::Base.deliveries.clear # clear mails sent due to prior WP creation

        JournalManager.send_notification = false

        work_package.save!
      end

      it { is_expected.to eq(0) }
    end

    context 'group_assigned_work_package' do
      let(:group) { FactoryGirl.create(:group) }

      before do
        group.users << user_1
        work_package.assigned_to = group
      end

      subject { work_package.recipients }

      it { is_expected.to include(user_1) }
    end
  end
end

#-- encoding: UTF-8
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

describe DeliverWatcherNotificationJob, type: :model do
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:watcher_setter) { FactoryGirl.create(:user) }
  let(:watcher_user) do
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:work_package) { FactoryGirl.build(:work_package, project: project) }
  let(:watcher) { FactoryGirl.create(:watcher, watchable: work_package, user: watcher_user) }

  subject { described_class.new(watcher.id, watcher_user.id, watcher_setter.id) }

  before do
    # make sure no actual calls make it into the UserMailer
    allow(UserMailer).to receive(:work_package_watcher_added)
      .and_return(double('mail', deliver_now: nil))
  end

  it 'sends a mail' do
    expect(UserMailer).to receive(:work_package_watcher_added).with(work_package,
                                                                    watcher_user,
                                                                    watcher_setter)
    subject.perform
  end

  describe 'exceptions' do
    describe 'exceptions should be raised' do
      before do
        mail = double('mail')
        allow(mail).to receive(:deliver_now).and_raise(SocketError)
        expect(UserMailer).to receive(:work_package_watcher_added).and_return(mail)
      end

      it 'raises the error' do
        expect { subject.perform }.to raise_error(SocketError)
      end
    end
  end
end

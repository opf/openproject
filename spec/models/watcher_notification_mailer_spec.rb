#-- encoding: UTF-8
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

describe WatcherNotificationMailer do
  def call_listener(watcher, watcher_setter)
    described_class.handle_watcher(watcher, watcher_setter)
  end

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing

    allow(Delayed::Job).to receive(:enqueue)
  end

  describe 'watcher setup' do
    let(:project)       { FactoryGirl.create(:project) }
    let(:work_package)  { FactoryGirl.create(:work_package, project: project) }

    let(:watcher_setter) do
      FactoryGirl.create(:user,
                        mail_notification: 'all',
                        member_in_project: project)
    end

    let(:watcher) do
      FactoryGirl.create(:watcher, user: FactoryGirl.create(:user,
                                          mail_notification: 'all',
                                          member_in_project: project),
                                  watchable: work_package)
    end

    context 'watcher_added and user wants to be notified' do
      it 'notifies the watcher' do
        expect(Delayed::Job).to receive(:enqueue)
        call_listener(watcher, watcher_setter)
      end
    end

    context 'watcher_added and user does NOT want to be notified' do
      it 'does not notify the watcher' do
        allow(watcher.user).to receive(:notify_about?).with(watcher).and_return(false)
        expect(Delayed::Job).not_to receive(:enqueue)
        call_listener(watcher, watcher_setter)
      end
    end
  end
end


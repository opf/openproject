#-- encoding: UTF-8
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
require 'spec_helper'

shared_examples 'WatcherNotificationMailer' do |watcher_notification_job|
  let(:watcher_notification_job) { watcher_notification_job }

  def call_listener(watcher, watcher_changer)
    described_class.handle_watcher(watcher, watcher_changer)
  end

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing
  end

  describe 'watcher setup' do
    let(:work_package) {
      work_package = FactoryBot.build_stubbed(:work_package)
      journal = FactoryBot.build_stubbed(:work_package_journal)

      allow(work_package).to receive(:journals).and_return([journal])
      work_package
    }

    let(:watcher_changer) do
      FactoryBot.build_stubbed(:user,
                                mail_notification: watching_setting,
                                preference: user_pref)
    end

    let(:watching_setting) { 'all' }
    let(:self_notified) { true }
    let(:watching_user) {
      FactoryBot.build_stubbed(:user,
                                mail_notification: watching_setting,
                                preference: user_pref)
    }
    let(:user_pref) {
      pref = FactoryBot.build_stubbed(:user_preference)

      allow(pref).to receive(:self_notified?).and_return(self_notified)

      pref
    }

    let(:watcher) do
      FactoryBot.build_stubbed(:watcher, user: watching_user,
                                          watchable: work_package)
    end

    shared_examples_for 'notifies the added watcher for' do |setting|
      let(:watching_setting) { setting }

      context 'when added by a different user
               and has self_notified activated' do
        let(:self_notified) { true }

        it 'notifies the watcher' do
          expect(watcher_notification_job).to receive(:perform_later)
          call_listener(watcher, watcher_changer)
        end
      end

      context 'when added by a different user
               and has self_notified deactivated' do
        let(:self_notified) { false }

        it 'notifies the watcher' do
          expect(watcher_notification_job).to receive(:perform_later)
          call_listener(watcher, watcher_changer)
        end
      end

      context 'but when watcher is added by theirself
               and has self_notified deactivated' do
        let(:watching_user) { watcher_changer }
        let(:self_notified) { false }

        it 'does not notify the watcher' do
          expect(watcher_notification_job).not_to receive(:perform_later)
          call_listener(watcher, watcher_changer)
        end
      end

      context 'but when watcher is added by theirself
               and has self_notified activated' do
        let(:watching_user) { watcher_changer }
        let(:self_notified) { true }

        it 'notifies the watcher' do
          expect(watcher_notification_job).to receive(:perform_later)
          call_listener(watcher, watcher_changer)
        end
      end
    end

    shared_examples_for 'does not notify the added watcher for' do |setting|
      let(:watching_setting) { setting }

      context 'when added by a different user' do
        it 'does not notify the watcher' do
          expect(watcher_notification_job).not_to receive(:perform_later)
          call_listener(watcher, watcher_changer)
        end
      end

      context 'when watcher is added by theirself' do
        let(:watching_user) { watcher_changer }
        let(:self_notified) { false }

        it 'does not notify the watcher' do
          expect(watcher_notification_job).not_to receive(:perform_later)
          call_listener(watcher, watcher_changer)
        end
      end
    end

    it_behaves_like 'does not notify the added watcher for', 'none'

    it_behaves_like 'notifies the added watcher for', 'all'

    it_behaves_like 'notifies the added watcher for', 'only_my_events'

    it_behaves_like 'notifies the added watcher for', 'only_owner' do
      before do
        work_package.author = watching_user
      end
    end
    it_behaves_like 'does not notify the added watcher for', 'only_owner' do
      before do
        work_package.author = watcher_changer
      end
    end

    it_behaves_like 'notifies the added watcher for', 'only_assigned' do
      before do
        work_package.assigned_to = watching_user
      end
    end
    it_behaves_like 'does not notify the added watcher for', 'only_assigned' do
      before do
        work_package.assigned_to = watcher_changer
      end
    end

    it_behaves_like 'notifies the added watcher for', 'selected' do
      let(:project) { FactoryBot.build_stubbed(:project) }
      before do
        work_package.project = project
        allow(watching_user).to receive(:notified_projects_ids).and_return([project.id])
      end
    end
    it_behaves_like 'does not notify the added watcher for', 'selected' do
      let(:project) { FactoryBot.build_stubbed(:project) }
      before do
        work_package.project = project
        allow(watching_user).to receive(:notified_projects_ids).and_return([])
      end
    end
    it_behaves_like 'does not notify the added watcher for', 'selected' do
      let(:project) { FactoryBot.build_stubbed(:project) }
      before do
        allow(watching_user).to receive(:notified_projects_ids).and_return([project.id])
      end
    end
  end
end

describe WatcherRemovedNotificationMailer do
  include_examples "WatcherNotificationMailer", DeliverWatcherRemovedNotificationJob
end

describe WatcherAddedNotificationMailer do
  include_examples "WatcherNotificationMailer", DeliverWatcherAddedNotificationJob
end

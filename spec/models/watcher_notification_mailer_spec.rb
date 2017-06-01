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
    let(:work_package) {
      work_package = FactoryGirl.build_stubbed(:work_package)
      journal = FactoryGirl.build_stubbed(:work_package_journal)

      allow(work_package).to receive(:journals).and_return([journal])
      work_package
    }

    let(:watcher_setter) do
      FactoryGirl.build_stubbed(:user,
                                mail_notification: watching_setting,
                                preference: user_pref)
    end

    let(:watching_setting) { 'all' }
    let(:self_notified) { true }
    let(:watching_user) {
      FactoryGirl.build_stubbed(:user,
                                mail_notification: watching_setting,
                                preference: user_pref)
    }
    let(:user_pref) {
      pref = FactoryGirl.build_stubbed(:user_preference)

      allow(pref).to receive(:self_notified?).and_return(self_notified)

      pref
    }

    let(:watcher) do
      FactoryGirl.build_stubbed(:watcher, user: watching_user,
                                          watchable: work_package)
    end

    shared_examples_for 'notifies the added watcher for' do |setting|
      let(:watching_setting) { setting }

      context 'when added by a different user
               and has self_notified activated' do
        let(:self_notified) { true }

        it 'notifies the watcher' do
          expect(Delayed::Job).to receive(:enqueue)
          call_listener(watcher, watcher_setter)
        end
      end

      context 'when added by a different user
               and has self_notified deactivated' do
        let(:self_notified) { false }

        it 'notifies the watcher' do
          expect(Delayed::Job).to receive(:enqueue)
          call_listener(watcher, watcher_setter)
        end
      end

      context 'but when watcher is added by theirself
               and has self_notified deactivated' do
        let(:watching_user) { watcher_setter }
        let(:self_notified) { false }

        it 'does not notify the watcher' do
          expect(Delayed::Job).to_not receive(:enqueue)
          call_listener(watcher, watcher_setter)
        end
      end

      context 'but when watcher is added by theirself
               and has self_notified activated' do
        let(:watching_user) { watcher_setter }
        let(:self_notified) { true }

        it 'notifies the watcher' do
          expect(Delayed::Job).to receive(:enqueue)
          call_listener(watcher, watcher_setter)
        end
      end
    end

    shared_examples_for 'does not notify the added watcher for' do |setting|
      let(:watching_setting) { setting }

      context 'when added by a different user' do
        it 'does not notify the watcher' do
          expect(Delayed::Job).to_not receive(:enqueue)
          call_listener(watcher, watcher_setter)
        end
      end

      context 'when watcher is added by theirself' do
        let(:watching_user) { watcher_setter }
        let(:self_notified) { false }

        it 'does not notify the watcher' do
          expect(Delayed::Job).to_not receive(:enqueue)
          call_listener(watcher, watcher_setter)
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
        work_package.author = watcher_setter
      end
    end

    it_behaves_like 'notifies the added watcher for', 'only_assigned' do
      before do
        work_package.assigned_to = watching_user
      end
    end
    it_behaves_like 'does not notify the added watcher for', 'only_assigned' do
      before do
        work_package.assigned_to = watcher_setter
      end
    end

    it_behaves_like 'notifies the added watcher for', 'selected' do
      let(:project) { FactoryGirl.build_stubbed(:project) }
      before do
        work_package.project = project
        allow(watching_user).to receive(:notified_projects_ids).and_return([project.id])
      end
    end
    it_behaves_like 'does not notify the added watcher for', 'selected' do
      let(:project) { FactoryGirl.build_stubbed(:project) }
      before do
        work_package.project = project
        allow(watching_user).to receive(:notified_projects_ids).and_return([])
      end
    end
    it_behaves_like 'does not notify the added watcher for', 'selected' do
      let(:project) { FactoryGirl.build_stubbed(:project) }
      before do
        allow(watching_user).to receive(:notified_projects_ids).and_return([project.id])
      end
    end
  end
end

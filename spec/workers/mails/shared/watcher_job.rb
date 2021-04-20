#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

shared_examples "watcher job" do |action|
  subject { described_class.perform_now(watcher_parameter, watcher_changer) }

  let(:action) { action }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:watcher_changer) do
    FactoryBot.build_stubbed(:user,
                             mail_notification: watching_setting,
                             preference: user_pref)
  end
  let(:work_package) { FactoryBot.build_stubbed(:work_package, project: project) }
  let(:watcher) do
    FactoryBot.build_stubbed(:watcher, watchable: work_package, user: watching_user)
  end
  let(:self_notified) { true }
  let(:user_pref) do
    pref = FactoryBot.build_stubbed(:user_preference)

    allow(pref).to receive(:self_notified?).and_return(self_notified)

    pref
  end
  let(:watching_setting) { 'all' }
  let(:watching_user) do
    FactoryBot.build_stubbed(:user,
                             mail_notification: watching_setting,
                             preference: user_pref)
  end

  before do
    # make sure no actual calls make it into the UserMailer
    allow(UserMailer)
      .to receive(:work_package_watcher_changed)
      .and_return(double('mail', deliver_now: nil))
  end

  shared_examples_for 'sends a mail' do
    it 'sends a mail' do
      subject
      expect(UserMailer)
        .to have_received(:work_package_watcher_changed)
        .with(work_package,
              watching_user,
              watcher_changer,
              action)
    end
  end

  shared_examples_for 'sends no mail' do
    it 'sends no mail' do
      subject
      expect(UserMailer)
        .not_to have_received(:work_package_watcher_changed)
    end
  end

  describe 'exceptions' do
    describe 'exceptions should be raised' do
      before do
        mail = double('mail')
        allow(mail).to receive(:deliver_now).and_raise(SocketError)
        expect(UserMailer).to receive(:work_package_watcher_changed).and_return(mail)
      end

      it 'raises the error' do
        expect { subject }.to raise_error(SocketError)
      end
    end
  end

  shared_examples_for 'notifies the watcher for' do |setting|
    let(:watching_setting) { setting }

    context 'when added by a different user
               and has self_notified activated' do
      let(:self_notified) { true }

      it_behaves_like 'sends a mail'
    end

    context 'when added by a different user
               and has self_notified deactivated' do
      let(:self_notified) { false }

      it_behaves_like 'sends a mail'
    end

    context 'but when watcher is added by theirself
               and has self_notified deactivated' do
      let(:watching_user) { watcher_changer }
      let(:self_notified) { false }

      it_behaves_like 'sends no mail'
    end

    context 'but when watcher is added by theirself
               and has self_notified activated' do
      let(:watching_user) { watcher_changer }
      let(:self_notified) { true }

      it_behaves_like 'sends a mail'
    end
  end

  shared_examples_for 'does not notify the watcher for' do |setting|
    let(:watching_setting) { setting }

    context 'when added by a different user' do
      it_behaves_like 'sends no mail'
    end

    context 'when watcher is added by theirself' do
      let(:watching_user) { watcher_changer }
      let(:self_notified) { false }

      it_behaves_like 'sends no mail'
    end
  end

  it_behaves_like 'does not notify the watcher for', 'none'

  it_behaves_like 'notifies the watcher for', 'all'

  it_behaves_like 'notifies the watcher for', 'only_my_events'

  it_behaves_like 'notifies the watcher for', 'only_owner' do
    before do
      work_package.author = watching_user
    end
  end

  it_behaves_like 'does not notify the watcher for', 'only_owner' do
    before do
      work_package.author = watcher_changer
    end
  end

  it_behaves_like 'notifies the watcher for', 'only_assigned' do
    before do
      work_package.assigned_to = watching_user
    end
  end

  it_behaves_like 'does not notify the watcher for', 'only_assigned' do
    before do
      work_package.assigned_to = watcher_changer
    end
  end

  it_behaves_like 'notifies the watcher for', 'selected' do
    before do
      work_package.project = project
      allow(watching_user).to receive(:notified_projects_ids).and_return([project.id])
    end
  end

  it_behaves_like 'does not notify the watcher for', 'selected' do
    before do
      work_package.project = project
      allow(watching_user).to receive(:notified_projects_ids).and_return([])
    end
  end

  it_behaves_like 'does not notify the watcher for', 'selected' do
    let(:work_package) { FactoryBot.build_stubbed(:work_package) }
    before do
      allow(watching_user).to receive(:notified_projects_ids).and_return([project.id])
    end
  end
end
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.shared_examples "watcher job" do |action|
  subject { described_class.perform_now(watcher_parameter, watcher_changer) }

  let(:action) { action }
  let(:project) { build_stubbed(:project) }
  let(:watcher_changer) do
    build_stubbed(:user)
  end
  let(:work_package) { build_stubbed(:work_package, type: build_stubbed(:type), project:) }
  let(:watcher) do
    build_stubbed(:watcher, watchable: work_package, user: watching_user)
  end
  let(:user_pref) do
    build_stubbed(:user_preference)
  end
  let(:notification_settings) do
    [build_stubbed(:notification_setting)]
  end
  let(:watching_user) do
    build_stubbed(:user,
                  notification_settings:).tap do |user|
      allow(user)
        .to receive(:notification_settings)
              .and_return(notification_settings)

      without_partial_double_verification do
        allow(notification_settings)
          .to receive(:applicable)
                .and_return(notification_settings)
      end
    end
  end

  before do
    # make sure no actual calls make it into the UserMailer
    allow(WorkPackageMailer)
      .to receive(:watcher_changed)
      .and_return(double("mail", deliver_now: nil))
  end

  shared_examples_for "sends a mail" do
    it "sends a mail" do
      subject
      expect(WorkPackageMailer)
        .to have_received(:watcher_changed)
        .with(work_package,
              watching_user,
              watcher_changer,
              action)
    end
  end

  shared_examples_for "sends no mail" do
    it "sends no mail" do
      subject
      expect(WorkPackageMailer)
        .not_to have_received(:watcher_changed)
    end
  end

  describe "exceptions" do
    describe "exceptions should be raised" do
      before do
        mail = double("mail")
        allow(mail).to receive(:deliver_now).and_raise(SocketError)
        allow(WorkPackageMailer).to receive(:watcher_changed).and_return(mail)
      end

      it "raises the error" do
        expect { subject }.to raise_error(SocketError)
      end
    end
  end

  shared_examples_for "notifies the watcher" do
    context "when added by a different user" do
      it_behaves_like "sends a mail"
    end

    context "when watcher is added by theirself" do
      let(:watcher_changer) { watching_user }

      it_behaves_like "sends no mail"
    end
  end

  shared_examples_for "does not notify the watcher" do
    context "when added by a different user" do
      it_behaves_like "sends no mail"
    end

    context "when watcher is added by theirself" do
      let(:watcher_changer) { watching_user }

      it_behaves_like "sends no mail"
    end
  end

  it_behaves_like "notifies the watcher" do
    let(:notification_settings) do
      [build_stubbed(:notification_setting, mentioned: false, assignee: false, responsible: false, watched: true)]
    end
  end

  it_behaves_like "notifies the watcher" do
    let(:notification_settings) do
      [build_stubbed(:notification_setting, mentioned: false, assignee: false, responsible: false, watched: true)]
    end
  end

  it_behaves_like "does not notify the watcher" do
    let(:notification_settings) do
      [build_stubbed(:notification_setting, mentioned: false, assignee: true, responsible: true, watched: false)]
    end
  end

  it_behaves_like "does not notify the watcher" do
    let(:notification_settings) do
      [build_stubbed(:notification_setting, mentioned: true, assignee: false, responsible: false, watched: false)]
    end
  end

  it_behaves_like "does not notify the watcher" do
    # Regression test for notification settings being empty
    let(:notification_settings) do
      []
    end
  end
end

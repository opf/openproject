# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Notifications::MarkUnreadService, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:author) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:work_package) { create(:work_package, project:, author:) }

  let(:journal) { create(:work_package_journal, user: author, notes: "A comment", journable: work_package, version: 2) }

  subject(:call) { described_class.new(user:).call(journal:) }

  context "without an existing notification for the journal" do
    it "creates an unread notification with the marked_as_unread reason that sends no mail" do
      expect { call }.to change(Notification, :count).by(1)

      expect(call).to be_success
      expect(Notification.last).to have_attributes(
        recipient: user,
        resource: work_package,
        journal:,
        actor: author,
        reason: "marked_as_unread",
        read_ian: false,
        mail_reminder_sent: nil,
        mail_alert_sent: nil
      )
    end
  end

  context "with a read notification for the journal" do
    let!(:notification) do
      create(:notification, recipient: user, resource: work_package, journal:, reason: :mentioned, read_ian: true)
    end

    it "marks it unread and keeps its reason" do
      expect { call }.not_to change(Notification, :count)

      expect(call).to be_success
      expect(notification.reload).to have_attributes(read_ian: false, reason: "mentioned")
    end
  end

  context "when marking the user's own journal" do
    let(:journal) { create(:work_package_journal, user:, notes: "My comment", journable: work_package, version: 2) }

    it "creates an unread notification" do
      expect(call).to be_success
      expect(Notification.last).to have_attributes(journal:, actor: user, read_ian: false)
    end
  end

  context "when the user cannot see the work package" do
    let(:user) { create(:user) }

    it "fails without creating a notification" do
      expect { call }.not_to change(Notification, :count)

      expect(call).to be_failure
    end
  end

  context "when the user is anonymous" do
    let(:user) { User.anonymous }

    it "fails" do
      expect(call).to be_failure
    end
  end
end

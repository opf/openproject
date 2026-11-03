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

RSpec.describe Notifications::MarkReadService, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:author) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:work_package) { create(:work_package, project:, author:) }

  let(:journal) { create(:work_package_journal, user: author, notes: "A comment", journable: work_package, version: 2) }

  subject(:call) { described_class.new(user:).call(journal:) }

  context "with an unread notification for the journal" do
    let!(:notification) do
      create(:notification, recipient: user, resource: work_package, journal:, reason: :mentioned, read_ian: false)
    end

    it "marks it read and keeps its reason" do
      expect { call }.not_to change(Notification, :count)

      expect(call).to be_success
      expect(notification.reload).to have_attributes(read_ian: true, reason: "mentioned")
    end
  end

  context "with multiple unread notifications for the journal" do
    let!(:notifications) do
      [
        create(:notification, recipient: user, resource: work_package, journal:, reason: :mentioned, read_ian: false),
        create(:notification, recipient: user, resource: work_package, journal:, reason: :assigned, read_ian: false)
      ]
    end

    it "marks all of them read" do
      expect(call).to be_success
      notifications.each do |notification|
        expect(notification.reload.read_ian).to be true
      end
    end
  end

  context "with an already-read notification for the journal" do
    let!(:notification) do
      create(:notification, recipient: user, resource: work_package, journal:, reason: :mentioned, read_ian: true)
    end

    it "does not touch it" do
      expect { call }.not_to change { notification.reload.updated_at }

      expect(call).to be_success
    end
  end

  context "without any notification for the journal" do
    it "succeeds without creating a notification" do
      expect { call }.not_to change(Notification, :count)

      expect(call).to be_success
    end
  end

  context "with a notification for another user" do
    let(:other_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
    let!(:notification) do
      create(:notification, recipient: other_user, resource: work_package, journal:, reason: :mentioned, read_ian: false)
    end

    it "does not touch it" do
      expect(call).to be_success
      expect(notification.reload.read_ian).to be false
    end
  end

  context "when the user cannot see the work package" do
    let(:user) { create(:user) }
    let!(:notification) do
      create(:notification, recipient: user, resource: work_package, journal:, reason: :mentioned, read_ian: false)
    end

    it "fails without touching the notification" do
      expect(call).to be_failure
      expect(notification.reload.read_ian).to be false
    end
  end

  context "when the user is anonymous" do
    let(:user) { User.anonymous }

    it "fails" do
      expect(call).to be_failure
    end
  end
end

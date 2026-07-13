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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Reminder do
  describe "Associations" do
    it { is_expected.to belong_to(:remindable) }
    it { is_expected.to belong_to(:creator).class_name("User") }
    it { is_expected.to have_many(:reminder_notifications).dependent(:destroy) }
    it { is_expected.to have_many(:notifications).through(:reminder_notifications) }
  end

  describe "Scopes" do
    describe ".visible" do
      it "returns reminders where the creator is the given user" do
        role = create(:project_role, permissions: %i[view_work_packages])
        project = create(:project)
        user = create(:user, member_with_roles: { project => role })
        other_user = create(:user, member_with_roles: { project => role })
        work_package = create(:work_package, project:)
        reminder = create(:reminder, creator: user, remindable: work_package)
        _other_reminder = create(:reminder, creator: other_user, remindable: work_package)

        expect(described_class.visible(user)).to contain_exactly(reminder)
      end

      it "excludes reminders whose remindable is no longer visible to the user" do
        role = create(:project_role, permissions: %i[view_work_packages])
        project = create(:project)
        user = create(:user, member_with_roles: { project => role })
        work_package = create(:work_package, project:)
        reminder = create(:reminder, creator: user, remindable: work_package)

        expect(described_class.visible(user)).to contain_exactly(reminder)

        Member.where(principal: user, project:).destroy_all

        expect(described_class.visible(user)).to be_empty
      end
    end

    describe ".upcoming_and_visible_to" do
      it "returns reminders where the creator is the given user" \
         "and there are no reminder_notifications for it yet" do
        role = create(:project_role, permissions: %i[view_work_packages])
        project = create(:project)
        user = create(:user, member_with_roles: { project => role })
        other_user = create(:user, member_with_roles: { project => role })
        work_package = create(:work_package, project:)
        reminder = create(:reminder, creator: user, remindable: work_package)
        _another_reminder_with_notification = create(:reminder, creator: user, remindable: work_package) do |r|
          create(:reminder_notification, reminder: r)
        end
        _other_users_reminder_with_notification = create(:reminder, creator: other_user, remindable: work_package) do |r|
          create(:reminder_notification, reminder: r)
        end
        _other_users_reminder = create(:reminder, creator: other_user, remindable: work_package)

        expect(described_class.upcoming_and_visible_to(user)).to contain_exactly(reminder)
      end

      it "excludes reminders whose remindable is no longer visible to the user" do
        role = create(:project_role, permissions: %i[view_work_packages])
        project = create(:project)
        user = create(:user, member_with_roles: { project => role })
        work_package = create(:work_package, project:)
        reminder = create(:reminder, creator: user, remindable: work_package)

        expect(described_class.upcoming_and_visible_to(user)).to contain_exactly(reminder)

        Member.where(principal: user, project:).destroy_all

        expect(described_class.upcoming_and_visible_to(user)).to be_empty
      end
    end
  end

  describe "#visible?" do
    let(:user) { build_stubbed(:user) }
    let(:other_user) { build_stubbed(:user) }
    let(:remindable) { build_stubbed(:work_package) }
    let(:reminder) { build_stubbed(:reminder, creator: user, remindable: remindable) }

    context "when the creator is the current user" do
      context "and the user has access to the remindable" do
        current_user { user }

        before do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project(:view_work_packages, project: remindable.project)
          end
        end

        it "returns true" do
          expect(reminder).to be_visible
        end
      end

      context "and the user does not have access to the remindable" do
        current_user { user }

        it "returns false" do
          expect(reminder).not_to be_visible
        end
      end
    end

    context "when the current user is not the same as the creator" do
      current_user { other_user }

      context "and the user has access to the remindable" do
        before do
          mock_permissions_for(other_user) do |mock|
            mock.allow_in_project(:view_work_packages, project: remindable.project)
          end
        end

        it "returns false" do
          expect(reminder).not_to be_visible

          aggregate_failures "remindable is visible to the other user" do
            expect(remindable.visible?(other_user)).to be(true)
          end
        end
      end
    end
  end

  describe "#unread_notifications?" do
    context "with an unread notification" do
      subject { create(:reminder, :with_unread_notifications) }

      it { is_expected.to be_an_unread_notification }
      it { expect(subject.unread_notifications).to be_present }
    end

    context "with no unread notifications" do
      subject { create(:reminder, :with_read_notifications) }

      it { is_expected.not_to be_an_unread_notification }
      it { expect(subject.unread_notifications).to be_empty }
    end

    context "with no notifications" do
      subject { build_stubbed(:reminder) }

      it { is_expected.not_to be_an_unread_notification }
      it { expect(subject.unread_notifications).to be_empty }
    end
  end

  describe "#scheduled?" do
    it "returns true if job_id is present" do
      reminder = build_stubbed(:reminder, :scheduled)

      expect(reminder).to be_scheduled
    end

    it "returns false if job_id is not present" do
      reminder = build(:reminder, job_id: nil)

      expect(reminder).not_to be_scheduled
    end

    it "returns false if completed_at is present" do
      reminder = build(:reminder, :scheduled, :completed)

      expect(reminder).not_to be_scheduled
    end
  end

  describe "#completed?" do
    it "returns true if completed_at is present" do
      reminder = build(:reminder, :completed)

      expect(reminder).to be_completed
    end

    it "returns false if completed_at is not present" do
      reminder = build(:reminder, completed_at: nil)

      expect(reminder).not_to be_completed
    end
  end
end

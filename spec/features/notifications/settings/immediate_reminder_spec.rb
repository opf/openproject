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

RSpec.describe "Immediate reminder settings", :js do
  shared_examples "immediate reminder settings" do
    it "allows to configure the reminder settings" do
      # Save prefs so we can reload them later
      pref.save!

      # Configure the reminders
      reminders_settings_page.visit!

      # By default the immediate reminder is checked
      expect(pref.immediate_reminders[:mentioned]).to be(true)
      reminders_settings_page.expect_immediate_reminder "mentioned", true

      # By default the personal reminder is checked
      expect(pref.immediate_reminders[:personal_reminder]).to be(true)
      reminders_settings_page.expect_immediate_reminder "personal_reminder", true

      reminders_settings_page.set_immediate_reminder "mentioned", false
      reminders_settings_page.set_immediate_reminder "personal_reminder", false

      reminders_settings_page.save_immediate_reminders

      reminders_settings_page.expect_and_dismiss_flash

      reminders_settings_page.reload!

      reminders_settings_page.expect_immediate_reminder "mentioned", false
      reminders_settings_page.expect_immediate_reminder "personal_reminder", false

      expect(pref.reload.immediate_reminders[:mentioned]).to be(false)
      expect(pref.reload.immediate_reminders[:personal_reminder]).to be(false)
    end
  end

  context "with the my page" do
    let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }
    let(:pref) { current_user.pref }

    current_user do
      create(:user)
    end

    it_behaves_like "immediate reminder settings"
  end

  context "with the user administration page" do
    let(:reminders_settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { create(:user) }
    let(:pref) { other_user.pref }

    current_user do
      create(:admin)
    end

    it_behaves_like "immediate reminder settings"
  end

  describe "email sending" do
    let(:project) { create(:project) }
    let(:work_package) { create(:work_package, project:) }
    let(:receiver) do
      create(
        :user,
        preferences: {
          immediate_reminders: {
            mentioned: true
          }
        },
        notification_settings: [
          build(:notification_setting,
                mentioned: true)
        ],
        member_with_permissions: { project => %i[view_work_packages] }
      )
    end

    current_user do
      create(:user)
    end

    it "sends a mail to the mentioned user immediately" do
      perform_enqueued_jobs do
        note = <<~NOTE
          Hey <mention class="mention"
                       data-id="#{receiver.id}"
                       data-type="user"
                       data-text="@#{receiver.name}">
                @#{receiver.name}
              </mention>
        NOTE

        work_package.add_journal(user: current_user, notes: note)
        work_package.save!
      end

      expect(ActionMailer::Base.deliveries.length)
        .to be 1

      expect(ActionMailer::Base.deliveries.first.subject)
        .to eql I18n.t(:"mail.mention.subject",
                       user_name: current_user.name,
                       id: "##{work_package.id}",
                       subject: work_package.subject)
    end
  end
end

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

Rails.root.glob("{,modules/*/}app/mailers/**/*_mailer.rb") { require it }
Rails.root.glob("{,modules/*/}spec/mailers/**/*_mailer_preview.rb") { require it }

PENDING_PREVIEW_MAILERS = %w[
  AnnouncementMailer
  DocumentsMailer
  MemberMailer
].freeze

PENDING_PREVIEWS_MAILER_ACTIONS = {
  MeetingMailer => %i[
    ended_series
    icalendar_notification
  ],
  ProjectMailer => %i[
    copy_project_failed
    copy_project_succeeded
    delete_project_failed
    project_created
  ],
  UserMailer => %i[
    account_activated
    account_activation_requested
    account_information
    backup_ready
    backup_token_reset
    incoming_email_error
    message_posted
    news_added
    news_comment_added
    password_change_not_possible
    password_lost
    test_mail
    user_signed_up
    wiki_page_added
    wiki_page_updated
  ],
  WorkPackageMailer => %i[
    watcher_changed
  ]
}.freeze

PENDING_PREVIEW_ACTIONS = %w[
  DigestMailerPreview#work_packages
  MeetingMailerPreview#cancelled__occurrence
  MeetingMailerPreview#cancelled_series
  MeetingSeriesMailerPreview#invited__template_completed
  MeetingSeriesMailerPreview#updated
  Reminders::NotificationMailerPreview#reminder_notification
  SharingMailerPreview#shared_work_package
  SharingMailerPreview#shared_work_package__via_group
  SharingMailerPreview#shared_work_package__via_invitation
  WorkPackageMailerPreview#mentioned
].freeze

ApplicationMailer.descendants.each do |mailer|
  next unless mailer.name&.end_with?("Mailer")

  preview_class = "#{mailer.name}Preview".safe_constantize # rubocop:disable RSpec/LeakyLocalVariable

  RSpec.describe mailer do
    it "has a preview class" do
      pending if mailer.name.in?(PENDING_PREVIEW_MAILERS)

      expect(preview_class).to be < ActionMailer::Preview
    end

    if preview_class
      preview_actions = preview_class.public_instance_methods(false) # rubocop:disable RSpec/LeakyLocalVariable

      it "has a preview for every action" do
        mailer_actions = mailer.public_instance_methods(false)
        actions_with_preview = preview_actions.map { it.to_s.split("__", 2)[0].to_sym }.uniq
        pending_actions = PENDING_PREVIEWS_MAILER_ACTIONS[mailer]

        expect([*actions_with_preview, *pending_actions]).to match_array(mailer_actions)

        pending if pending_actions

        expect(actions_with_preview).to match_array(mailer_actions)
      end

      preview_actions.each do |preview_action|
        it "has a working preview #{preview_action}" do
          pending if "#{preview_class}##{preview_action}".in?(PENDING_PREVIEW_ACTIONS)

          expect { preview_class.call(preview_action) }.not_to raise_error
        end
      end
    end
  end
end

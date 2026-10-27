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

module PendingMailerPreviews
  MAILERS = [
    AnnouncementMailer,
    DocumentsMailer,
    MemberMailer
  ].freeze

  MAILER_ACTIONS = {
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
      message_mentioned
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

  PREVIEW_ACTIONS = {
    DigestMailerPreview => %i[
      work_packages
    ],
    MeetingMailerPreview => %i[
      cancelled_occurrence
      cancelled_series
    ],
    MeetingSeriesMailerPreview => %i[
      invited_template_completed
      updated
    ],
    Reminders::NotificationMailerPreview => %i[
      reminder_notification
    ],
    SharingMailerPreview => %i[
      shared_work_package
      shared_work_package_via_group
      shared_work_package_via_invitation
    ],
    WorkPackageMailerPreview => %i[
      mentioned
    ]
  }.freeze
end

ApplicationMailer.descendants.each do |mailer|
  next unless mailer.name&.end_with?("Mailer")

  preview_class = "#{mailer}Preview".safe_constantize # rubocop:disable RSpec/LeakyLocalVariable

  RSpec.describe mailer do
    it "has a preview class" do
      pending "create preview for #{mailer}" if mailer.in?(PendingMailerPreviews::MAILERS)

      expect(preview_class).to be < ActionMailer::Preview
    end

    if preview_class
      preview_actions = preview_class.public_instance_methods(false) # rubocop:disable RSpec/LeakyLocalVariable

      # guess expecting preview method name to start with mailer method name
      def guess_action(mailer, preview_action)
        mailer.public_instance_methods(false)
          .select { preview_action.start_with?(it.to_s) }
          .max_by(&:length)
      end

      it "has a preview for every action" do
        mailer_actions = mailer.public_instance_methods(false)
        actions_with_preview = preview_actions.map do |preview_action|
          # get the action from preview action result
          preview_class.call(preview_action).action
        rescue StandardError
          guess_action(mailer, preview_action)
        end.uniq
        pending_actions = Array(PendingMailerPreviews::MAILER_ACTIONS[mailer])

        missing = mailer_actions - actions_with_preview - pending_actions
        expect(missing).to be_empty, "#{mailer} has no preview for #{missing.join(', ')} in #{mailer}Preview"

        unknown = pending_actions - mailer_actions
        expect(unknown).to be_empty, "#{mailer} has no actions #{unknown.join(', ')}, fix it in #{mailer}Preview " \
                                     "or remove from PendingMailerPreviews::MAILER_ACTIONS"

        pending "add previews for #{pending_actions.join(', ')}" unless pending_actions.empty?

        expect(actions_with_preview).to match_array(mailer_actions)
      end

      preview_actions.each do |preview_action|
        describe "preview #{preview_action}" do
          before do
            if PendingMailerPreviews::PREVIEW_ACTIONS[preview_class]&.include?(preview_action)
              pending "fix #{preview_class}##{preview_action}"
            end
          end

          it "does not raise an error" do
            expect { preview_class.call(preview_action) }.not_to raise_error
          end

          it "is named after its action" do
            expect(guess_action(mailer, preview_action)).to eq(preview_class.call(preview_action).action)
          end
        end
      end
    end
  end
end

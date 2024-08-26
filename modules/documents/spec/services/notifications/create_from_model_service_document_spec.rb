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
require Rails.root.join("spec/services/notifications/create_from_journal_job_shared")

RSpec.describe Notifications::CreateFromModelService, "document", with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:call) do
    described_class.new(journal).call(send_notifications)
  end

  include_context "with CreateFromJournalJob context"

  shared_let(:project) { create(:project) }

  let(:permissions) { [:view_documents] }
  let(:send_notifications) { true }

  let(:resource) do
    create(:document,
           project:)
  end
  let(:journal) { resource.journals.last }
  let(:author) { other_user }

  current_user { other_user }

  before do
    recipient
  end

  describe "#perform" do
    context "with a newly created document" do
      context "with the user having registered for all notifications" do
        it_behaves_like "creates notification" do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: :subscribed,
              mail_alert_sent: false,
              mail_reminder_sent: nil
            }
          end
        end
      end

      context "with the user having registered for assignee notifications" do
        let(:recipient_notification_settings) do
          [
            build(:notification_setting, **notification_settings_all_false.merge(assignee: true))
          ]
        end

        it_behaves_like "creates no notification"
      end

      context "with the user having registered for responsible notifications" do
        let(:recipient_notification_settings) do
          [
            build(:notification_setting, **notification_settings_all_false.merge(responsible: true))
          ]
        end

        it_behaves_like "creates no notification"
      end

      context "with the user having registered for no notifications" do
        let(:recipient_notification_settings) do
          [
            build(:notification_setting, **notification_settings_all_false)
          ]
        end

        it_behaves_like "creates no notification"
      end

      context "with the user having registered for all notifications but lacking permissions" do
        before do
          recipient.members.destroy_all
        end

        it_behaves_like "creates no notification"
      end
    end

    context "with an updated document" do
      before do
        resource.title = "A new subject"
        resource.save!
      end

      context "with the user having registered for all notifications" do
        it_behaves_like "creates notification" do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: :subscribed,
              mail_alert_sent: false,
              mail_reminder_sent: nil
            }
          end
        end
      end

      context "with the user having registered for assignee notifications" do
        let(:recipient_notification_settings) do
          [
            build(:notification_setting, **notification_settings_all_false.merge(assignee: true))
          ]
        end

        it_behaves_like "creates no notification"
      end

      context "with the user having registered for responsible notifications" do
        let(:recipient_notification_settings) do
          [
            build(:notification_setting, **notification_settings_all_false.merge(responsible: true))
          ]
        end

        it_behaves_like "creates no notification"
      end

      context "with the user having registered for no notifications" do
        let(:recipient_notification_settings) do
          [
            build(:notification_setting, **notification_settings_all_false)
          ]
        end

        it_behaves_like "creates no notification"
      end

      context "with the user having registered for all notifications but lacking permissions" do
        before do
          recipient.members.destroy_all
        end

        it_behaves_like "creates no notification"
      end
    end
  end
end

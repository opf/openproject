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

RSpec.describe OpenProject::Webhooks::EventResources::WorkPackageComment do
  subject(:notification_sent) do
    OpenProject::Notifications.send(OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY, journal:, send_mail: false)
  end

  let(:journal) { create(:work_package_journal, notes:, internal:) }
  let(:notes) { "I am a nice comment" }
  let(:internal) { false }

  let!(:comment_webhook) { create(:webhook, event_names: ["work_package_comment:comment"]) }
  let!(:internal_comment_webhook) { create(:webhook, event_names: ["work_package_comment:internal_comment"]) }

  context "when the journal is non-internal" do
    it "invokes comment web hooks" do
      notification_sent

      expect(WorkPackageCommentWebhookJob).to have_been_enqueued.with(
        comment_webhook.id,
        journal,
        "work_package_comment:comment"
      )
    end

    it "does not invoke internal_comment web hooks" do
      notification_sent

      expect(WorkPackageCommentWebhookJob).not_to have_been_enqueued.with(
        internal_comment_webhook.id,
        anything,
        anything
      )
    end
  end

  context "when the journal is internal" do
    let(:internal) { true }

    it "invokes internal_comment web hooks" do
      notification_sent

      expect(WorkPackageCommentWebhookJob).to have_been_enqueued.with(
        internal_comment_webhook.id,
        journal,
        "work_package_comment:internal_comment"
      )
    end

    it "does not invoke comment web hooks" do
      notification_sent

      expect(WorkPackageCommentWebhookJob).not_to have_been_enqueued.with(
        comment_webhook.id,
        anything,
        anything
      )
    end
  end

  context "when the journal has no comment" do
    let(:notes) { "" }

    it "does not invoke comment web hooks" do
      notification_sent

      expect(WorkPackageCommentWebhookJob).not_to have_been_enqueued.with(
        comment_webhook.id,
        anything,
        anything
      )
    end

    it "does not invoke internal_comment web hooks" do
      notification_sent

      expect(WorkPackageCommentWebhookJob).not_to have_been_enqueued.with(
        internal_comment_webhook.id,
        anything,
        anything
      )
    end
  end
end

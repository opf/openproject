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

RSpec.describe Notifications::CreateFromApiService do
  shared_let(:project) { create(:project, enabled_module_names: %w[documents]) }
  shared_let(:document) { create(:document, project:) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_documents manage_documents] })
  end
  shared_let(:recipient) do
    create(:user, member_with_permissions: { project => %i[view_documents] })
  end

  let(:instance) { described_class.new(user:) }
  let(:reason) { "mentioned" }
  let(:resource_type) { "Document" }
  let(:recipient_id) { recipient.id }

  subject(:service_call) do
    instance.call(reason:, resource_type:, resource_id: document.id, recipient_id:)
  end

  it "creates a mention notification without journal, only to be sent out by mail" do
    expect(service_call).to be_success
    expect(service_call.result)
      .to be_persisted
      .and have_attributes(recipient:,
                           resource: document,
                           actor: user,
                           reason: "mentioned",
                           journal: nil,
                           read_ian: nil,
                           mail_reminder_sent: nil)
  end

  it "sends the mention mail immediately and marks the notification accordingly" do
    expect { service_call }
      .to have_enqueued_mail(DocumentsMailer, :mentioned)
            .with(recipient, instance_of(Notification))

    expect(service_call.result.reload.mail_alert_sent).to be(true)
  end

  context "when the recipient disabled immediate mails for mentions" do
    let(:recipient_without_mention_mails) do
      create(:user,
             member_with_permissions: { project => %i[view_documents] },
             preferences: { immediate_reminders: { mentioned: false } })
    end
    let(:recipient_id) { recipient_without_mention_mails.id }

    it "creates the notification without sending a mail" do
      expect { service_call }.not_to have_enqueued_mail

      expect(service_call.result)
        .to be_persisted
        .and have_attributes(recipient: recipient_without_mention_mails, read_ian: nil)
      expect(service_call.result.reload.mail_alert_sent).to be_nil
    end
  end

  context "when the recipient is the user" do
    let(:recipient_id) { user.id }

    it "succeeds without creating a notification" do
      expect { service_call }.not_to change(Notification, :count)
      expect(service_call).to be_success
      expect(service_call.result).to be_nil
    end
  end

  context "when the recipient disabled mention notifications for the project" do
    before do
      create(:notification_setting, user: recipient, project:, mentioned: false)
    end

    it "succeeds without creating a notification" do
      expect { service_call }.not_to change(Notification, :count)
      expect(service_call).to be_success
      expect(service_call.result).to be_nil
    end
  end

  context "when the contract is invalid" do
    let(:reason) { "assigned" }

    it "fails without creating a notification" do
      expect { service_call }.not_to change(Notification, :count)
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:reason)).to eq([:inclusion])
    end
  end

  context "with a resource type that is no class" do
    let(:resource_type) { "Foo::Bar" }

    it "fails without loading the resource" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:resource)).to eq([:mentions_not_supported])
    end
  end
end

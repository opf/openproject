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

RSpec.describe Notifications::WorkflowJob, type: :model do
  subject(:perform_job) do
    described_class.new.perform(state, *arguments)
  end

  let(:send_notification) { true }

  let(:notifications) do
    [build_stubbed(:notification, reason: :assigned),
     mentioned_notification,
     build_stubbed(:notification, reason: :watched)]
  end

  let(:mentioned_notification) do
    build_stubbed(:notification, reason: :mentioned)
  end

  describe "#perform" do
    context "with the :create_notifications state" do
      let(:state) { :create_notifications }
      let(:arguments) { [resource, send_notification] }
      let(:resource) { build_stubbed(:comment) }

      let!(:create_service) do
        service_instance = instance_double(Notifications::CreateFromModelService)
        service_result = instance_double(ServiceResult)

        allow(Notifications::CreateFromModelService)
          .to receive(:new)
                .with(resource)
                .and_return(service_instance)

        allow(service_instance)
          .to receive(:call)
                .with(send_notification)
                .and_return(service_result)

        allow(service_result)
          .to receive(:all_results)
                .and_return(notifications)

        service_instance
      end

      let!(:mail_service) do
        service_instance = instance_double(Notifications::MailService,
                                           call: nil)

        allow(Notifications::MailService)
          .to receive(:new)
                .with(mentioned_notification)
                .and_return(service_instance)

        service_instance
      end

      it "calls the service to create notifications" do
        perform_job

        expect(create_service)
          .to have_received(:call)
                .with(send_notification)
      end

      it "sends mails for all notifications that are marked to send mails and that have a mention reason" do
        perform_job

        expect(mail_service)
          .to have_received(:call)
      end

      it "schedules a delayed WorkflowJob for those notifications not to be sent directly" do
        allow(Time)
          .to receive(:current)
                .and_return(Time.current)

        expected_time = Time.current +
                        Setting.journal_aggregation_time_minutes.to_i.minutes

        expect { perform_job }
          .to enqueue_job(described_class)
                .with(:send_mails, *(notifications - [mentioned_notification]).map(&:id))
                .at(expected_time)
      end
    end

    context "with the :send_mails state" do
      let(:state) { :send_mails }
      let(:arguments) { notifications.map(&:id) }

      let!(:mail_service) do
        service_instance = instance_double(Notifications::MailService,
                                           call: nil)

        allow(Notifications::MailService)
          .to receive(:new)
                .with(notifications.first)
                .and_return(service_instance)

        service_instance
      end

      before do
        scope = class_double(Notification, mail_alert_unsent: [notifications.first])

        allow(Notification)
          .to receive(:where)
                .with(id: notifications.map(&:id))
                .and_return(scope)
      end

      it "sends mails for all notifications that are marked to send mails" do
        perform_job

        expect(mail_service)
          .to have_received(:call)
      end
    end
  end
end

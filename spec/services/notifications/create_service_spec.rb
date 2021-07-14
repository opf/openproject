#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'services/base_services/behaves_like_create_service'

describe Notifications::CreateService, type: :model do
  let(:mail_digest_before) { false }

  before do
    scope = double('scope')

    allow(Notification)
      .to receive(:mail_digest_before)
            .with(recipient: model_instance.recipient, time: model_instance.created_at)
            .and_return(scope)

    allow(scope)
      .to receive(:where)
            .and_return(scope)

    allow(scope)
      .to receive(:not)
            .and_return(scope)

    allow(scope)
      .to receive(:exists?)
            .and_return(mail_digest_before)
  end

  it_behaves_like 'BaseServices create service' do
    let(:call_attributes) do
      {}
    end

    context 'when successful' do
      before do
        allow(set_attributes_service)
          .to receive(:call) do |attributes|
          model_instance.attributes = attributes

          set_attributes_result
        end
      end

      context 'when mail ought to be send', { with_settings: { notification_email_delay_minutes: 30 } } do
        let(:call_attributes) do
          {
            read_mail: false
          }
        end

        it 'schedules a delayed notification job' do
          allow(Time)
            .to receive(:now)
                  .and_return(Time.now)

          expect { subject }
            .to have_enqueued_job(Mails::NotificationJob)
                 .with({ "_aj_globalid" => "gid://open-project/Notification/#{model_instance.id}" })
                 .at(Time.now + Setting.notification_email_delay_minutes.minutes)
        end
      end

      context 'when mail not ought to be send' do
        let(:call_attributes) do
          {
            read_mail: nil
          }
        end

        it 'schedules no notification job' do
          expect { subject }
            .not_to have_enqueued_job(Mails::NotificationJob)
        end
      end

      context 'when digests ought to be send' do
        let(:call_attributes) do
          {
            read_mail_digest: false
          }
        end

        before do
          allow(model_instance.recipient)
            .to receive(:time_zone)
                  .and_return(ActiveSupport::TimeZone['Tijuana'])
        end

        it 'schedules a digest mail job' do
          expected_time = ActiveSupport::TimeZone['Tijuana'].parse(Setting.notification_email_digest_time) + 1.day

          expect { subject }
            .to have_enqueued_job(Mails::DigestJob)
                  .with({ "_aj_globalid" => "gid://open-project/User/#{model_instance.recipient.id}" })
                  .at(expected_time)
        end
      end

      context 'when digests ought to be send and there is already a digest job scheduled' do
        let(:mail_digest_before) { true }

        let(:call_attributes) do
          {
            read_mail_digest: false
          }
        end

        it 'schedules no digest mail job' do
          expect { subject }
            .not_to have_enqueued_job(Mails::DigestJob)
        end
      end

      context 'when digests not ought to be send' do
        let(:call_attributes) do
          {
            read_mail_digest: nil
          }
        end

        it 'schedules no digest mail job' do
          expect { subject }
            .not_to have_enqueued_job(Mails::DigestJob)
        end
      end
    end

    context 'when unsuccessful' do
      let(:model_save_result) { false }

      it 'schedules no job' do
        expect { subject }
          .not_to have_enqueued_job(Mails::NotificationJob)
      end
    end
  end
end

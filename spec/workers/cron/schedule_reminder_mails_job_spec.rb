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

describe Cron::ScheduleReminderMailsJob, type: :job do
  # As it is hard to mock Postgres's "now()" method, in the specs here we need to adopt the slot time
  # relative to the local time of the user that we want to hit.
  let(:current_utc_time) { Time.current.getutc }
  let(:slot_time) { hitting_reminder_slot_for(hitting_user, current_utc_time) } # ie. "08:00", "08:30"

  let(:hitting_user) { paris_user }
  let(:paris_user) { FactoryBot.create(:user, preferences: { time_zone: "Paris" }) } # time_zone in winter is +01:00
  let(:no_zone_user) { FactoryBot.create(:user) } # time_zone is nil
  let(:notifications) { FactoryBot.create(:notification, recipient: hitting_user) }

  subject(:perform_job) do
    described_class.new.perform
  end

  before do
    allow(Setting).to receive(:notification_email_digest_time).and_return(slot_time)
    notifications
  end

  context 'with paris_user as hitting_user' do
    let(:moscow_user) { FactoryBot.create(:user, preferences: { time_zone: "Moscow" }) } # time_zone all year is +03:00
    let(:greenland_user) { FactoryBot.create(:user, preferences: { time_zone: "Greenland" }) } # time_zone in winter is -03:00
    let(:notifications) do
      FactoryBot.create(:notification, recipient: hitting_user, created_at: 5.minutes.ago)
      FactoryBot.create(:notification, recipient: moscow_user, created_at: 5.minutes.ago)
      FactoryBot.create(:notification, recipient: greenland_user, created_at: 5.minutes.ago)
      FactoryBot.create(:notification, recipient: no_zone_user, created_at: 5.minutes.ago)
    end

    before do
      allow(Time).to receive(:current).and_return(current_utc_time)
    end

    it 'schedules ReminderMailJobs for all users that subscribed for that slot in their local time' do
      # `hitting_user` is `paris_user`.
      # `slot_time` (expressed string in local time) is set to be at the beginning of the first or second half hour
      # block of the started hour.
      expect { perform_job }
          .to enqueue_job(Mails::ReminderJob)
                .with(hitting_user.id)

      # `moscow_user` is in a different time zone (higher offset than Paris) so should not hit for the same `slot_time`
      expect { perform_job }
          .not_to enqueue_job(Mails::ReminderJob)
                    .with(moscow_user.id)

      # `greenland_user` is in a different time (lower offset than Paris) so should not hit for the same `slot_time`
      expect { perform_job }
          .not_to enqueue_job(Mails::ReminderJob)
                    .with(greenland_user.id)

      # `no_zone_user` should fall back to UTC time zone and thus have lower offset as `paris_user` and not hit
      expect { perform_job }
          .not_to enqueue_job(Mails::ReminderJob)
                    .with(no_zone_user.id)
    end
  end

  context 'when slot_time in UTC' do
    let(:hitting_user) { no_zone_user }
    let(:notifications) do
      FactoryBot.create(:notification, recipient: hitting_user, created_at: 5.minutes.ago)
    end

    it 'schedules a job for users without timezone set' do
      expect { perform_job }
          .to enqueue_job(Mails::ReminderJob)
                .with(hitting_user.id)
    end
  end

  context 'when hitting user is not active' do
    let(:hitting_user) do
      paris_user.locked!
      paris_user
    end
    let(:notifications) do
      FactoryBot.create(:notification, recipient: hitting_user)
    end

    it 'does not schedule for users that are not active' do
      expect { perform_job }
          .not_to enqueue_job(Mails::ReminderJob)
                    .with(hitting_user.id)
    end
  end

  context 'with a user without notifications' do
    # Create another user just as `hitting_user` but without notifications
    let(:paris_user_without_notifications) { FactoryBot.create(:user, preferences: { time_zone: "Paris" }) }

    it 'does not schedule reminder mail job' do
      expect { perform_job }
          .not_to enqueue_job(Mails::ReminderJob)
                    .with(paris_user_without_notifications.id)
    end
  end

  context 'with a user with read IAN notifications' do
    # Create another user just as `hitting_user` but without notifications
    let(:paris_user_with_read_ian_notifications) do
      FactoryBot.create(:user, preferences: { time_zone: "Paris" })
    end
    let(:notifications) do
      FactoryBot.create(:notification,
                        recipient: paris_user_with_read_ian_notifications,
                        read_ian: true)
    end

    it 'does not schedule reminder mail job' do
      expect { perform_job }
        .not_to enqueue_job(Mails::ReminderJob)
                  .with(paris_user_with_read_ian_notifications.id)
    end
  end

  context 'with a user with who already received a reminder for a notification' do
    # Create another user just as `hitting_user` but without notifications
    let(:paris_user_with_read_mail_digest_notifications) do
      FactoryBot.create(:user, preferences: { time_zone: "Paris" })
    end
    let(:notifications) do
      FactoryBot.create(:notification,
                        recipient: paris_user_with_read_mail_digest_notifications,
                        read_mail_digest: true)
    end

    it 'does not schedule reminder mail job' do
      expect { perform_job }
        .not_to enqueue_job(Mails::ReminderJob)
                  .with(paris_user_with_read_mail_digest_notifications.id)
    end
  end
end

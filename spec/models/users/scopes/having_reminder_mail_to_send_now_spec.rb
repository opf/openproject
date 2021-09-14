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

describe User, '.with_reminder_mail_to_send_now', type: :job do
  subject(:scope) do
    described_class.having_reminder_mail_to_send_now
  end

  # As it is hard to mock Postgres's "now()" method, in the specs here we need to adopt the slot time
  # relative to the local time of the user that we want to hit.
  let(:current_utc_time) { Time.current.getutc }
  let(:slot_time) { hitting_reminder_slot_for(hitting_user, current_utc_time) } # ie. "08:00", "08:30"

  let(:hitting_user) { paris_user }
  let(:paris_user) { FactoryBot.create(:user, preferences: { time_zone: "Paris" }) } # time_zone in winter is +01:00
  let(:moscow_user) { FactoryBot.create(:user, preferences: { time_zone: "Moscow" }) } # time_zone all year is +03:00
  let(:greenland_user) { FactoryBot.create(:user, preferences: { time_zone: "Greenland" }) } # time_zone in winter is -03:00
  let(:no_zone_user) { FactoryBot.create(:user) } # time_zone is nil
  let(:notifications) { FactoryBot.create(:notification, recipient: hitting_user) }

  before do
    allow(Setting).to receive(:notification_email_digest_time).and_return(slot_time)
    allow(Time).to receive(:current).and_return(current_utc_time)
    notifications
  end

  context 'for a user whose local time is matching the configured time' do
    let(:notifications) do
      FactoryBot.create(:notification, recipient: paris_user, created_at: 5.minutes.ago)
    end

    it 'contains the user' do
      expect(scope)
        .to match_array([paris_user])
    end
  end

  context 'for a user whose local time is matching the configured time (in a non CET time zone)' do
    let(:slot_time) { hitting_reminder_slot_for(moscow_user, current_utc_time) }
    let(:notifications) do
      FactoryBot.create(:notification, recipient: moscow_user, created_at: 5.minutes.ago)
    end

    it 'contains the user' do
      expect(scope)
        .to match_array([moscow_user])
    end
  end

  context 'for a user whose local time is matching the configured time but without a notification' do
    let(:notifications) do
      # There is a notification for a different user
      FactoryBot.create(:notification, recipient: moscow_user, created_at: 5.minutes.ago)
    end

    it 'is empty' do
      expect(scope)
        .to be_empty
    end
  end

  context 'for a user whose local time is matching the configured time but with an already read notification (IAN)' do
    let(:notifications) do
      FactoryBot.create(:notification, recipient: paris_user, created_at: 5.minutes.ago, read_ian: true)
    end

    it 'is empty' do
      expect(scope)
        .to be_empty
    end
  end

  context 'for a user whose local time is matching the configured time but with an already read notification (reminder)' do
    let(:notifications) do
      FactoryBot.create(:notification, recipient: paris_user, created_at: 5.minutes.ago, read_mail_digest: true)
    end

    it 'is empty' do
      expect(scope)
        .to be_empty
    end
  end

  context 'for a user whose local time is matching the configured time but with the user being inactive' do
    let(:notifications) do
      FactoryBot.create(:notification, recipient: paris_user, created_at: 5.minutes.ago)
    end

    before do
      paris_user.locked!
    end

    it 'is empty' do
      expect(scope)
        .to be_empty
    end
  end

  context 'for a user whose local time is before the configured time' do
    let(:notifications) do
      FactoryBot.create(:notification, recipient: moscow_user, created_at: 5.minutes.ago)
    end

    it 'contains the user' do
      expect(scope)
        .to be_empty
    end
  end

  context 'for a user whose local time is after the configured time' do
    let(:notifications) do
      FactoryBot.create(:notification, recipient: greenland_user, created_at: 5.minutes.ago)
    end

    it 'contains the user' do
      expect(scope)
        .to be_empty
    end
  end

  context 'for a user without a time zone' do
    let(:slot_time) { hitting_reminder_slot_for(no_zone_user, current_utc_time) }
    let(:notifications) do
      FactoryBot.create(:notification, recipient: no_zone_user, created_at: 5.minutes.ago)
    end

    it 'is including the user as UTC is assumed' do
      expect(scope)
        .to match_array([no_zone_user])
    end
  end
end

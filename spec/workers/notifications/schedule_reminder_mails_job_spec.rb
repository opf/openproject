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

describe Notifications::ScheduleReminderMailsJob, type: :job do
  subject(:job) { described_class.perform_now }

  let(:ids) { [23, 42] }

  before do
    scope = instance_double(ActiveRecord::Relation)
    allow(User)
      .to receive(:having_reminder_mail_to_send_now)
            .and_return(scope)

    allow(scope)
      .to receive(:pluck)
            .with(:id)
            .and_return(ids)
  end

  describe '#perform' do
    it 'schedules reminder jobs for every user with a reminder mails to be sent' do
      expect { subject }
        .to change(enqueued_jobs, :count)
              .by(2)

      expect(Mails::ReminderJob)
        .to have_been_enqueued
              .exactly(:once)
              .with(23)

      expect(Mails::ReminderJob)
        .to have_been_enqueued
              .exactly(:once)
              .with(42)
    end
  end
end

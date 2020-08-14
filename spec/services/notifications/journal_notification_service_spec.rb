#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Notifications::JournalNotificationService do
  let(:journable) { FactoryBot.build_stubbed(:stubbed_work_package) }
  let(:journal) { FactoryBot.build_stubbed(:journal, journable: journable) }
  let(:send_mails) { true }

  shared_examples_for 'enqueues a notification' do
    before do
      # Freeze time
      allow(Time)
        .to receive(:current)
        .and_return(Time.current)

      notification_set = double('notification set')

      expect(EnqueueWorkPackageNotificationJob)
        .to receive(:set)
        .with(wait_until: Setting.journal_aggregation_time_minutes.to_i.minutes.from_now)
        .and_return(notification_set)

      expect(notification_set)
        .to receive(:perform_later)
        .with(journal.id, send_mails)
    end

    it 'fulfills expectations' do
      described_class.call(journal, send_mails)
    end
  end

  shared_examples_for 'enqueues no notification' do
    before do
      expect(EnqueueWorkPackageNotificationJob)
        .not_to receive(:set)
    end

    it 'fulfills expectations' do
      described_class.call(journal, send_mails)
    end
  end

  context 'for a work package journal' do
    it_behaves_like 'enqueues a notification'
  end

  context 'for a news journal' do
    let(:journable) { FactoryBot.build_stubbed(:news) }
    it_behaves_like 'enqueues no notification'
  end
end

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

describe Journals::ScheduleCompletedService do
  let(:journal) { FactoryBot.build_stubbed(:journal, journable: journable) }
  let(:send_mails) { true }

  describe '#call' do
    shared_examples_for 'enqueues a JournalCompletedJob' do
      before do
        # Freeze time
        allow(Time)
          .to receive(:current)
                .and_return(Time.current)

        notification_set = double('notification set')

        allow(Notifications::JournalCompletedJob)
          .to receive(:set)
                .with(wait_until: Setting.journal_aggregation_time_minutes.to_i.minutes.from_now)
                .and_return(notification_set)

        allow(notification_set)
          .to receive(:perform_later)
                .with(journal.id, send_mails)
      end

      it 'enqueues a JournalCompletedJob' do
        described_class.call(journal, send_mails)

        expect(Notifications::JournalCompletedJob)
          .to have_received(:set)
      end
    end

    shared_examples_for 'enqueues no job' do
      before do
        allow(Notifications::JournalCompletedJob)
          .to receive(:set)
      end

      it 'enqueues no JournalCompletedJob' do
        described_class.call(journal, send_mails)

        expect(Notifications::JournalCompletedJob)
          .not_to have_received(:set)
      end
    end

    context 'with a work_package' do
      let(:journable) { FactoryBot.build_stubbed(:stubbed_work_package) }

      it_behaves_like 'enqueues a JournalCompletedJob'
    end

    context 'with a wiki page' do
      let(:journable) { FactoryBot.build_stubbed(:wiki_content) }

      it_behaves_like 'enqueues a JournalCompletedJob'
    end

    context 'with a news' do
      let(:journable) { FactoryBot.build_stubbed(:news) }

      it_behaves_like 'enqueues no job'
    end
  end
end

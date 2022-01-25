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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe Journals::CompletedJob, type: :model do
  let(:send_mail) { true }

  let(:journal) do
    build_stubbed(:journal, journable: journable).tap do |j|
      allow(Journal)
        .to receive(:find)
              .with(j.id.to_s)
              .and_return(j)
      allow(Journal)
        .to receive(:find_by)
              .with(id: j.id)
              .and_return(j)
      allow(Journal)
        .to receive(:exists?)
              .with(id: j.id)
              .and_return(true)
    end
  end

  describe '.schedule' do
    subject { described_class.schedule(journal, send_mail) }

    shared_examples_for 'enqueues a JournalCompletedJob' do
      before do
        allow(Time)
          .to receive(:current)
                .and_return(Time.current)
      end

      it 'enqueues a JournalCompletedJob' do
        expect { subject }
          .to have_enqueued_job(described_class)
                .at(Setting.journal_aggregation_time_minutes.to_i.minutes.from_now)
                .with(journal.id,
                      send_mail)
      end
    end

    shared_examples_for 'enqueues no job' do
      it 'enqueues no JournalCompletedJob' do
        expect { subject }
          .not_to have_enqueued_job(described_class)
      end
    end

    context 'with a work_package' do
      let(:journable) { build_stubbed(:work_package) }

      it_behaves_like 'enqueues a JournalCompletedJob'
    end

    context 'with a wiki page' do
      let(:journable) { build_stubbed(:wiki_content) }

      it_behaves_like 'enqueues a JournalCompletedJob'
    end

    context 'with a news' do
      let(:journable) { build_stubbed(:news) }

      it_behaves_like 'enqueues a JournalCompletedJob'
    end
  end

  describe '#perform' do
    subject { described_class.new.perform(journal.id, send_mail) }

    shared_examples_for 'sends a notification' do |event|
      it 'sends a notification' do
        allow(OpenProject::Notifications)
          .to receive(:send)

        subject

        expect(OpenProject::Notifications)
          .to have_received(:send)
                .with(event,
                      journal: journal,
                      send_mail: send_mail)
      end
    end

    context 'with a work packages' do
      let(:journable) { build_stubbed(:work_package) }

      it_behaves_like 'sends a notification',
                      OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY
    end

    context 'with wiki page content' do
      let(:journable) { build_stubbed(:wiki_content) }

      it_behaves_like 'sends a notification',
                      OpenProject::Events::AGGREGATED_WIKI_JOURNAL_READY
    end

    context 'with a news' do
      let(:journable) { build_stubbed(:news) }

      it_behaves_like 'sends a notification',
                      OpenProject::Events::AGGREGATED_NEWS_JOURNAL_READY
    end

    context 'with a non non-existant journal' do
      let(:journable) { build_stubbed(:work_package) }

      before do
        allow(Journal)
          .to receive(:find_by)
                .with(id: journal.id)
                .and_return(nil)
      end

      it 'sends no notification' do
        allow(OpenProject::Notifications)
          .to receive(:send)

        subject

        expect(OpenProject::Notifications)
          .not_to have_received(:send)
      end
    end
  end
end

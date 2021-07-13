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

describe Mails::NotificationJob, type: :model do
  subject(:job) { instance.perform(notification) }

  let(:recipient) do
    FactoryBot.build_stubbed(:user)
  end
  let(:actor) do
    FactoryBot.build_stubbed(:user)
  end
  let(:instance) { described_class.new }

  context 'with a work package journal notification' do
    let(:journal) { FactoryBot.build_stubbed(:work_package_journal) }
    let(:read_ian) { false }
    let(:notification) do
      FactoryBot.build_stubbed(:notification,
                               journal: journal,
                               recipient: recipient,
                               actor: actor,
                               read_ian: read_ian)
    end

    before do
      allow(Mails::WorkPackageJob)
        .to receive(:perform_now)
    end

    context 'with the notification not read in app already' do
      it 'sends a mail' do
        job

        expect(Mails::WorkPackageJob)
          .to have_received(:perform_now)
                .with(notification.journal, notification.recipient_id, notification.actor_id)
      end
    end

    context 'with the notification read in app already' do
      let(:read_ian) { true }

      it 'sends no mail' do
        job

        expect(Mails::WorkPackageJob)
          .not_to have_received(:perform_now)
      end
    end
  end

  context 'with a different journal notification' do
    let(:journal) { FactoryBot.build_stubbed(:message_journal) }
    let(:notification) do
      FactoryBot.build_stubbed(:notification,
                               journal: journal,
                               recipient: recipient,
                               actor: actor)
    end

    it 'raises an error' do
      expect { job }
        .to raise_error(ArgumentError)
    end
  end
end

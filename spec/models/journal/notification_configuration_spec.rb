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

describe Journal::NotificationConfiguration, type: :model do
  describe '.with' do
    let!(:send_notification_before) { described_class.active? }
    let!(:proc_called_counter) { OpenStruct.new called: false, send_notifications: send_notification_before }
    let(:proc) do
      Proc.new do
        proc_called_counter.called = true
        proc_called_counter.send_notifications = described_class.active?
      end
    end

    it 'executes the block' do
      described_class.with !send_notification_before, &proc

      expect(proc_called_counter.called)
        .to be_truthy
    end

    it 'uses the provided send_notifications value within the proc' do
      described_class.with !send_notification_before, &proc

      expect(proc_called_counter.send_notifications)
        .to eql !send_notification_before
    end

    it 'resets the send_notifications to the value before' do
      described_class.with !send_notification_before, &proc

      expect(described_class.active?)
        .to eql send_notification_before
    end

    it 'lets the first block dominate further block calls' do
      described_class.with !send_notification_before do
        described_class.with send_notification_before, &proc
      end

      expect(proc_called_counter.send_notifications)
        .to eql !send_notification_before
    end

    it 'is thread safe' do
      thread = Thread.new do
        described_class.with true do
          inner = Thread.new do
            described_class.with false do
              Journal::NotificationConfiguration.active?
            end
          end

          [Journal::NotificationConfiguration.active?, inner.value]
        end
      end

      expect(thread.value)
        .to eql [true, false]
    end

    context 'with an exception being raised within the block' do
      it 'raises the exception but always resets the notification value' do
        expect { described_class.with(!send_notification_before) { raise ArgumentError } }
          .to raise_error ArgumentError

        expect(described_class.active?)
          .to eql send_notification_before
      end
    end
  end
end

# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
require_module_spec_helper

RSpec.describe Storages::ManageNextcloudIntegrationEventsJob, type: :job do
  describe '.priority' do
    it 'has a maximum priority' do
      expect(described_class.priority).to eq(7)
    end
  end

  describe '.debounce' do
    context 'when has been debounced by other thread' do
      before do
        Rails.cache.write(described_class::KEY, Time.current)
      end

      it 'does nothing' do
        expect { described_class.debounce }.not_to change(enqueued_jobs, :count)
      end
    end

    context 'when has not been debounced by other thread' do
      it 'schedules a job' do
        expect { described_class.debounce }.to change(enqueued_jobs, :count).from(0).to(1)
      end

      it 'hits cache once when called 1000 times in a short period of time' do
        allow(Rails.cache).to receive(:fetch).and_call_original

        expect do
          1000.times { described_class.debounce }
        end.to change(enqueued_jobs, :count).from(0).to(1)

        expect(Rails.cache).to have_received(:fetch).once
      end
    end
  end

  describe '#perform' do
    it 'responds with true when parent perform responds with true' do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock).and_return(true)
      allow(described_class).to receive(:debounce)

      expect(described_class.new.perform).to be(true)

      expect(described_class).not_to have_received(:debounce)
    end

    it 'debounces itself when parent perform responds with false' do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock).and_return(false)
      allow(described_class).to receive(:debounce)

      expect(described_class.new.perform).to be(false)

      expect(described_class).to have_received(:debounce).once
    end
  end
end

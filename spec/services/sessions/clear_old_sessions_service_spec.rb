# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe Sessions::ClearOldSessionsService do
  describe ".call!" do
    let!(:newly_dormant) { create(:push_subscription, session: nil, updated_at: 90.days.ago) }
    let!(:long_dormant) { create(:push_subscription, session: nil, suspended_at: 31.days.ago) }
    let!(:recent_dormant) { create(:push_subscription, session: nil, suspended_at: 1.day.ago) }
    let!(:active) { create(:push_subscription, updated_at: 90.days.ago) }

    it "forgets dormant push subscriptions suspended longer than the retention window only" do
      described_class.call!

      expect(PushSubscription.all).to contain_exactly(newly_dormant, recent_dormant, active)
    end

    it "starts the retention clock for a subscription that just became dormant" do
      freeze_time do
        described_class.call!

        expect(newly_dormant.reload.suspended_at).to eq(Time.current)
        expect(active.reload.suspended_at).to be_nil
      end
    end
  end
end

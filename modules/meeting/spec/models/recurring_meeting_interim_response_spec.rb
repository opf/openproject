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

RSpec.describe RecurringMeetingInterimResponse do
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:recurring_meeting) { create(:recurring_meeting, project:) }
  let(:user) { create(:user) }

  describe "validations" do
    describe "#start_time_must_be_valid_occurrence" do
      context "when start_time matches an occurrence of the recurring meeting" do
        let(:start_time) { recurring_meeting.start_time + 7.days }

        it "is valid" do
          response = described_class.new(recurring_meeting:, user:, start_time:,
                                         participation_status: :accepted)
          expect(response).to be_valid
        end
      end

      context "when start_time does not match any occurrence" do
        let(:start_time) { recurring_meeting.start_time + 1.hour }

        it "is invalid" do
          response = described_class.new(recurring_meeting:, user:, start_time:,
                                         participation_status: :accepted)
          expect(response).not_to be_valid
          expect(response.errors[:start_time])
            .to include("is not a valid occurrence time for this recurring meeting")
        end
      end
    end
  end
end

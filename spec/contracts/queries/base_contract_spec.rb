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
require_relative "shared_contract_examples"

RSpec.describe Queries::BaseContract do
  include_context "with queries contract"

  describe "timestamps" do
    let(:query) { build_stubbed(:query, timestamps:) }

    context "with EE", with_ee: %i[baseline_comparison] do
      Timestamp::ALLOWED_DATE_KEYWORDS.each do |timestamp_date_keyword|
        context "when the '#{timestamp_date_keyword}' value is provided" do
          let(:timestamps) { ["#{timestamp_date_keyword}@12:00+00:00"] }

          it_behaves_like "contract is valid"
        end
      end

      context "when the shortcut value 'now' is provided" do
        let(:timestamps) { ["now"] }

        it_behaves_like "contract is valid"
      end

      context "when a duration value is provided" do
        let(:timestamps) { ["P-2D"] }

        it_behaves_like "contract is valid"
      end

      context "when an iso8601 datetime value is provided" do
        let(:timestamps) { [1.week.ago.iso8601] }

        it_behaves_like "contract is valid"
      end
    end

    context "without EE", with_ee: false do
      context "when the 'oneDayAgo' value is provided" do
        let(:timestamps) { ["oneDayAgo@12:00+00:00"] }

        it_behaves_like "contract is valid"
      end

      context "when the shortcut value 'now' is provided" do
        let(:timestamps) { ["now"] }

        it_behaves_like "contract is valid"
      end

      context "when the 'PT0S' duration value is provided" do
        let(:timestamps) { ["PT0S"] }

        it_behaves_like "contract is valid"
      end

      context "when the 'P-1D' duration value is provided" do
        let(:timestamps) { ["P-1D"] }

        it_behaves_like "contract is valid"
      end

      context "when an iso8601 datetime value from yesterday is provided" do
        let(:timestamps) { [1.day.ago.beginning_of_day.iso8601] }

        it_behaves_like "contract is valid"
      end

      context "when the 'lastWorkingDay' value is provided and it's yesterday" do
        let(:timestamps) { "lastWorkingDay@00:00+00:00" }

        it_behaves_like "contract is valid"
      end

      Timestamp::ALLOWED_DATE_KEYWORDS[2..].each do |timestamp_date_keyword|
        context "when the '#{timestamp_date_keyword}' value is provided" do
          let(:timestamps) { ["#{timestamp_date_keyword}@12:00+00:00"] }

          it_behaves_like "contract is invalid", timestamps: :forbidden
        end
      end

      context "when the 'lastWorkingDay' value is provided and it's before yesterday" do
        let(:timestamps) { "lastWorkingDay@00:00+00:00" }

        before do
          allow(Day).to receive(:last_working) { Day.new(date: 7.days.ago) }
        end

        it_behaves_like "contract is invalid", timestamps: :forbidden
      end

      context "when a duration value older than yesterday is provided" do
        let(:timestamps) { ["P-2D"] }

        it_behaves_like "contract is invalid", timestamps: :forbidden
      end

      context "when an iso8601 datetime value older than yesterday is provided" do
        let(:timestamps) { [2.days.ago.end_of_day.iso8601] }

        it_behaves_like "contract is invalid", timestamps: :forbidden
      end
    end
  end
end

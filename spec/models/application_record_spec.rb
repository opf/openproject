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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ApplicationRecord do
  describe "#most_recently_changed" do
    let!(:work_package) do
      create(:work_package).tap do |wp|
        wp.update_column(:updated_at, 5.days.from_now)
      end
    end

    let!(:type) do
      create(:type).tap do |type|
        type.update_column(:updated_at, 1.day.from_now)
      end
    end

    let!(:status) { create(:status) }

    def expect_matched_date(postgres_time, rails_time)
      # Rails uses timestamp without timezone for timestamp columns
      postgres_utc_iso8601 = Time.zone.parse(postgres_time.to_s).iso8601
      rails_utc_iso8601 = rails_time.iso8601

      expect(postgres_utc_iso8601).to eq(rails_utc_iso8601)
    end

    it "returns the most recently changed timestamp of the given resource classes" do
      expect_matched_date described_class.most_recently_changed(WorkPackage, Type, Status),
                          work_package.updated_at

      expect_matched_date described_class.most_recently_changed(Status, Type),
                          type.updated_at

      expect_matched_date described_class.most_recently_changed(Status),
                          status.updated_at
    end
  end
end

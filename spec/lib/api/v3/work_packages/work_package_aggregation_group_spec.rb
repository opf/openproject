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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe API::V3::WorkPackages::WorkPackageAggregationGroup do
  let(:current_user) { build_stubbed(:user, preferences: { time_zone: "Europe/Brussels" }) }
  let(:count) { 2 }
  let(:query) do
    build_stubbed(:query).tap do |query|
      allow(query).to receive(:group_by_column).and_return(group_by_column)
    end
  end

  subject { described_class.new(group_key, count, query:, current_user:).to_json }

  context "when grouping by a datetime custom field" do
    let(:custom_field) { build_stubbed(:datetime_wp_custom_field) }
    let(:group_by_column) { Queries::WorkPackages::Selects::CustomFieldSelect.new(custom_field) }
    let(:group_key) { Time.utc(2026, 10, 1, 12, 30) }

    it "renders the value like the work package attribute (ISO 8601 in UTC)" do
      expect(subject).to be_json_eql("2026-10-01T12:30:00.000Z".to_json).at_path("value")
    end

    context "without a value" do
      let(:group_key) { nil }

      it "renders null" do
        expect(subject).to be_json_eql(nil.to_json).at_path("value")
      end
    end
  end

  context "when grouping by a date custom field" do
    let(:custom_field) { build_stubbed(:date_wp_custom_field) }
    let(:group_by_column) { Queries::WorkPackages::Selects::CustomFieldSelect.new(custom_field) }
    let(:group_key) { Date.new(2026, 10, 1) }

    it "keeps rendering the date" do
      expect(subject).to be_json_eql("2026-10-01".to_json).at_path("value")
    end
  end
end

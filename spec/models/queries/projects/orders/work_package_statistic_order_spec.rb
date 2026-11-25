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

RSpec.describe Queries::Projects::Orders::WorkPackageStatisticOrder do
  let(:instance) do
    described_class.new(attribute).tap do |i|
      i.direction = direction
    end
  end
  let(:attribute) { :work_packages_completion }
  let(:direction) { :desc }

  it "is registered for every statistic column" do
    Projects::WorkPackageStatistics::ATTRIBUTES.each do |key|
      expect(described_class.key).to match(key.to_s)
    end
  end

  it "does not match unrelated columns" do
    expect(described_class.key).not_to match("work_packages_total_bogus")
  end

  context "with a valid direction" do
    it "orders by the completion, listing projects without work packages last" do
      expect(instance.apply_to(Project).to_sql)
        .to include("ORDER BY wp_stats_for_sort.work_packages_completion DESC NULLS LAST")
    end

    context "for a count column" do
      let(:attribute) { :work_packages_overdue }

      it "treats missing counts as zero" do
        expect(instance.apply_to(Project).to_sql)
          .to include("ORDER BY COALESCE(wp_stats_for_sort.work_packages_overdue, 0) DESC NULLS LAST")
      end
    end
  end

  context "with an invalid direction" do
    let(:direction) { "bogus" }

    it "raises an error" do
      expect { instance.apply_to(Project) }.to raise_error(ArgumentError)
    end
  end
end

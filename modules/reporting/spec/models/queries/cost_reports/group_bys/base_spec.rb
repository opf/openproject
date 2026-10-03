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

RSpec.describe Queries::CostReports::GroupBys::Base do
  current_user { create(:admin) }

  let(:registered) { Queries::Register.group_bys[CostReportQuery] }
  let(:static) { registered - [Queries::CostReports::GroupBys::CustomField] }

  describe "every registered group by" do
    it "derives its key from its class name" do
      expect(Queries::CostReports::GroupBys::WorkPackageId.key).to eq(:work_package_id)
      expect(Queries::CostReports::GroupBys::Week.key).to eq(:week)
    end

    it "is resolvable through the query" do
      query = CostReportQuery.new(name: "probe")

      static.each do |group_by_class|
        resolved = query.group_by_for(group_by_class.key)

        expect(resolved).to be_a(group_by_class), "#{group_by_class.key} did not resolve"
      end
    end

    it "takes its caption from the engine group by" do
      static.each do |group_by_class|
        group_by = group_by_class.new(group_by_class.key)

        expect(group_by.caption).to be_present, "#{group_by_class} has no caption"
      end
    end

    it "is valid" do
      static.each do |group_by_class|
        expect(group_by_class.new(group_by_class.key)).to be_valid
      end
    end

    it "does not group itself, leaving that to the engine" do
      group_by = Queries::CostReports::GroupBys::Week.new(:week)

      expect { group_by.apply_to(TimeEntry.all) }.to raise_error(NotImplementedError)
    end
  end

  describe "usage on a query" do
    let(:query) { CostReportQuery.new(name: "probe") }

    it "can group by several dimensions at once" do
      query.group(:week, :project_id, :work_package_id)

      expect(query).to be_valid
      expect(query.group_bys.map(&:name)).to eq(%i[week project_id work_package_id])
    end

    it "rejects a dimension the engine does not know" do
      query.group(:nonsense)

      expect(query).not_to be_valid
    end
  end

  describe Queries::CostReports::GroupBys::CustomField do
    shared_let(:custom_field) { create(:list_wp_custom_field, is_for_all: true) }

    it "is keyed by custom field id" do
      expect(described_class.key).to match("cf_#{custom_field.id}")
    end

    it "names itself after the custom field" do
      expect(described_class.new(:"cf_#{custom_field.id}").caption).to eq(custom_field.name)
    end

    it "is unavailable for a custom field that no longer exists" do
      removed_id = 0

      expect(described_class.new(:"cf_#{removed_id}")).not_to be_available
    end

    it "is resolvable through the query" do
      query = CostReportQuery.new(name: "probe")

      expect(query.group_by_for(:"cf_#{custom_field.id}")).to be_a(described_class)
    end
  end
end

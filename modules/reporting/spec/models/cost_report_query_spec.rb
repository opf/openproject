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

RSpec.describe CostReportQuery do
  current_user { create(:admin) }

  let(:instance) { described_class.new(name: "Costs") }

  describe "registration" do
    it "registers a filter for every user facing engine filter" do
      registered = Queries::Register.filters[described_class].map { |filter| filter.key.to_s }

      # PermissionFilter and NoFilter are system filters injected by the engine
      # itself, so they are deliberately not offered.
      engine = CostQuery::Filter.all
                                .reject { |filter| filter.name.to_s.match?(/CustomField\d+|PermissionFilter|NoFilter/) }
                                .map { |filter| filter.name.demodulize.underscore }

      expect(engine - registered).to be_empty
    end

    it "registers a group by for every user facing engine group by" do
      registered = Queries::Register.group_bys[described_class].map { |group_by| group_by.key.to_s }

      # SingletonValue is injected by the table widget when an axis is empty.
      engine = CostQuery::GroupBy.all
                                 .reject { |group_by| group_by.name.to_s.match?(/CustomField\d+|SingletonValue/) }
                                 .map { |group_by| group_by.name.demodulize.underscore }

      expect(engine - registered).to be_empty
    end

    it "registers a custom field filter and group by" do
      expect(Queries::Register.filters[described_class])
        .to include(Queries::CostReports::Filters::CustomFieldFilter)
      expect(Queries::Register.group_bys[described_class])
        .to include(Queries::CostReports::GroupBys::CustomField)
    end
  end

  describe "persistence" do
    it "is stored as a PersistedQuery" do
      instance.save!

      expect(PersistedQuery.find(instance.id)).to be_a(described_class)
    end

    it "round trips filters" do
      instance.where("spent_on", ">d", ["2026-01-01"])
      instance.save!

      reloaded = described_class.find(instance.id).filters.first

      expect([reloaded.name, reloaded.operator, reloaded.values])
        .to eq([:spent_on, ">d", ["2026-01-01"]])
    end

    it "round trips group bys, keeping their order" do
      instance.group(:week, :project_id)
      instance.save!

      expect(described_class.find(instance.id).group_bys.map(&:name)).to eq(%i[week project_id])
    end

    it "stores the group bys as a flat array of attribute names" do
      instance.group(:week, :project_id)
      instance.save!

      raw = described_class.connection.select_value(
        "SELECT group_bys FROM persisted_queries WHERE id = #{instance.id}"
      )

      expect(JSON.parse(raw)).to eq(%w[week project_id])
    end

    it "has no group bys by default" do
      expect(instance.group_bys).to eq([])
    end
  end

  describe "#visible" do
    let(:user) { create(:user) }
    let!(:own_query) { create(:cost_report_query, principal: user) }
    let!(:other_query) { create(:cost_report_query, principal: create(:user)) }

    it "only returns the queries of the given user" do
      expect(described_class.visible(user)).to contain_exactly(own_query)
    end
  end

  describe "#engine_query" do
    let(:project) { create(:project) }

    before do
      instance.project = project
      instance.where("spent_on", ">d", ["2026-01-01"])
      instance.group(:week, :project_id)
    end

    it "replays the definition into a reporting engine query" do
      expect(instance.engine_query).to be_a(CostQuery)
    end

    it "replays the filters" do
      names = instance.engine_query.filters.map { |filter| filter.class.name.demodulize }

      expect(names).to include("SpentOn")
    end

    it "replays the group bys" do
      names = instance.engine_query.group_bys.map { |group_by| group_by.class.name.demodulize }

      expect(names).to contain_exactly("Week", "ProjectId")
    end

    it "passes the project on" do
      expect(instance.engine_query.project).to eq(project)
    end

    it "builds a chain that produces SQL" do
      expect(instance.engine_query.sql_statement.to_s).to be_present
    end
  end

  describe "#default_scope" do
    it "raises, because the engine computes the results" do
      expect { instance.default_scope }.to raise_error(NotImplementedError)
    end
  end
end

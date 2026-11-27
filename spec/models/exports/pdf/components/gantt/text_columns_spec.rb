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

RSpec.describe Exports::PDF::Components::Gantt::TextColumns do
  subject(:text_columns) { described_class.new(query) }

  let(:query) { build_stubbed(:query) }
  let(:string_cf) { build_stubbed(:string_wp_custom_field) }
  let(:list_cf) { build_stubbed(:list_wp_custom_field) }
  let(:user_cf) { build_stubbed(:user_wp_custom_field) }
  let(:int_cf) { build_stubbed(:integer_wp_custom_field) }
  let(:date_cf) { build_stubbed(:date_wp_custom_field) }
  let(:bool_cf) { build_stubbed(:boolean_wp_custom_field) }
  let(:text_cf) { build_stubbed(:text_wp_custom_field) }
  let(:property_columns) { Queries::WorkPackages::Selects::PropertySelect.instances }
  let(:custom_field_columns) do
    [string_cf, list_cf, user_cf, int_cf, date_cf, bool_cf, text_cf]
      .map { |cf| Queries::WorkPackages::Selects::CustomFieldSelect.new(cf) }
  end
  let(:relation_columns) { Queries::WorkPackages::Selects::RelationOfTypeSelect.instances }
  let(:displayable_columns) { property_columns + custom_field_columns + relation_columns }

  before do
    allow(query).to receive(:displayable_columns).and_return(displayable_columns)
  end

  def column(name)
    displayable_columns.find { |c| c.name.to_s == name.to_s }
  end

  def names(columns)
    columns.map { |c| c.name.to_s }
  end

  describe "#kind" do
    it "classifies the subject" do
      expect(text_columns.kind(column(:subject))).to eq(:subject)
    end

    it "classifies properties without a typed database column as simple text" do
      %i[project parent assigned_to author responsible category labels status type priority
         shared_with_users].each do |name|
        expect(text_columns.kind(column(name))).to eq(:simple_text), "expected #{name} to be simple text"
      end
    end

    it "classifies properties with a date, time, numeric or boolean database column as fixed" do
      %i[id start_date due_date created_at updated_at
         estimated_hours remaining_hours done_ratio duration].each do |name|
        expect(text_columns.kind(column(name))).to eq(:fixed), "expected #{name} to be fixed"
      end
    end

    it "classifies computed numeric properties as fixed" do
      spent_hours = column(:spent_hours)
      currency_columns = %i[material_costs labor_costs overall_costs]
                           .map { |name| Queries::WorkPackages::Selects::WorkPackageSelect.new(name) }

      expect([spent_hours, *currency_columns].map { |c| text_columns.kind(c) }).to all(eq(:fixed))
    end

    it "classifies the budget as simple text" do
      budget = Queries::WorkPackages::Selects::WorkPackageSelect.new(:budget)

      expect(text_columns.kind(budget)).to eq(:simple_text)
    end

    it "classifies simple text custom fields" do
      [string_cf, list_cf, user_cf].each do |cf|
        expect(text_columns.kind(column(cf.column_name))).to eq(:simple_text)
      end
    end

    it "classifies fixed custom fields" do
      [int_cf, date_cf, bool_cf].each do |cf|
        expect(text_columns.kind(column(cf.column_name))).to eq(:fixed)
      end
    end

    it "rejects long text custom fields" do
      expect(text_columns.kind(column(text_cf.column_name))).to be_nil
    end

    it "rejects relation columns" do
      expect(relation_columns.map { |c| text_columns.kind(c) }).to all(be_nil)
    end

    it "classifies columns contributed by other select classes by their database column" do
      story_points = Queries::WorkPackages::Selects::WorkPackageSelect.new(:story_points)
      sprint = Queries::WorkPackages::Selects::WorkPackageSelect.new(:sprint)

      expect(text_columns.kind(story_points)).to eq(:fixed)
      expect(text_columns.kind(sprint)).to eq(:simple_text)
    end
  end

  describe "#available" do
    it "excludes long text custom fields and relation columns" do
      available_names = names(text_columns.available)

      expect(available_names).to include("subject", string_cf.column_name, int_cf.column_name)
      expect(available_names).not_to include(text_cf.column_name, *names(relation_columns))
    end
  end

  describe "#defaults" do
    it "returns ID, subject, start date and finish date" do
      expect(names(text_columns.defaults)).to eq(%w[id subject start_date due_date])
    end

    context "when the query's own columns differ" do
      before { allow(query).to receive(:columns).and_return([column(:status), column(:priority)]) }

      it "ignores them" do
        expect(names(text_columns.defaults)).to eq(%w[id subject start_date due_date])
      end
    end
  end

  describe "#resolve" do
    it "uses the defaults when no selection is given" do
      expect(names(text_columns.resolve(nil))).to eq(%w[id subject start_date due_date])
    end

    it "keeps the requested order" do
      expect(names(text_columns.resolve(%w[due_date subject id]))).to eq(%w[due_date subject id])
    end

    it "accepts symbols" do
      expect(names(text_columns.resolve(%i[subject status]))).to eq(%w[subject status])
    end

    it "caps the selection at the maximum column count" do
      requested = %w[id subject type status priority start_date due_date]

      expect(names(text_columns.resolve(requested))).to eq(%w[id subject type status priority start_date])
    end

    it "drops disallowed and unknown columns before applying the cap" do
      requested = [text_cf.column_name, relation_columns.first.name.to_s, "unknown", "id", "subject"]

      expect(names(text_columns.resolve(requested))).to eq(%w[id subject])
    end

    it "drops duplicates" do
      expect(names(text_columns.resolve(%w[id id subject]))).to eq(%w[id subject])
    end

    it "falls back to the subject for an empty selection" do
      expect(names(text_columns.resolve([]))).to eq(%w[subject])
    end

    it "falls back to the subject when nothing selected is allowed" do
      expect(names(text_columns.resolve([text_cf.column_name]))).to eq(%w[subject])
    end
  end
end

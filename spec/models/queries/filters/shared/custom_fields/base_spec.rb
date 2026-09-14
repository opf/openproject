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

# The sub-select #where produces is rewritten for historic queries by
# Journable::HistoricActiveRecordRelation, which swaps custom_values for customizable_journals.
# These examples pin the rows each operator selects on both the current and the historic path.
RSpec.describe Queries::Filters::Shared::CustomFields::Base, "#where" do
  describe "for a work package custom field" do
    shared_let(:type) { create(:type_task) }
    shared_let(:project) { create(:project, types: [type]) }

    shared_let(:string_cf) { create(:string_wp_custom_field, types: [type], projects: [project]) }
    shared_let(:list_cf) { create(:list_wp_custom_field, types: [type], projects: [project]) }
    shared_let(:int_cf) { create(:integer_wp_custom_field, types: [type], projects: [project]) }
    shared_let(:date_cf) { create(:date_wp_custom_field, types: [type], projects: [project]) }
    # is_for_all skips the custom_fields_projects join, which is a separate code path
    shared_let(:for_all_cf) { create(:string_wp_custom_field, is_for_all: true, types: [type]) }

    shared_let(:option_ids) { list_cf.custom_options.map { |option| option.id.to_s } }

    shared_let(:alpha) do
      create(:work_package, project:, type:).tap do |wp|
        wp.custom_field_values = { string_cf.id => "alpha", list_cf.id => option_ids.first,
                                   int_cf.id => "5", date_cf.id => "2026-01-01",
                                   for_all_cf.id => "alpha" }
        wp.save!
      end
    end

    shared_let(:beta) do
      create(:work_package, project:, type:).tap do |wp|
        wp.custom_field_values = { string_cf.id => "beta", list_cf.id => option_ids.last,
                                   int_cf.id => "50", date_cf.id => "2026-06-01",
                                   for_all_cf.id => "beta" }
        wp.save!
      end
    end

    shared_let(:blank) { create(:work_package, project:, type:) }

    before { [alpha, beta, blank] }

    def filter_for(custom_field, operator, values, historic: false)
      query = build_stubbed(:query, project:)
      query.timestamps = ["2022-08-01T00:00:00Z"] if historic

      Queries::WorkPackages::Filter::CustomFieldFilter.create!(
        name: custom_field.column_name,
        context: query,
        operator:,
        values:
      )
    end

    # Runs both forms and holds them to the same rows. The correlated one is returned because it is
    # the form a baseline query uses.
    def matching(custom_field, operator, values = [])
      filter = filter_for(custom_field, operator, values)
      expect(filter).to be_valid, filter.errors.full_messages.join(", ")

      sub_select = WorkPackage.where(filter.where)
      correlated = WorkPackage.where(filter_for(custom_field, operator, values, historic: true).where)

      expect(correlated.pluck(:id)).to match_array(sub_select.pluck(:id))

      correlated
    end

    describe "a string custom field" do
      it "finds the work package holding the value" do
        expect(matching(string_cf, "=", %w[alpha])).to contain_exactly(alpha)
      end

      it "finds the work packages not holding the value" do
        expect(matching(string_cf, "!", %w[alpha])).to contain_exactly(beta, blank)
      end

      it "finds the work package by a substring" do
        expect(matching(string_cf, "~", %w[lph])).to contain_exactly(alpha)
      end

      # The anchor is what keeps the LEFT OUTER JOIN on the custom values producing a NULL row,
      # which is the only thing "is empty" and the negating operators can match on.
      it "finds the work packages without a value" do
        expect(matching(string_cf, "!*")).to contain_exactly(blank)
      end

      it "finds the work packages with a value" do
        expect(matching(string_cf, "*")).to contain_exactly(alpha, beta)
      end
    end

    describe "a list custom field" do
      it "finds the work package holding the option" do
        expect(matching(list_cf, "=", [option_ids.first])).to contain_exactly(alpha)
      end

      it "finds the work packages not holding the option" do
        expect(matching(list_cf, "!", [option_ids.first])).to contain_exactly(beta, blank)
      end

      it "finds the work packages without a value" do
        expect(matching(list_cf, "!*")).to contain_exactly(blank)
      end
    end

    describe "an integer custom field" do
      it "finds the work package holding the value" do
        expect(matching(int_cf, "=", %w[5])).to contain_exactly(alpha)
      end

      it "finds the work package above a bound" do
        expect(matching(int_cf, ">=", %w[10])).to contain_exactly(beta)
      end

      it "finds the work packages without a value" do
        expect(matching(int_cf, "!*")).to contain_exactly(blank)
      end
    end

    describe "a date custom field" do
      it "finds the work package holding the date" do
        expect(matching(date_cf, "=d", %w[2026-01-01])).to contain_exactly(alpha)
      end

      it "finds the work package within an interval" do
        expect(matching(date_cf, "<>d", %w[2026-05-01 2026-07-01])).to contain_exactly(beta)
      end

      it "finds the work packages without a value" do
        expect(matching(date_cf, "!*")).to contain_exactly(blank)
      end
    end

    # Without the custom_fields_projects join the query has one join fewer to anchor on.
    describe "a custom field activated for all projects" do
      it "finds the work package holding the value" do
        expect(matching(for_all_cf, "=", %w[alpha])).to contain_exactly(alpha)
      end

      it "finds the work packages without a value" do
        expect(matching(for_all_cf, "!*")).to contain_exactly(blank)
      end
    end

    # The CTE built for a baseline query holds one row per matching journal, so `id` is not unique
    # there: any row of an id would satisfy the sub-select form, while the correlated form only
    # lets the row whose own journal matches. The set of ids -- the only thing the historic
    # relation is consumed for -- has to be the same either way.
    describe "in a baseline query spanning two timestamps" do
      let(:monday) { "2022-08-01".to_datetime }
      let(:friday) { "2022-08-05".to_datetime }

      let!(:changed) do
        create(:work_package, project:, type:, journals: { monday => {}, friday => {} })
      end

      # matches on Monday only: on Friday the value is gone
      let!(:monday_value) do
        create(:journal_customizable_journal,
               journal: changed.journals.find_by(created_at: monday),
               custom_field: string_cf,
               value: "alpha")
      end

      def historic_ids(operator, values = [])
        WorkPackage
          .where(filter_for(string_cf, operator, values, historic: true).where)
          .at_timestamp([monday, friday])
          .pluck(:id)
          .uniq
      end

      it "finds the work package that only matched at the earlier timestamp" do
        expect(historic_ids("=", %w[alpha])).to include(changed.id)
      end

      it "does not find it for a value it never held" do
        expect(historic_ids("=", %w[gamma])).not_to include(changed.id)
      end

      it "finds it as empty, because it held no value on Friday" do
        expect(historic_ids("!*")).to include(changed.id)
      end
    end
  end

  # The switch lives on the shared base, so it applies to every custom field context. A project or
  # user query has no #historic? and therefore no CTE to inline, so both keep the sub-select form;
  # the requirement is that neither regresses.
  describe "for a project custom field" do
    shared_let(:project_cf) { create(:string_project_custom_field) }
    shared_let(:admin) { create(:admin) }
    shared_let(:matching_project) do
      create(:project).tap do |project|
        create(:custom_value, custom_field: project_cf, customized: project, value: "alpha")
      end
    end
    shared_let(:other_project) do
      create(:project).tap do |project|
        create(:custom_value, custom_field: project_cf, customized: project, value: "beta")
      end
    end

    # where_subselect_conditions gates on the current user's view_project_attributes.
    current_user { admin }

    def matching(operator, values = [])
      filter = Queries::Projects::Filters::CustomFieldFilter.create!(
        name: project_cf.column_name, operator:, values:
      )

      Project.where(filter.where)
    end

    it "finds the project by its custom value" do
      expect(matching("=", %w[alpha])).to contain_exactly(matching_project)
    end

    it "finds the projects not holding the value" do
      expect(matching("!", %w[alpha])).to include(other_project)
      expect(matching("!", %w[alpha])).not_to include(matching_project)
    end

    it "finds the projects with a value" do
      expect(matching("*")).to contain_exactly(matching_project, other_project)
    end
  end

  describe "for a user custom field" do
    shared_let(:user_cf) { create(:user_custom_field, :string) }
    shared_let(:admin) { create(:admin) }
    shared_let(:matching_user) do
      create(:user).tap { |user| create(:custom_value, custom_field: user_cf, customized: user, value: "alpha") }
    end
    shared_let(:other_user) do
      create(:user).tap { |user| create(:custom_value, custom_field: user_cf, customized: user, value: "beta") }
    end

    current_user { admin }

    def matching(operator, values = [])
      filter = Queries::Users::Filters::CustomFieldFilter.create!(
        name: user_cf.column_name, operator:, values:
      )

      User.where(filter.where)
    end

    it "finds the user by their custom value" do
      expect(matching("=", %w[alpha])).to contain_exactly(matching_user)
    end

    it "finds the users with a value" do
      expect(matching("*")).to contain_exactly(matching_user, other_user)
    end
  end
end

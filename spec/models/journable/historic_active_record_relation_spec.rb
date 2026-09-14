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

RSpec.describe Journable::HistoricActiveRecordRelation do
  # See: https://github.com/opf/openproject/pull/11243

  let(:before_monday) { "2022-01-01".to_datetime }
  let(:monday) { "2022-08-01".to_datetime }
  let(:tuesday) { "2022-08-02".to_datetime }
  let(:wednesday) { "2022-08-03".to_datetime }
  let(:thursday) { "2022-08-04".to_datetime }
  let(:friday) { "2022-08-05".to_datetime }
  let(:work_package_attributes) { {} }
  let(:project) { create(:project) }
  let!(:work_package) do
    create(:work_package,
           description: "The work package as it is since Friday",
           estimated_hours: 10,
           project:,
           journals: {
             monday => { description: "The work package as it has been on Monday", estimated_hours: 5 },
             wednesday => { description: "The work package as it has been on Wednesday", estimated_hours: 10 },
             friday => { description: "The work package as it is since Friday", estimated_hours: 10 }
           },
           position: 1)
  end
  let(:journable) { work_package }
  let(:monday_journal) do
    work_package.journals.find_by(created_at: monday)
  end
  let(:wednesday_journal) do
    work_package.journals.find_by(created_at: wednesday)
  end
  let(:friday_journal) do
    work_package.journals.find_by(created_at: friday)
  end

  let(:relation) { WorkPackage.all }
  let(:historic_relation) { relation.at_timestamp(wednesday) }

  subject { historic_relation }

  describe "#pluck" do
    describe "id" do
      subject { historic_relation.pluck(:id) }

      it "returns the id of the work package" do
        expect(subject).to eq [work_package.id]
      end
    end

    describe "description" do
      subject { historic_relation.pluck(:description) }

      it "returns the description of the work package" do
        expect(subject).to eq ["The work package as it has been on Wednesday"]
      end
    end

    describe "created_at" do
      subject { historic_relation.pluck(:created_at) }

      it "returns the created_at of the work package" do
        expect(subject).to eq [monday]
      end
    end

    describe "updated_at" do
      subject { historic_relation.pluck(:updated_at) }

      it "returns the updated_at of the journal active on the queried for date" do
        expect(subject).to eq [wednesday]
      end
    end

    describe "timestamp" do
      subject { historic_relation.pluck(:timestamp) }

      it "returns the timestamp queried for" do
        expect(subject).to eq [wednesday.to_s]
      end
    end

    describe "position" do
      subject { historic_relation.pluck(:position) }

      it "returns null because the column is not journalized" do
        expect(subject).to eq [nil]
      end

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "prints a warning" do
        allow(Rails.logger).to receive(:warn)
        subject
        expect(Rails.logger).to have_received(:warn).with(/position/)
      end
    end
  end

  shared_examples "historic work package is returned" do
    let(:expected_timestamp) { wednesday }
    let(:expected_journal) { wednesday_journal }

    it "returns the requested work package with journal_id and timestamp added and attributes adapted", :aggregate_failures do
      expect(subject.to_a).to match [work_package]
      expect(subject.to_a.first.journal_id).to eql expected_journal.id
      expect(subject.to_a.first.timestamp).to eql expected_timestamp.to_s
      expect(subject.to_a.first.created_at).to eql work_package.created_at
      expect(subject.to_a.first.updated_at).to eql expected_journal.updated_at
      expect(subject.to_a.first.position).to be_nil
    end
  end

  describe "#where" do
    describe "project_id in array (Arel::Nodes::HomogeneousIn)" do
      let(:relation) { WorkPackage.where(project_id: [project.id, 1, 2, 3]) }

      describe "#to_a" do
        it_behaves_like "historic work package is returned"
      end
    end

    describe "project_id not in array (Arel::Nodes::HomogeneousIn)" do
      let(:relation) { WorkPackage.where.not(project_id: [9999, 999]) }

      describe "#to_a" do
        it_behaves_like "historic work package is returned"
      end
    end

    describe "id in array (Arel::Nodes::HomogeneousIn)" do
      let(:relation) { WorkPackage.where(id: [work_package.id, 999, 9999]) }

      describe "#to_a" do
        it_behaves_like "historic work package is returned"
      end
    end

    describe "id in subquery (Arel::Nodes::In)" do
      let(:relation) { WorkPackage.where(id: [work_package.id, 99, 999, 9999]) }

      describe "#to_a" do
        it_behaves_like "historic work package is returned"
      end
    end

    describe "sql string (as used by Query#statement)" do
      let(:relation) { WorkPackage.where("(work_packages.description ILIKE '%been on Wednesday%')") }

      it_behaves_like "historic work package is returned"

      describe "when the sql where statement includes work_package.id" do
        # This is used, for example, in 'follows' relations.
        let(:relation) { WorkPackage.where("(work_packages.id IN (#{work_package.id}))") }

        it_behaves_like "historic work package is returned"
      end

      describe "when the sql where statement includes \"work_package\".\"id\"" do
        # This is used in the manual-sorting feature.
        let(:relation) { WorkPackage.where("(\"work_packages\".\"id\" IN (#{work_package.id}))") }

        it_behaves_like "historic work package is returned"
      end

      describe "when searching for a single custom field" do
        let(:custom_field) do
          create(:text_wp_custom_field,
                 name: "Text CF",
                 types: project.enabled_types,
                 projects: [project])
        end
        let!(:monday_cf_journal) do
          create(:journal_customizable_journal, journal: monday_journal, custom_field:, value: "Monday_CV")
        end
        let!(:wednesday_cf_journal) do
          create(:journal_customizable_journal, journal: wednesday_journal, custom_field:, value: "Wednesday_CV")
        end
        let!(:friday_cf_journal) do
          create(:journal_customizable_journal, journal: friday_journal, custom_field:, value: "Friday_CV")
        end
        let(:work_package_attributes) { { custom_values: { custom_field.id => "Friday_CV" } } }
        let(:filter) do
          Queries::WorkPackages::Filter::CustomFieldFilter.create!(
            name: custom_field.column_name,
            context: build_stubbed(:query, project:),
            operator: "~",
            values:
          )
        end
        let(:relation) { WorkPackage.where(filter.where) }

        context "with the current value at the current time" do
          let(:values) { %w(Friday_CV) }
          let(:historic_relation) { relation.at_timestamp(Timestamp.new("PT0S")) }

          it_behaves_like "historic work package is returned" do
            let(:expected_timestamp) { "PT0S" }
            let(:expected_journal) { friday_journal }
          end
        end

        context "with the matching historic value" do
          let(:values) { %w(Wednesday_CV) }

          it "transforms the expression to join the customizable_journals" do
            subject.to_sql.squish.tap do |subject_sql|
              expect(subject_sql)
                .to include <<~SQL.squish
                  JOIN customizable_journals ON
                  customizable_journals.journal_id = work_packages.journal_id
                  AND customizable_journals.custom_field_id = #{custom_field.id}
                SQL
              expect(subject_sql).to include "customizable_journals.value ILIKE '%Wednesday\\_CV%'"
            end
          end

          it_behaves_like "historic work package is returned"
        end

        context "with a different historic value" do
          let(:values) { %w(Monday_CV) }

          it "does not return the requested work package" do
            expect(subject).not_to include work_package
          end
        end

        context "with 'is empty' on list field and 'is not' on hierarchy field (Regression#70490)",
                with_ee: [:custom_field_hierarchies] do
          let(:list_custom_field) do
            create(:list_wp_custom_field,
                   name: "List CF",
                   types: project.enabled_types,
                   projects: [project])
          end
          let(:hierarchy_custom_field) do
            create(:hierarchy_wp_custom_field,
                   name: "Hierarchy CF",
                   types: project.enabled_types,
                   projects: [project])
          end

          let!(:wednesday_list_cf_journal) do
            create(:journal_customizable_journal,
                   journal: wednesday_journal,
                   custom_field: list_custom_field,
                   value: "1")
          end
          let!(:wednesday_hierarchy_cf_journal) do
            create(:journal_customizable_journal,
                   journal: wednesday_journal,
                   custom_field: hierarchy_custom_field,
                   value: "1")
          end

          let!(:work_package_matching) do
            create(:work_package, project:, journals: { monday => {}, wednesday => {}, friday => {} })
          end

          let(:is_empty_filter) do
            Queries::WorkPackages::Filter::CustomFieldFilter.create!(
              name: list_custom_field.column_name,
              context: build_stubbed(:query, project:),
              operator: "!*",
              values: []
            )
          end
          let(:is_not_filter) do
            Queries::WorkPackages::Filter::CustomFieldFilter.create!(
              name: hierarchy_custom_field.column_name,
              context: build_stubbed(:query, project:),
              operator: "!",
              values: ["1"]
            )
          end
          let(:relation) { WorkPackage.where("(#{is_empty_filter.where}) AND (#{is_not_filter.where})") }
          let(:historic_relation) { relation.at_timestamp(wednesday) }

          it "transforms the expression to join the customizable_journals with correct value substitutions" do
            subject.to_sql.squish.tap do |subject_sql|
              expect(subject_sql)
                .to include <<~SQL.squish
                  JOIN customizable_journals ON
                  customizable_journals.journal_id = work_packages.journal_id
                  AND customizable_journals.custom_field_id = #{list_custom_field.id}
                SQL
              expect(subject_sql)
                .to include <<~SQL.squish
                  JOIN customizable_journals ON
                  customizable_journals.journal_id = work_packages.journal_id
                  AND customizable_journals.custom_field_id = #{hierarchy_custom_field.id}
                SQL
              expect(subject_sql).not_to include "custom_values.value"
            end
          end

          it "returns only work packages matching both filters at the timestamp" do
            expect(subject).to include work_package_matching
            expect(subject).not_to include work_package
          end
        end
      end

      describe "when searching for two custom fields (concatenated into string as Query#results does)" do
        let(:text_custom_field) do
          create(:text_wp_custom_field,
                 name: "Text CF",
                 types: project.enabled_types,
                 projects: [project])
        end
        let!(:monday_text_cf_journal) do
          create(:journal_customizable_journal,
                 journal: monday_journal,
                 custom_field: text_custom_field,
                 value: "Monday_CV")
        end
        let!(:wednesday_text_cf_journal) do
          create(:journal_customizable_journal,
                 journal: wednesday_journal,
                 custom_field: text_custom_field,
                 value: "Wednesday_CV")
        end
        let!(:friday_text_cf_journal) do
          create(:journal_customizable_journal,
                 journal: friday_journal,
                 custom_field: text_custom_field,
                 value: "Friday_CV")
        end
        let(:int_custom_field) do
          create(:integer_wp_custom_field,
                 name: "Int CF",
                 types: project.enabled_types,
                 projects: [project])
        end
        let!(:monday_int_cf_journal) do
          create(:journal_customizable_journal,
                 journal: monday_journal,
                 custom_field: int_custom_field,
                 value: "1")
        end
        let!(:wednesday_int_cf_journal) do
          create(:journal_customizable_journal,
                 journal: wednesday_journal,
                 custom_field: int_custom_field,
                 value: "2")
        end
        let!(:friday_int_cf_journal) do
          create(:journal_customizable_journal,
                 journal: friday_journal,
                 custom_field: int_custom_field,
                 value: "3")
        end
        let(:work_package_attributes) do
          { custom_values: { text_custom_field.id => "Friday_CV", int_custom_field.id => "3" } }
        end
        let(:text_filter) do
          Queries::WorkPackages::Filter::CustomFieldFilter.create!(
            name: text_custom_field.column_name,
            context: build_stubbed(:query, project:),
            operator: "~",
            values: text_values
          )
        end
        let(:int_filter) do
          Queries::WorkPackages::Filter::CustomFieldFilter.create!(
            name: int_custom_field.column_name,
            context: build_stubbed(:query, project:),
            operator: "=",
            values: int_values
          )
        end
        # Done just like Query#results does it by fetching Query#statement
        let(:relation) { WorkPackage.where("(#{text_filter.where}) AND (#{int_filter.where})") }

        context "with the current value at the current time" do
          let(:text_values) { %w(Friday_CV) }
          let(:int_values) { "3" }
          let(:historic_relation) { relation.at_timestamp(Timestamp.new("PT0S")) }

          it_behaves_like "historic work package is returned" do
            let(:expected_timestamp) { "PT0S" }
            let(:expected_journal) { friday_journal }
          end
        end

        context "with matching historic values" do
          let(:text_values) { %w(Wednesday) }
          let(:int_values) { "2" }
          let(:historic_relation) { relation.at_timestamp(wednesday) }

          it_behaves_like "historic work package is returned"
        end

        # Guards against regression #58600
        context "with only one filter matching historic values" do
          let(:text_values) { %w(Friday) }
          let(:int_values) { "2" }
          let(:historic_relation) { relation.at_timestamp(wednesday) }

          it "returns no work package" do
            expect(subject).to be_empty
          end
        end
      end
    end

    describe "foo OR bar (Arel::Nodes::Grouping)" do
      # https://github.com/opf/openproject/pull/11678#issuecomment-1328011996
      let(:relation) do
        WorkPackage.where(subject: "Foo").or(
          WorkPackage.where(description: "The work package as it has been on Wednesday")
        )
      end

      it_behaves_like "historic work package is returned"
    end

    describe "work_packages.updated_at > ?" do
      # as used by spec/features/work_packages/timeline/timeline_dates_spec.rb
      let(:relation) { WorkPackage.where("work_packages.updated_at > '2022-01-01'") }

      it_behaves_like "historic work package is returned"

      describe "when using quotation marks" do
        let(:relation) { WorkPackage.where("\"work_packages\".\"updated_at\" > '2022-01-01'") }

        it_behaves_like "historic work package is returned"
      end

      describe "when using a hash" do
        let(:relation) { WorkPackage.where(work_packages: { updated_at: ("2022-01-01".to_datetime).. }) }

        it_behaves_like "historic work package is returned"
      end
    end

    describe "work_packages.created_at > ?" do
      # as used by spec/features/work_packages/table/queries/filter_spec.rb
      let(:relation) { WorkPackage.where("work_packages.created_at > '2022-01-01'") }

      it_behaves_like "historic work package is returned"

      describe "when using quotation marks" do
        let(:relation) { WorkPackage.where("\"work_packages\".\"created_at\" > '2022-01-01'") }

        it_behaves_like "historic work package is returned"
      end

      describe "when using a hash" do
        let(:relation) { WorkPackage.where(work_packages: { created_at: ("2022-01-01".to_datetime).. }) }

        it_behaves_like "historic work package is returned"
      end
    end
  end

  describe "#order" do
    let(:relation) { WorkPackage.order(description: :desc) }

    it_behaves_like "historic work package is returned"

    describe "manual order clause" do
      let(:relation) { WorkPackage.order("work_packages.description DESC") }

      it_behaves_like "historic work package is returned"
    end

    describe "manual order clause using work_packages.id" do
      # This is used in the manual-sorting feature.
      let(:relation) { WorkPackage.order("work_packages.id DESC") }

      it_behaves_like "historic work package is returned"
    end

    describe "order clause with work_packages.id" do
      let(:relation) { WorkPackage.order(id: :desc) }

      it_behaves_like "historic work package is returned"
    end

    describe "several order clauses" do
      let(:relation) { WorkPackage.order(subject: :asc, id: :desc) }

      it_behaves_like "historic work package is returned"
    end
  end

  describe "#joins" do
    describe "using active record" do
      let(:relation) { WorkPackage.joins(:time_entries) }

      before { work_package.time_entries << create(:time_entry) }

      it_behaves_like "historic work package is returned"
    end

    describe "using a manual sql expression" do
      # This is used in the manual-sorting feature.
      let(:relation) do
        WorkPackage
          .joins("LEFT OUTER JOIN ordered_work_packages ON ordered_work_packages.work_package_id = work_packages.id")
      end

      it_behaves_like "historic work package is returned"
    end

    describe "using an initial scope with a include(:project)" do
      # This is used in a work package query with timestamps.
      let(:relation) do
        WorkPackage
          .includes(:project)
          .where(projects: { id: project.id })
      end

      it "returns the requested work package with attributes adapted", :aggregate_failures do
        # Different from the other cases, the work package will not have journal_id and timestamp properties here since
        # an include will lead to an explicit projection which does not include the fields as the values
        # seem to be taken from WorkPackage.column_names
        expect(subject.to_a).to match [work_package]
        expect(subject.to_a.first.created_at).to eql work_package.created_at
        expect(subject.to_a.first.updated_at).to eql wednesday_journal.updated_at
        expect(subject.to_a.first.position).to be_nil
      end
    end
  end

  describe "#first" do
    describe "for columns that don't exist in the journal-data table" do
      let(:column_name) { :lock_version }

      subject { historic_relation.first.send(column_name) }

      specify "the column name does exist in the journable table" do
        expect(WorkPackage.column_names).to include column_name.to_s
      end

      specify "the column name does not exist in the journal-data table" do
        expect(Journal::WorkPackageJournal.column_names).not_to include column_name.to_s
      end

      it "has the attribute with null value" do
        expect(historic_relation.first.attributes_before_type_cast[column_name]).to be_nil
      end

      it "has the typecasted value matching the journable class's data type" do
        expect(subject).to eq 0
      end
    end
  end
end

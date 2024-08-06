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

RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter,
               with_flag: { percent_complete_edition: true } do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project_with_types) }
  let(:permissions) { [:edit_work_packages] }
  let(:attribute_query) do
    build_stubbed(:query).tap do |query|
      query.filters.clear
      query.add_filter("parent", "=", ["{id}"])
    end
  end
  let(:attribute_groups) do
    [Type::AttributeGroup.new(wp_type, "People", %w(assignee responsible)),
     Type::AttributeGroup.new(wp_type, "Estimates and time", %w(estimated_time spent_time)),
     Type::QueryGroup.new(wp_type, "Children", attribute_query)]
  end
  let(:schema) do
    API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package:).tap do |schema|
      allow(wp_type)
        .to receive(:attribute_groups)
        .and_return(attribute_groups)
      allow(schema)
        .to receive(:assignable_values)
        .and_call_original
      allow(schema)
        .to receive(:assignable_values)
        .with(:version, current_user)
        .and_return([])
    end
  end
  let(:self_link) { "/a/self/link" }
  let(:base_schema_link) { nil }
  let(:hide_self_link) { false }
  let(:embedded) { true }
  let(:representer) do
    described_class.create(schema,
                           self_link:,
                           form_embedded: embedded,
                           base_schema_link:,
                           current_user:)
  end
  let(:available_custom_fields) { [] }
  let(:wp_type) { project.types.first }
  let(:custom_field) { build_stubbed(:custom_field) }
  let(:work_package) do
    build_stubbed(:work_package, project:, type: wp_type) do |wp|
      allow(wp)
        .to receive(:available_custom_fields)
        .and_return(available_custom_fields)
    end
  end
  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project: schema.project
    end

    login_as(current_user)
    allow(schema.project)
      .to receive(:module_enabled?)
      .and_return(true)

    allow(schema).to receive(:writable?).and_call_original
  end

  context "for generation" do
    subject(:generated) { representer.to_json }

    shared_examples_for "has a collection of allowed values" do
      let(:embedded) { true }

      before do
        allow(schema).to receive(:assignable_values).and_return(nil)
      end

      context "when no values are allowed" do
        before do
          allow(schema).to receive(:assignable_values).with(factory, anything).and_return([])
        end

        it_behaves_like "links to and embeds allowed values directly" do
          let(:path) { json_path }
          let(:hrefs) { [] }
        end
      end

      context "when values are allowed" do
        let(:values) { build_stubbed_list(factory, 3) }

        before do
          allow(schema).to receive(:assignable_values).with(factory, anything).and_return(values)
        end

        it_behaves_like "links to and embeds allowed values directly" do
          let(:path) { json_path }
          let(:hrefs) { values.map { |value| "/api/v3/#{href_path}/#{value.id}" } }
        end
      end

      context "when not embedded" do
        before do
          allow(schema).to receive(:assignable_values).with(factory, anything).and_return(nil)
        end

        it_behaves_like "does not link to allowed values" do
          let(:path) { json_path }
        end
      end
    end

    describe "self link" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { self_link }
      end

      it_behaves_like "has no link" do
        let(:link) { "baseSchema" }
      end

      context "when embedded in a form" do
        let(:self_link) { nil }
        let(:base_schema_link) { "/a/schema/link" }

        it_behaves_like "has no link" do
          let(:link) { "self" }
        end

        it_behaves_like "has an untitled link" do
          let(:link) { "baseSchema" }
          let(:href) { base_schema_link }
        end
      end
    end

    describe "_type" do
      it "is indicated as Schema" do
        expect(subject).to be_json_eql("Schema".to_json).at_path("_type")
      end
    end

    describe "_attributeGroups" do
      it "renders form attribute group elements of the schema" do
        expect(subject)
          .to be_json_eql(
            {
              _type: "WorkPackageFormAttributeGroup",
              name: "People",
              attributes: %w(assignee responsible)
            }.to_json
          )
          .at_path("_attributeGroups/0")

        expect(subject)
          .to be_json_eql(
            {
              _type: "WorkPackageFormAttributeGroup",
              name: "Estimates and time",
              attributes: %w(estimatedTime spentTime)
            }.to_json
          )
          .at_path("_attributeGroups/1")
      end

      it "renders form children query group elements of the schema" do
        expect(subject)
          .to be_json_eql("WorkPackageFormChildrenQueryGroup".to_json)
          .at_path("_attributeGroups/2/_type")

        expect(subject)
          .to be_json_eql(api_v3_paths.query(attribute_query.id).to_json)
          .at_path("_attributeGroups/2/_links/query/href")

        expect(subject)
          .to be_json_eql("Query".to_json)
          .at_path("_attributeGroups/2/_embedded/query/_type")
      end

      context "with relation query group" do
        let(:attribute_query) do
          build_stubbed(:query).tap do |query|
            query.filters.clear
            query.add_filter("follows", "=", ["{id}"])
          end
        end

        it "renders form relation query group elements of the schema" do
          expect(subject)
            .to be_json_eql("WorkPackageFormRelationQueryGroup".to_json)
                  .at_path("_attributeGroups/2/_type")

          expect(subject)
            .to be_json_eql(api_v3_paths.query(attribute_query.id).to_json)
                  .at_path("_attributeGroups/2/_links/query/href")

          expect(subject)
            .to be_json_eql("Query".to_json)
                  .at_path("_attributeGroups/2/_embedded/query/_type")
        end
      end
    end

    describe "lock version" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "lockVersion" }
        let(:type) { "Integer" }
        let(:name) { I18n.t("api_v3.attributes.lock_version") }
        let(:required) { true }
        let(:writable) { true }
      end

      context "when lockVersion disabled" do
        let(:representer) do
          described_class.create(schema,
                                 self_link: nil,
                                 current_user:,
                                 hide_lock_version: true)
        end

        it "is hidden" do
          expect(subject).not_to have_json_path("lockVersion")
        end
      end
    end

    describe "id" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "id" }
        let(:type) { "Integer" }
        let(:name) { I18n.t("attributes.id") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "subject" do
      let(:path) { "subject" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "String" }
        let(:name) { I18n.t("attributes.subject") }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like "indicates length requirements" do
        let(:min_length) { 1 }
        let(:max_length) { 255 }
      end
    end

    describe "description" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "description" }
        let(:type) { "Formattable" }
        let(:name) { I18n.t("attributes.description") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "duration" do
      let(:milestone?) { false }

      before do
        allow(schema)
          .to receive(:milestone?)
          .and_return(milestone?)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "duration" }
        let(:type) { "Duration" }
        let(:name) { I18n.t("activerecord.attributes.work_package.duration") }
        let(:required) { false }
        let(:writable) { true }
      end

      context "when the work package is a milestone" do
        let(:milestone?) { true }

        it "has no duration attribute" do
          expect(subject).not_to have_json_path("duration")
        end
      end
    end

    describe "scheduleManually" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "scheduleManually" }
        let(:type) { "Boolean" }
        let(:name) { I18n.t("activerecord.attributes.work_package.schedule_manually") }
        let(:required) { false }
        let(:has_default) { true }
        let(:writable) { true }
      end
    end

    describe "ignoreNonWorkingDays" do
      before do
        allow(schema)
          .to receive(:writable?)
                .with("ignore_non_working_days")
                .and_return writable
      end

      context "when writable" do
        let(:writable) { true }

        it_behaves_like "has basic schema properties" do
          let(:path) { "ignoreNonWorkingDays" }
          let(:type) { "Boolean" }
          let(:name) { I18n.t("activerecord.attributes.work_package.ignore_non_working_days") }
          let(:required) { false }
          let(:writable) { true }
        end
      end

      context "when not writable" do
        let(:writable) { false }

        it_behaves_like "has basic schema properties" do
          let(:path) { "ignoreNonWorkingDays" }
          let(:type) { "Boolean" }
          let(:name) { I18n.t("activerecord.attributes.work_package.ignore_non_working_days") }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    describe "date" do
      before do
        allow(schema)
          .to receive(:writable?)
          .with("date")
          .and_return true

        allow(schema)
          .to receive(:milestone?)
          .and_return(true)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "date" }
        let(:type) { "Date" }
        let(:name) { I18n.t("attributes.date") }
        let(:required) { false }
        let(:writable) { true }
      end

      context "when not writable" do
        before do
          allow(schema)
            .to receive(:writable?)
            .with("date")
            .and_return false
        end

        it_behaves_like "has basic schema properties" do
          let(:path) { "date" }
          let(:type) { "Date" }
          let(:name) { I18n.t("attributes.date") }
          let(:required) { false }
          let(:writable) { false }
        end
      end

      context "when the work package is no milestone" do
        before do
          allow(schema)
            .to receive(:milestone?)
            .and_return(false)
        end

        it "has no date attribute" do
          expect(subject).not_to have_json_path("date")
        end
      end
    end

    describe "startDate" do
      before do
        allow(schema)
          .to receive(:writable?)
          .with("start_date")
          .and_return true

        allow(schema)
          .to receive(:milestone?)
          .and_return(false)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "startDate" }
        let(:type) { "Date" }
        let(:name) { I18n.t("attributes.start_date") }
        let(:required) { false }
        let(:writable) { true }
      end

      context "when not writable" do
        before do
          allow(schema)
            .to receive(:writable?)
            .with("start_date")
            .and_return false
        end

        it_behaves_like "has basic schema properties" do
          let(:path) { "startDate" }
          let(:type) { "Date" }
          let(:name) { I18n.t("attributes.start_date") }
          let(:required) { false }
          let(:writable) { false }
        end
      end

      context "when the work package is a milestone" do
        before do
          allow(schema)
            .to receive(:milestone?)
            .and_return(true)
        end

        it "has no date attribute" do
          expect(subject).not_to have_json_path("startDate")
        end
      end
    end

    describe "dueDate" do
      before do
        allow(schema)
          .to receive(:writable?)
          .with("due_date")
          .and_return true

        allow(schema)
          .to receive(:milestone?)
          .and_return(false)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "dueDate" }
        let(:type) { "Date" }
        let(:name) { I18n.t("attributes.due_date") }
        let(:required) { false }
        let(:writable) { true }
      end

      context "when not writable" do
        before do
          allow(schema).to receive(:writable?).with("due_date").and_return false
        end

        it_behaves_like "has basic schema properties" do
          let(:path) { "dueDate" }
          let(:type) { "Date" }
          let(:name) { I18n.t("attributes.due_date") }
          let(:required) { false }
          let(:writable) { false }
        end
      end

      context "when the work package is a milestone" do
        before do
          allow(schema)
            .to receive(:milestone?)
            .and_return(true)
        end

        it "has no date attribute" do
          expect(subject).not_to have_json_path("dueDate")
        end
      end
    end

    describe "derivedStartDate" do
      let(:is_milestone) { false }

      before do
        allow(schema)
          .to receive(:milestone?)
          .and_return(is_milestone)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "derivedStartDate" }
        let(:type) { "Date" }
        let(:name) { I18n.t("attributes.derived_start_date") }
        let(:required) { false }
        let(:writable) { false }
      end

      context "when the work package is a milestone" do
        let(:is_milestone) { true }

        it "has no date attribute" do
          expect(subject).not_to have_json_path("derivedStartDate")
        end
      end
    end

    describe "derivedDueDate" do
      let(:is_milestone) { false }

      before do
        allow(schema)
          .to receive(:milestone?)
          .and_return(is_milestone)
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "derivedDueDate" }
        let(:type) { "Date" }
        let(:name) { I18n.t("attributes.derived_due_date") }
        let(:required) { false }
        let(:writable) { false }
      end

      context "when the work package is a milestone" do
        let(:is_milestone) { true }

        it "has no date attribute" do
          expect(subject).not_to have_json_path("derivedDueDate")
        end
      end
    end

    describe "estimatedTime" do
      before do
        allow(schema)
          .to receive(:writable?)
          .with("estimated_hours")
          .and_return true
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "estimatedTime" }
        let(:type) { "Duration" }
        let(:name) { I18n.t("attributes.estimated_time") }
        let(:required) { false }
        let(:writable) { true }
      end

      context "when not writable" do
        before do
          allow(schema)
            .to receive(:writable?)
            .with("estimated_hours")
            .and_return false
        end

        it_behaves_like "has basic schema properties" do
          let(:path) { "estimatedTime" }
          let(:type) { "Duration" }
          let(:name) { I18n.t("attributes.estimated_time") }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    describe "derivedEstimatedTime" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "derivedEstimatedTime" }
        let(:type) { "Duration" }
        let(:name) { I18n.t("attributes.derived_estimated_hours") }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    describe "remainingTime" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "remainingTime" }
        let(:type) { "Duration" }
        let(:name) { I18n.t("activerecord.attributes.work_package.remaining_hours") }
        let(:required) { false }
        let(:writable) { true }
      end

      context 'when on the "status-based" % complete mode',
              with_settings: { work_package_done_ratio: "status" } do
        it_behaves_like "has basic schema properties" do
          let(:path) { "remainingTime" }
          let(:type) { "Duration" }
          let(:name) { I18n.t("activerecord.attributes.work_package.remaining_hours") }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    describe "derivedRemainingTime" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "derivedRemainingTime" }
        let(:type) { "Duration" }
        let(:name) { I18n.t("activerecord.attributes.work_package.derived_remaining_hours") }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    describe "spentTime" do
      context "with the view_time_entries permission" do
        let(:permissions) { %i[edit_work_packages view_time_entries] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "spentTime" }
          let(:type) { "Duration" }
          let(:name) { I18n.t("activerecord.attributes.work_package.spent_time") }
          let(:required) { false }
          let(:writable) { false }
        end
      end

      context "with the view_own_time_entries permission" do
        let(:permissions) { %i[edit_work_packages view_own_time_entries] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "spentTime" }
          let(:type) { "Duration" }
          let(:name) { I18n.t("activerecord.attributes.work_package.spent_time") }
          let(:required) { false }
          let(:writable) { false }
        end
      end

      context "without any view time_entries permission" do
        it "has no spentTime attribute" do
          expect(subject).not_to have_json_path("spentTime")
        end
      end
    end

    describe "percentageDone" do
      context "in work-based progress calculation mode",
              with_settings: { work_package_done_ratio: "field" } do
        it_behaves_like "has basic schema properties" do
          let(:path) { "percentageDone" }
          let(:type) { "Integer" }
          let(:name) { I18n.t("activerecord.attributes.work_package.done_ratio") }
          let(:required) { false }
          let(:writable) { true }
        end
      end

      context "in status-based progress calculation mode",
              with_settings: { work_package_done_ratio: "status" } do
        it_behaves_like "has basic schema properties" do
          let(:path) { "percentageDone" }
          let(:type) { "Integer" }
          let(:name) { I18n.t("activerecord.attributes.work_package.done_ratio") }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end

    describe "derivedPercentageDone" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "derivedPercentageDone" }
        let(:type) { "Integer" }
        let(:name) { I18n.t("activerecord.attributes.work_package.derived_done_ratio") }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    describe "readonly" do
      context "with the enterprise add-on enabled", with_ee: %i[readonly_work_packages] do
        it_behaves_like "has basic schema properties" do
          let(:path) { "readonly" }
          let(:type) { "Boolean" }
          let(:name) { I18n.t("activerecord.attributes.work_package.readonly") }
          let(:required) { false }
          let(:has_default) { true }
          let(:writable) { false }
        end
      end

      context "without the enterprise add-on" do
        it "has no such property" do
          expect(subject).not_to have_json_path("readonly")
        end
      end
    end

    describe "createdAt" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "createdAt" }
        let(:type) { "DateTime" }
        let(:name) { I18n.t("attributes.created_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "updatedAt" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "updatedAt" }
        let(:type) { "DateTime" }
        let(:name) { I18n.t("attributes.updated_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "author" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "author" }
        let(:type) { "User" }
        let(:name) { I18n.t("attributes.author") }
        let(:required) { true }
        let(:writable) { false }
        let(:location) { "_links" }
      end
    end

    describe "project" do
      context "if having the move_work_packages permission" do
        let(:permissions) { [:move_work_packages] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "project" }
          let(:type) { "Project" }
          let(:name) { I18n.t("attributes.project") }
          let(:required) { true }
          let(:writable) { true }
          let(:location) { "_links" }
        end
      end

      context "if having the edit_work_packages permission" do
        let(:permissions) { [:edit_work_packages] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "project" }
          let(:type) { "Project" }
          let(:name) { I18n.t("attributes.project") }
          let(:required) { true }
          let(:writable) { false }
          let(:location) { "_links" }
        end
      end

      context "when updating" do
        it_behaves_like "links to allowed values via collection link" do
          let(:path) { "project" }
          let(:href) { api_v3_paths.available_projects_on_edit(work_package.id) }
        end
      end

      context "when creating (new_record)" do
        let(:work_package) do
          build(:work_package, project:, type: wp_type) do |wp|
            allow(wp)
              .to receive(:available_custom_fields)
              .and_return(available_custom_fields)
          end
        end

        it_behaves_like "links to allowed values via collection link" do
          let(:path) { "project" }
          let(:href) { api_v3_paths.available_projects_on_create }
        end
      end

      context "when creating (new_record with empty type)" do
        let(:work_package) do
          build(:work_package, project:, type: nil) do |wp|
            allow(wp)
              .to receive(:available_custom_fields)
                    .and_return(available_custom_fields)
          end
        end

        it_behaves_like "links to allowed values via collection link" do
          let(:path) { "project" }
          let(:href) { api_v3_paths.available_projects_on_create }
        end
      end

      context "when not embedded" do
        let(:embedded) { false }

        it_behaves_like "does not link to allowed values" do
          let(:path) { "project" }
        end
      end
    end

    describe "parent" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "parent" }
        let(:type) { "WorkPackage" }
        let(:name) { I18n.t("activerecord.attributes.work_package.parent") }
        let(:required) { false }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      it_behaves_like "links to allowed values via collection link" do
        let(:path) { "parent" }
        let(:href) { api_v3_paths.work_package_available_relation_candidates(work_package.id, type: :parent) }
      end

      context "when creating" do
        let(:work_package) do
          build(:work_package, project:) do |wp|
            allow(wp)
              .to receive(:available_custom_fields)
                    .and_return(available_custom_fields)
          end
        end

        it_behaves_like "does not link to allowed values" do
          let(:path) { "parent" }
        end
      end
    end

    describe "type" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "type" }
        let(:type) { "Type" }
        let(:name) { I18n.t("activerecord.attributes.work_package.type") }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      it_behaves_like "has a collection of allowed values" do
        let(:json_path) { "type" }
        let(:href_path) { "types" }
        let(:factory) { :type }
      end
    end

    describe "status" do
      context "if having the change_work_package_status permission" do
        let(:permissions) { [:change_work_package_status] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "status" }
          let(:type) { "Status" }
          let(:name) { I18n.t("attributes.status") }
          let(:required) { true }
          let(:writable) { true }
          let(:has_default) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "has a collection of allowed values" do
          let(:json_path) { "status" }
          let(:href_path) { "statuses" }
          let(:factory) { :status }
        end
      end

      # Just edit_work_packages without change_work_package_status still makes status writable:
      context "if having the edit_work_packages permission" do
        let(:permissions) { [:edit_work_packages] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "status" }
          let(:type) { "Status" }
          let(:name) { I18n.t("attributes.status") }
          let(:required) { true }
          let(:writable) { true }
          let(:has_default) { true }
          let(:location) { "_links" }
        end
      end
    end

    describe "categories" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "category" }
        let(:type) { "Category" }
        let(:name) { I18n.t("attributes.category") }
        let(:required) { false }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      it_behaves_like "has a collection of allowed values" do
        let(:json_path) { "category" }
        let(:href_path) { "categories" }
        let(:factory) { :category }
      end
    end

    describe "versions" do
      context "if having the assign_versions permission" do
        let(:permissions) { [:assign_versions] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "version" }
          let(:type) { "Version" }
          let(:name) { I18n.t("activerecord.attributes.work_package.version") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "has a collection of allowed values" do
          let(:json_path) { "version" }
          let(:href_path) { "versions" }
          let(:factory) { :version }
        end
      end

      context "if having the edit_work_packages permission" do
        let(:permissions) { [:edit_work_packages] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "version" }
          let(:type) { "Version" }
          let(:name) { I18n.t("activerecord.attributes.work_package.version") }
          let(:required) { false }
          let(:writable) { false }
          let(:location) { "_links" }
        end
      end
    end

    describe "priorities" do
      before do
        allow(schema).to receive(:writable?).with("priority").and_return true
      end

      it_behaves_like "has basic schema properties" do
        let(:path) { "priority" }
        let(:type) { "Priority" }
        let(:name) { I18n.t("activerecord.attributes.work_package.priority") }
        let(:required) { true }
        let(:writable) { true }
        let(:has_default) { true }
        let(:location) { "_links" }
      end

      it_behaves_like "has a collection of allowed values" do
        let(:json_path) { "priority" }
        let(:href_path) { "priorities" }
        let(:factory) { :priority }
      end

      context "when not writable" do
        before do
          allow(schema).to receive(:writable?).with("priority").and_return false
        end

        it_behaves_like "has basic schema properties" do
          let(:path) { "priority" }
          let(:type) { "Priority" }
          let(:name) { I18n.t("activerecord.attributes.work_package.priority") }
          let(:required) { true }
          let(:writable) { false }
          let(:has_default) { true }
          let(:location) { "_links" }
        end
      end
    end

    describe "responsible and assignee" do
      let(:base_href) { "/api/v3/projects/#{work_package.project.id}" }
      let(:wp_base_href) { "/api/v3/work_packages/#{work_package.id}" }

      describe "assignee" do
        it_behaves_like "has basic schema properties" do
          let(:path) { "assignee" }
          let(:type) { "User" }
          let(:name) { I18n.t("attributes.assigned_to") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "links to allowed values via collection link" do
          let(:path) { "assignee" }
          let(:base_href) { "/api/v3/work_packages/#{work_package.id}" }
          let(:href) { "#{base_href}/available_assignees" }
        end

        context "when not embedded" do
          let(:embedded) { false }

          it_behaves_like "does not link to allowed values" do
            let(:path) { "assignee" }
          end
        end

        context "when not having a project (yet) and not yet persisted" do
          before do
            work_package.project = nil

            allow(work_package).to receive(:persisted?).and_return(false)
          end

          it_behaves_like "does not link to allowed values" do
            let(:path) { "assignee" }
          end
        end
      end

      describe "responsible" do
        it_behaves_like "has basic schema properties" do
          let(:path) { "responsible" }
          let(:type) { "User" }
          let(:name) { I18n.t("attributes.responsible") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        context "when the work package is persisted" do
          it_behaves_like "links to allowed values via collection link" do
            let(:path) { "responsible" }
            let(:href) { "#{wp_base_href}/available_assignees" }
          end
        end

        context "when the work package is not persisted" do
          let(:work_package) { build(:work_package, project:) }

          it_behaves_like "links to allowed values via collection link" do
            let(:path) { "responsible" }
            let(:href) { "#{base_href}/available_assignees" }
          end
        end

        context "when not embedded" do
          let(:embedded) { false }

          it_behaves_like "does not link to allowed values" do
            let(:path) { "responsible" }
          end
        end

        context "when not having a project (yet) and not yet persisted" do
          before do
            work_package.project = nil

            allow(work_package).to receive(:persisted?).and_return(false)
          end

          it_behaves_like "does not link to allowed values" do
            let(:path) { "responsible" }
          end
        end
      end
    end

    describe "budget" do
      context "when user allowed to view_budgets" do
        let(:permissions) { %i[edit_work_packages view_budgets] }

        it_behaves_like "has basic schema properties" do
          let(:path) { "budget" }
          let(:type) { "Budget" }
          let(:name) { I18n.t("attributes.budget") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        it_behaves_like "has a collection of allowed values" do
          let(:json_path) { "budget" }
          let(:href_path) { "budgets" }
          let(:factory) { :budget }
        end
      end

      context "when user not allowed to view_budgets" do
        it "has no schema for budget" do
          expect(subject).not_to have_json_path("budget")
        end
      end
    end

    describe "custom fields" do
      let(:available_custom_fields) { [build_stubbed(:integer_wp_custom_field)] }

      it "uses a CustomFieldInjector" do
        allow(API::V3::Utilities::CustomFieldInjector).to receive(:create_schema_representer)
          .and_return(described_class)
        representer.to_json

        expect(API::V3::Utilities::CustomFieldInjector).to have_received(:create_schema_representer)
      end
    end
  end

  describe "caching" do
    context "for a SpecificWorkPackageSchema" do
      # do not interfere with the representer cache fetching
      let(:attribute_groups) { [] }

      it "is disabled" do
        allow(OpenProject::Cache).to receive(:fetch)

        representer.to_json

        expect(OpenProject::Cache)
          .not_to have_received(:fetch)
      end
    end

    context "for a TypedWorkPackageSchema" do
      # do not interfere with the representer cache fetching
      let(:attribute_groups) { [] }

      let(:embedded) { false }

      let(:schema) do
        API::V3::WorkPackages::Schema::TypedWorkPackageSchema
          .new(type: work_package.type, project:).tap do |schema|
          allow(wp_type)
            .to receive(:attribute_groups)
            .and_return(attribute_groups)
          allow(schema)
            .to receive(:assignable_values)
            .and_call_original
          allow(schema)
            .to receive(:assignable_values)
            .with(:version, current_user)
            .and_return([])
        end
      end

      it "is based on the representer's cache_key" do
        allow(OpenProject::Cache)
          .to receive(:fetch)
          .with(representer.json_cache_key)
          .and_call_original

        representer.to_json

        expect(OpenProject::Cache)
          .to have_received(:fetch)
          .with(representer.json_cache_key)
      end

      it "does not cache the attribute_groups" do
        call_count = 0
        allow(work_package.type)
          .to receive(:attribute_groups) do
          call_count += 1
          []
        end

        # Rendering two times, the Type#attribute_groups
        # should still be called on the second rendering.
        representer.to_json
        expect { representer.to_json }
          .to change { call_count }
      end
    end

    describe "#json_cache_key" do
      def joined_cache_key
        representer.json_cache_key.join("/")
      end

      before do
        allow(work_package.project)
          .to receive(:all_work_package_custom_fields)
          .and_return []

        setup

        original_cache_key

        change
      end

      let(:setup) { nil }
      let(:original_cache_key) { joined_cache_key }

      shared_examples_for "changes" do
        before do
          change
        end

        it "the cache key" do
          expect(joined_cache_key).not_to eql(original_cache_key)
        end
      end

      context "for a different project" do
        it_behaves_like "changes" do
          let(:change) { work_package.project = build_stubbed(:project) }
        end
      end

      context "if the project is updated" do
        it_behaves_like "changes" do
          let(:change) { work_package.project.updated_at += 1.hour }
        end
      end

      context "for a different type" do
        it_behaves_like "changes" do
          let(:change) { work_package.type = build_stubbed(:type) }
        end
      end

      context "if the type is updated" do
        it_behaves_like "changes" do
          let(:change) { work_package.type.updated_at += 1.hour }
        end
      end

      context "if the type is switches" do
        it_behaves_like "changes" do
          let(:change) { allow(I18n).to receive(:locale).and_return(:de) }
        end
      end

      context "if the custom_fields change" do
        it_behaves_like "changes" do
          let(:change) do
            allow(work_package)
              .to receive(:available_custom_fields)
              .and_return([build_stubbed(:custom_field)])
          end
        end
      end

      context "if the work_package_done_ratio setting changes" do
        it_behaves_like "changes" do
          let(:setup) do
            allow(Setting)
              .to receive(:work_package_done_ratio)
              .and_return("something")
          end

          let(:change) do
            allow(Setting)
              .to receive(:work_package_done_ratio)
              .and_return("else")
          end
        end
      end

      context "if the users permissions change" do
        it_behaves_like "changes" do
          let(:cache_perms) { %i[view_work_packages edit_work_packages] }
          let(:setup) do
            allow(representer).to receive(:all_permissions_granted_to_user_under_project).and_return(cache_perms)
          end

          let(:change) do
            cache_perms << :manage_versions
          end
        end
      end
    end
  end
end

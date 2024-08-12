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

RSpec.describe API::V3::TimeEntries::Schemas::TimeEntrySchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }

  let(:self_link) { "/a/self/link" }
  let(:embedded) { true }
  let(:new_record) { true }
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:assigned_project) { nil }
  let(:activity) { build_stubbed(:time_entry_activity) }
  let(:time_entry) { build_stubbed(:time_entry) }
  let(:writable_attributes) { %w(spent_on hours project work_package activity comment user) }

  let(:contract) do
    contract = instance_double(new_record ? TimeEntries::CreateContract : TimeEntries::UpdateContract,
                               new_record?: new_record,
                               id: new_record ? nil : 5,
                               project: assigned_project,
                               project_id: project.id,
                               model: time_entry)

    allow(contract)
      .to receive(:writable?) do |attribute|
      writable_attributes.include?(attribute.to_s)
    end

    allow(contract)
      .to receive(:available_custom_fields)
      .and_return([])

    allow(contract)
      .to receive(:assignable_values) do |attribute, _user|
      case attribute
      when :activity
        [activity]
      end
    end

    contract
  end
  let(:representer) do
    described_class.create(contract,
                           self_link:,
                           form_embedded: embedded,
                           current_user:)
  end

  context "generation" do
    subject(:generated) { representer.to_json }

    describe "_type" do
      it "is indicated as Schema" do
        expect(subject).to be_json_eql("Schema".to_json).at_path("_type")
      end
    end

    describe "id" do
      let(:path) { "id" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Integer" }
        let(:name) { I18n.t("attributes.id") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "spentOn" do
      let(:path) { "spentOn" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Date" }
        let(:name) { TimeEntry.human_attribute_name("spent_on") }
        let(:required) { true }
        let(:writable) { true }
      end
    end

    describe "hours" do
      let(:path) { "hours" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Duration" }
        let(:name) { TimeEntry.human_attribute_name("hours") }
        let(:required) { true }
        let(:writable) { true }
      end
    end

    describe "comment" do
      let(:path) { "comment" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Formattable" }
        let(:name) { TimeEntry.human_attribute_name("comment") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "createdAt" do
      let(:path) { "createdAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { TimeEntry.human_attribute_name("created_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "updatedAt" do
      let(:path) { "updatedAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { TimeEntry.human_attribute_name("updated_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "user" do
      let(:path) { "user" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "User" }
        let(:name) { TimeEntry.human_attribute_name("user") }
        let(:required) { true }
        let(:writable) { true }
        let(:location) { "_links" }
      end
    end

    describe "work_package" do
      let(:path) { "workPackage" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "WorkPackage" }
        let(:name) { TimeEntry.human_attribute_name("work_package") }
        let(:required) { false }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      context "if embedding" do
        let(:embedded) { true }

        context "if being a new record" do
          let(:new_record) { true }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) do
              api_v3_paths.time_entries_available_work_packages_on_create
            end
          end
        end

        context "if being an existing record" do
          let(:new_record) { false }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) do
              api_v3_paths.time_entries_available_work_packages_on_edit(contract.id)
            end
          end
        end
      end
    end

    describe "activity" do
      let(:path) { "activity" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "TimeEntriesActivity" }
        let(:name) { TimeEntry.human_attribute_name("activity") }
        let(:has_default) { true }
        let(:required) { false }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      context "if embedding" do
        let(:embedded) { true }

        it_behaves_like "links to and embeds allowed values directly" do
          let(:hrefs) { [activity].map { |value| "/api/v3/time_entries/activities/#{value.id}" } }
        end
      end

      describe "project" do
        let(:path) { "project" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Project" }
          let(:name) { TimeEntry.human_attribute_name("project") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        context "if embedding" do
          let(:embedded) { true }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) do
              api_v3_paths.time_entries_available_projects
            end
          end
        end
      end

      describe "user" do
        let(:path) { "user" }

        it_behaves_like "has basic schema properties" do
          let(:type) { "User" }
          let(:name) { TimeEntry.human_attribute_name("user") }
          let(:required) { true }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        context "if embedding" do
          let(:embedded) { true }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) do
              api_v3_paths.path_for :principals,
                                    filters: [
                                      { status: { operator: "!", values: [Principal.statuses[:locked].to_s] } },
                                      { type: { operator: "=", values: ["User"] } },
                                      { member: { operator: "=", values: [project.id] } }
                                    ]
            end
          end
        end
      end
    end

    context "for a custom value" do
      let(:custom_field) { build_stubbed(:time_entry_custom_field) }
      let(:path) { "customField#{custom_field.id}" }
      let(:writable_attributes) { [custom_field.attribute_name] }

      before do
        allow(contract)
          .to receive(:available_custom_fields)
          .and_return([custom_field])
      end

      it_behaves_like "has basic schema properties" do
        let(:type) { "Formattable" }
        let(:name) { custom_field.name }
        let(:required) { false }
        let(:writable) { true }
      end

      context "with schema not writable" do
        let(:writable_attributes) { [] }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Formattable" }
          let(:name) { custom_field.name }
          let(:required) { false }
          let(:writable) { false }
        end
      end
    end
  end
end

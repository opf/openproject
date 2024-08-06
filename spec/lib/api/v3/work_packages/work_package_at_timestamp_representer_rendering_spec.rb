# -- copyright
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
# ++

require "spec_helper"

# Note: The specs in this file do not attempt to test the properties themselves with all their possible
# variations. This is done in length in the work_package_representer_spec.rb. Instead, the focus of the tests
# here are on the selection of properties.
RSpec.describe API::V3::WorkPackages::WorkPackageAtTimestampRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }
  let(:embed_links) { false }
  let(:timestamps) { nil }
  let(:query) { nil }

  let(:due_date) { Date.current + 5.days }
  let(:start_date) { Date.current - 5.days }
  let(:assigned_to) { build_stubbed(:user) }
  let(:responsible) { build_stubbed(:user) }
  let(:status) { build_stubbed(:status) }
  let(:type) { build_stubbed(:type) }
  let(:priority) { build_stubbed(:priority) }
  let(:version) { build_stubbed(:version) }
  let(:parent) do
    build_stubbed(:work_package).tap do |wp|
      allow(wp)
        .to receive(:visible?)
        .and_return(true)
    end
  end
  let(:project) { build_stubbed(:project) }
  let(:custom_field) do
    build_stubbed(:string_wp_custom_field,
                  name: "String CF",
                  types: project.types,
                  projects: [project])
  end

  let(:available_custom_fields) { [custom_field] }
  let(:custom_value) do
    build_stubbed(:custom_value,
                  custom_field:,
                  value: "This is a string value")
  end

  let(:work_package) do
    build_stubbed(:work_package,
                  project:,
                  status:,
                  due_date:,
                  start_date:,
                  assigned_to:,
                  type:,
                  priority:,
                  version:,
                  parent:,
                  responsible:).tap do |wp|
      allow(wp)
        .to receive(:respond_to?)
              .and_call_original
      allow(wp)
        .to receive(:respond_to?)
              .with(:wrapped?)
              .and_return(true)
      allow(wp)
        .to receive_messages(available_custom_fields:, custom_field_values: [custom_value])
    end
  end
  let(:timestamp) { Timestamp.new(1.day.ago) }

  let(:attributes_changed_to_baseline) { work_package.attributes.keys + ["custom_field_#{custom_field.id}"] }
  let(:exists_at_timestamp) { true }
  let(:with_query) { true }
  let(:matches_filters_at_timestamp) { true }
  let(:exists_at_current_timestamp) { true }

  let(:model) do
    work_package.tap do |model|
      # Mimicking the eager loading wrapper
      without_partial_double_verification do
        allow(model)
          .to receive_messages(timestamp:, attributes_changed_to_baseline:,
                               exists_at_timestamp?: exists_at_timestamp,
                               with_query?: with_query,
                               matches_filters_at_timestamp?: matches_filters_at_timestamp,
                               exists_at_current_timestamp?: exists_at_current_timestamp)
      end
    end
  end

  let(:representer) do
    described_class.create(model, current_user:)
  end

  subject(:generated) { representer.to_json }

  context "with all supported properties requested" do
    let(:expected_json) do
      {
        "subject" => work_package.subject,
        "startDate" => work_package.start_date,
        "dueDate" => work_package.due_date,
        "customField#{custom_field.id}" => "This is a string value",
        "_meta" => {
          "matchesFilters" => true,
          "exists" => true,
          "timestamp" => timestamp.to_s
        },
        "_links" => {
          "assignee" => {
            "href" => api_v3_paths.user(assigned_to.id),
            "title" => assigned_to.name
          },
          "responsible" => {
            "href" => api_v3_paths.user(responsible.id),
            "title" => responsible.name
          },
          "project" => {
            "href" => api_v3_paths.project(project.id),
            "title" => project.name
          },
          "status" => {
            "href" => api_v3_paths.status(status.id),
            "title" => status.name
          },
          "type" => {
            "href" => api_v3_paths.type(type.id),
            "title" => type.name
          },
          "priority" => {
            "href" => api_v3_paths.priority(priority.id),
            "title" => priority.name
          },
          "version" => {
            "href" => api_v3_paths.version(version.id),
            "title" => version.name
          },
          "parent" => {
            "href" => api_v3_paths.work_package(parent.id),
            "title" => parent.subject
          },
          "self" => {
            "href" => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            "title" => work_package.subject
          },
          "schema" => {
            "href" => api_v3_paths.work_package_schema(work_package.project_id, work_package.type_id)
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context "with a subset of supported properties" do
    let(:attributes_changed_to_baseline) { %w[start_date assigned_to_id version_id] }

    let(:expected_json) do
      {
        "startDate" => work_package.start_date,
        "_meta" => {
          "matchesFilters" => true,
          "exists" => true,
          "timestamp" => timestamp.to_s
        },
        "_links" => {
          "assignee" => {
            "href" => api_v3_paths.user(assigned_to.id),
            "title" => assigned_to.name
          },
          "version" => {
            "href" => api_v3_paths.version(version.id),
            "title" => version.name
          },
          "self" => {
            "href" => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            "title" => work_package.subject
          },
          "schema" => {
            "href" => api_v3_paths.work_package_schema(work_package.project_id, work_package.type_id)
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context "without a linked property" do
    let(:attributes_changed_to_baseline) { %w[subject start_date] }

    let(:expected_json) do
      {
        "subject" => work_package.subject,
        "startDate" => work_package.start_date,
        "_meta" => {
          "matchesFilters" => true,
          "exists" => true,
          "timestamp" => timestamp.to_s
        },
        "_links" => {
          "self" => {
            "href" => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            "title" => work_package.subject
          },
          "schema" => {
            "href" => api_v3_paths.work_package_schema(work_package.project_id, work_package.type_id)
          }
        }
      }.to_json
    end

    it "renders with only `self` in links" do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context "with a nil value for a linked property" do
    let(:assigned_to) { nil }

    let(:attributes_changed_to_baseline) { %w[assigned_to_id] }

    let(:expected_json) do
      {
        "_meta" => {
          "matchesFilters" => true,
          "exists" => true,
          "timestamp" => timestamp.to_s
        },
        "_links" => {
          "assignee" => {
            "href" => nil
          },
          "self" => {
            "href" => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            "title" => work_package.subject
          },
          "schema" => {
            "href" => api_v3_paths.work_package_schema(work_package.project_id, work_package.type_id)
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context "without the timestamp being in the attributes_by_timestamp collection" do
    let(:attributes_changed_to_baseline) { %w[] }

    let(:exists_at_timestamp) { false }

    let(:matches_filters_at_timestamp) { false }

    let(:expected_json) do
      {
        "_meta" => {
          "matchesFilters" => false,
          "exists" => false,
          "timestamp" => timestamp.to_s
        }
      }.to_json
    end

    it "has only the meta noting that the wp did not exist" do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context "with a milestone typed work package" do
    let(:type) { build_stubbed(:type_milestone) }
    # On a milestone, both dates will be the same
    let(:start_date) { due_date }
    let(:attributes_changed_to_baseline) { %w[start_date] }

    let(:expected_json) do
      {
        "date" => work_package.start_date,
        "_meta" => {
          "matchesFilters" => true,
          "exists" => true,
          "timestamp" => timestamp.to_s
        },
        "_links" => {
          "self" => {
            "href" => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            "title" => work_package.subject
          },
          "schema" => {
            "href" => api_v3_paths.work_package_schema(work_package.project_id, work_package.type_id)
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context "with only one attribute changed to baseline but with the work package not existing (not visible) at current time" do
    # Note that while the work package in this test is configured to not exist at the current time (not visible),
    # the timestamp passed in isn't the current time. So this represents a case where the work package is no longer
    # visible but was visible at the timestamp provided.
    # The API response would look like this:
    #   {
    #     "_type"=>"WorkPackage",
    #     "_meta"=>{ "exists"=>false, "timestamp"=>"PT0S", "matchesFilters"=>false },
    #     "id"=>101,
    #     "_embedded"=>
    #      {
    #        "attributesByTimestamp"=>
    #          [
    #            # The part rendered by this representer
    #            {
    #             "_meta"=>{"exists"=>true, "timestamp"=>"2015-01-01T00:00:00Z", "matchesFilters"=>true},
    #             "subject"=>"The original work package",
    #             "startDate"=>nil,
    #             "dueDate"=>nil,
    #             "_links"=> {
    #                  "self"=>{"href"=>"/api/v3/work_packages/101?timestamps=2015-01-01T00%3A00%3A00Z",
    #                           "title"=>"The original work package"},
    #                  "schema"=>{"href"=>"/api/v3/work_packages/schemas/85-63"},
    #                  "type"=>{"href"=>"/api/v3/types/63", "title"=>"None"},
    #                  "priority"=>{"href"=>"/api/v3/priorities/3", "title"=>"Priority 1"},
    #                  "project"=>{"href"=>"/api/v3/projects/85", "title"=>"My Project No. 2"},
    #                  "status"=>{"href"=>"/api/v3/statuses/3", "title"=>"status 1"},
    #                  "responsible"=>{"href"=>nil},
    #                  "assignee"=>{"href"=>"/api/v3/users/68", "title"=>"Bob Bobbit"},
    #                  "parent"=>{"href"=>"/api/v3/work_packages/102"}
    #                  "version"=>{"href"=>nil}
    #               }
    #            },
    #            {
    #              "_meta"=>{"exists"=>false, "timestamp"=>"PT0S", "matchesFilters"=>false}
    #            }
    #          ]
    #      },
    #     "_links"=>{"self"=>{"href"=>"/api/v3/work_packages/101?timestamps=2015-01-01T00%3A00%3A00Z%2C2023-05-25T15%3A21%3A28Z"}}
    #   }
    # where the outer resource, the actual WorkPackage resource, is labeled to not exist ( _meta/exists => false ) but
    # the attributesByTimestamp for that timestamp would be labeled as existing
    # ( _embedded/attributesByTimestamp/0/_meta/exists => true ).
    let(:attributes_changed_to_baseline) { %w[start_date] }
    let(:exists_at_current_timestamp) { false }

    let(:expected_json) do
      {
        "subject" => work_package.subject,
        "startDate" => work_package.start_date,
        "dueDate" => work_package.due_date,
        "_meta" => {
          "matchesFilters" => true,
          "exists" => true,
          "timestamp" => timestamp.to_s
        },
        "_links" => {
          "assignee" => {
            "href" => api_v3_paths.user(assigned_to.id),
            "title" => assigned_to.name
          },
          "responsible" => {
            "href" => api_v3_paths.user(responsible.id),
            "title" => responsible.name
          },
          "project" => {
            "href" => api_v3_paths.project(project.id),
            "title" => project.name
          },
          "status" => {
            "href" => api_v3_paths.status(status.id),
            "title" => status.name
          },
          "type" => {
            "href" => api_v3_paths.type(type.id),
            "title" => type.name
          },
          "priority" => {
            "href" => api_v3_paths.priority(priority.id),
            "title" => priority.name
          },
          "version" => {
            "href" => api_v3_paths.version(version.id),
            "title" => version.name
          },
          "parent" => {
            "href" => api_v3_paths.work_package(parent.id),
            "title" => parent.subject
          },
          "self" => {
            "href" => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            "title" => work_package.subject
          },
          "schema" => {
            "href" => api_v3_paths.work_package_schema(work_package.project_id, work_package.type_id)
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end
end

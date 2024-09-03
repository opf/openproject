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

RSpec.describe API::V3::WorkPackages::WorkPackageCollectionRepresenter do
  include API::V3::Utilities::PathHelper
  create_shared_association_defaults_for_work_package_factory

  let(:self_base_link) { "/api/v3/example" }
  let(:work_packages) do
    created_work_packages
    WorkPackage.all
  end
  let(:created_work_packages) { create_list(:work_package, total) }
  let(:first_wp) { work_packages.first }
  let(:user) { build_stubbed(:user) }

  let(:query_params) { {} }
  let(:groups) { nil }
  let(:total_sums) { nil }
  let(:project) { nil }

  let(:page_parameter) { nil }
  let(:page_size_parameter) { nil }
  let(:default_page_size) { 30 }
  let(:total) { 5 }
  let(:embed_schemas) { false }
  let(:timestamps) { nil }
  let(:query) { nil }
  # nil in this context means "don't care". The user will be allowed any action
  let(:permissions) { nil }

  let(:representer) do
    described_class.new(
      work_packages,
      self_link: self_base_link,
      query_params:,
      project:,
      groups:,
      total_sums:,
      page: page_parameter,
      per_page: page_size_parameter,
      current_user: user,
      embed_schemas:,
      timestamps:,
      query:
    )
  end
  let(:collection_inner_type) { "WorkPackage" }

  current_user { user }

  before do
    mock_permissions_for(user) do |mock|
      if permissions && project
        mock.allow_in_project *permissions, project:
      else
        mock.allow_everything
      end
    end
  end

  subject(:collection) { representer.to_json }

  describe "_links" do
    describe "self" do
      describe "when providing timestamps" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
        let(:absolute_timestamp_strings) { timestamps.collect(&:absolute) }
        let(:absolute_timestamps_query_param) { { timestamps: absolute_timestamp_strings.join(",") }.to_query }

        it "has the absolute timestamps within the self link" do
          Timecop.freeze do
            expect(subject)
              .to include_json(absolute_timestamps_query_param.to_json)
              .at_path("_links/self/href")
          end
        end
      end

      describe "when providing only the current timestamp" do
        let(:timestamps) { [Timestamp.parse("PT0S")] }

        it "has no timestamps within the self link" do
          Timecop.freeze do
            expect(subject)
              .not_to include_json("timestamps".to_json)
              .at_path("_links/self/href")
          end
        end
      end
    end

    describe "representations" do
      context "when outside of a project and the user has the export_work_packages permission" do
        let(:query_params) { { foo: "bar" } }

        let(:expected) do
          expected_query_params = query_params.merge(pageSize: 30, offset: 1)
          JSON.parse([
            {
              href: work_packages_path({ format: "pdf", pdf_export_type: "table" }.merge(expected_query_params)),
              type: "application/pdf",
              identifier: "pdf",
              title: I18n.t("export.format.pdf_overview_table")
            },
            {
              href: work_packages_path({ format: "pdf", pdf_export_type: "report", show_images: true }
                                         .merge(expected_query_params)),
              identifier: "pdf-with-descriptions",
              type: "application/pdf",
              title: I18n.t("export.format.pdf_report_with_images")
            },
            {
              href: work_packages_path({ format: "pdf", pdf_export_type: "report" }.merge(expected_query_params)),
              identifier: "pdf-descr",
              type: "application/pdf",
              title: I18n.t("export.format.pdf_report")
            },
            {
              href: work_packages_path({ format: "csv" }.merge(expected_query_params)),
              type: "text/csv",
              identifier: "csv",
              title: I18n.t("export.format.csv")
            },
            {
              href: work_packages_path({ format: "atom" }.merge(expected_query_params)),
              identifier: "atom",
              type: "application/atom+xml",
              title: I18n.t("export.format.atom")
            }
          ].to_json)
        end

        it "has a collection of export formats" do
          actual = JSON.parse(subject).dig("_links", "representations")

          # As plugins might extend the representation, we only
          # check for a subset
          expect(actual)
            .to include(*expected)
        end
      end

      context "when inside of a project and the user has the export_work_packages permission" do
        let(:project) { build_stubbed(:project) }

        let(:expected) do
          expected_query_params = query_params.merge(pageSize: 30, offset: 1)
          JSON.parse([
            {
              href: project_work_packages_path(project, { format: "pdf", pdf_export_type: "table" }.merge(expected_query_params)),
              type: "application/pdf",
              identifier: "pdf",
              title: I18n.t("export.format.pdf_overview_table")
            },
            {
              href: project_work_packages_path(project, { format: "pdf", pdf_export_type: "report", show_images: true }
                                                          .merge(expected_query_params)),
              type: "application/pdf",
              identifier: "pdf-with-descriptions",
              title: I18n.t("export.format.pdf_report_with_images")
            },
            {
              href: project_work_packages_path(project,
                                               { format: "pdf", pdf_export_type: "report" }.merge(expected_query_params)),
              type: "application/pdf",
              identifier: "pdf-descr",
              title: I18n.t("export.format.pdf_report")
            },
            {
              href: project_work_packages_path(project, { format: "csv" }.merge(expected_query_params)),
              identifier: "csv",
              type: "text/csv",
              title: I18n.t("export.format.csv")
            },
            {
              href: project_work_packages_path(project, { format: "atom" }.merge(expected_query_params)),
              identifier: "atom",
              type: "application/atom+xml",
              title: I18n.t("export.format.atom")
            }
          ].to_json)
        end

        it "has a project scoped collection of export formats if inside a project" do
          actual = JSON.parse(subject).dig("_links", "representations")

          # As plugins might extend the representation, we only
          # check for a subset
          expect(actual)
            .to include(*expected)
        end
      end

      context "when the user lacks the export_work_packages permission" do
        before do
          mock_permissions_for(user, &:forbid_everything)
        end

        it "has no export links" do
          expect(collection)
            .not_to have_json_path("_links/representations")
        end
      end
    end

    describe "customFields" do
      let(:project) { build_stubbed(:project) }

      context "with the permission to select custom fields" do
        before do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :select_custom_fields, project:
          end
        end

        it "has a link to set the custom fields for that project" do
          expected = {
            href: project_settings_custom_fields_path(project),
            type: "text/html",
            title: "Custom fields"
          }

          expect(collection)
            .to be_json_eql(expected.to_json)
                  .at_path("_links/customFields")
        end
      end

      context "without the permission to select custom fields" do
        before do
          mock_permissions_for(user, &:forbid_everything)
        end

        it "has no link to set the custom fields for that project" do
          expect(collection).not_to have_json_path("_links/customFields")
        end
      end

      context "when not in a project" do
        let(:project) { nil }

        it "has no link to set the custom fields for that project" do
          expect(collection).not_to have_json_path("_links/customFields")
        end
      end
    end
  end

  describe "_embedded" do
    describe "elements" do
      context "for a work package that is not visible" do
        let(:total) { 1 }
        let(:permissions) { [] }
        let(:project) { created_work_packages.first.project }

        it "renders a reduced WorkPackage element" do
          expect(collection)
            .to be_json_eql(
              {
                _type: "WorkPackage",
                _links: {
                  self: {
                    href: api_v3_paths.work_package(first_wp.id)
                  }
                }
              }.to_json
            ).at_path("_embedded/elements/0")
        end
      end
    end
  end

  it "does not render groups" do
    expect(collection).not_to have_json_path("groups")
  end

  it "does not render sums" do
    expect(collection).not_to have_json_path("totalSums")
  end

  it "has a schemas link" do
    # All work packages in the collection are from the same project and have the same type
    path = api_v3_paths.work_package_schemas [first_wp.project_id, first_wp.type_id]

    expect(collection)
      .to be_json_eql(path.to_json)
      .at_path("_links/schemas/href")
  end

  describe "ancestors" do
    it "are being eager loaded" do
      representer.represented.each do |wp|
        expect(wp.work_package_ancestors).to be_a(Array)
        expect(wp.ancestors).to eq(wp.work_package_ancestors)
      end
    end
  end

  context "when the user has the edit_work_package permission in any project" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project *permissions, project: build_stubbed(:project) # any project
      end
    end

    context "when allowed" do
      let(:permissions) { [:edit_work_packages] }

      it "has a link to templated edit work_package" do
        expect(collection)
          .to be_json_eql(api_v3_paths.work_package_form("{work_package_id}").to_json)
          .at_path("_links/editWorkPackage/href")
      end
    end

    context "when not allowed" do
      let(:permissions) { [] }

      it "has no link to templated edit work_package" do
        expect(collection).not_to have_json_path("_links/editWorkPackage")
      end
    end
  end

  context "when the user has the add_work_package permission in any project" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project :add_work_packages, project: build_stubbed(:project) # any project
      end
    end

    it "has a link to create work_packages" do
      expect(collection)
        .to be_json_eql(api_v3_paths.create_work_package_form.to_json)
        .at_path("_links/createWorkPackage/href")
    end

    it "declares to use POST to create work_packages" do
      expect(collection)
        .to be_json_eql(:post.to_json)
        .at_path("_links/createWorkPackage/method")
    end

    it "has a link to create work_packages immediately" do
      expect(collection)
        .to be_json_eql(api_v3_paths.work_packages.to_json)
        .at_path("_links/createWorkPackageImmediate/href")
    end

    it "declares to use POST to create work_packages immediately" do
      expect(collection)
        .to be_json_eql(:post.to_json)
        .at_path("_links/createWorkPackageImmediate/method")
    end

    context "when in project context" do
      let(:project) { build_stubbed(:project) }

      it "has no link to create work_packages" do
        expect(collection)
          .not_to have_json_path("_links/createWorkPackage")
      end

      it "has no link to create work_packages immediately" do
        expect(collection)
          .not_to have_json_path("_links/createWorkPackageImmediate")
      end
    end
  end

  context "when the user lacks the add_work_package permission" do
    before do
      mock_permissions_for(user, &:forbid_everything)
    end

    it "has no link to create work_packages" do
      expect(collection)
        .not_to have_json_path("_links/createWorkPackage")
    end

    it "has no link to create work_packages immediately" do
      expect(collection)
        .not_to have_json_path("_links/createWorkPackageImmediate")
    end
  end

  context "with a magic page size" do
    let(:page_size_parameter) { -1 }

    it_behaves_like "offset-paginated APIv3 collection" do
      let(:page) { 1 }
      let(:page_size) {  Setting.apiv3_max_page_size }
      let(:actual_count) { 5 }
      let(:collection_type) { "WorkPackageCollection" }
    end
  end

  context "with a limited page size" do
    let(:page_size_parameter) { 2 }

    context "when on the first page" do
      it_behaves_like "offset-paginated APIv3 collection" do
        let(:page) { 1 }
        let(:page_size) { page_size_parameter }
        let(:actual_count) { page_size_parameter }
        let(:collection_type) { "WorkPackageCollection" }

        it_behaves_like "links to next page by offset"
      end

      it_behaves_like "has no link" do
        let(:link) { "previousByOffset" }
      end
    end

    context "when on the last page" do
      let(:page_parameter) { 3 }

      it_behaves_like "offset-paginated APIv3 collection" do
        let(:page) { 3 }
        let(:page_size) { page_size_parameter }
        let(:actual_count) { 1 }
        let(:collection_type) { "WorkPackageCollection" }

        it_behaves_like "links to previous page by offset"
      end

      it_behaves_like "has no link" do
        let(:link) { "nextByOffset" }
      end
    end
  end

  context "when passing a query_params hash" do
    let(:query_params) { { a: "b", b: "c" } }

    it_behaves_like "has an untitled link" do
      let(:link) { "self" }
      let(:href) { "/api/v3/example?a=b&b=c&offset=1&pageSize=30" }
    end
  end

  context "when passing groups" do
    let(:groups) do
      group = { "custom" => "object" }

      without_partial_double_verification do
        allow(group).to receive(:has_sums?).and_return false
      end

      [group]
    end

    it "renders the groups object as json" do
      expect(collection).to be_json_eql(groups.to_json).at_path("groups")
    end
  end

  context "when passing groups with sums" do
    let(:groups) do
      group = { "sums" => {} }

      without_partial_double_verification do
        allow(group).to receive(:has_sums?).and_return true
      end

      [group]
    end

    it "renders the groups object as json" do
      expect(collection).to be_json_eql(groups.to_json).at_path("groups")
    end

    it "has a link to the sums schema" do
      expected = {
        href: api_v3_paths.work_package_sums_schema
      }

      expect(collection).to be_json_eql(expected.to_json).at_path("_links/sumsSchema")
    end
  end

  context "when passing sums" do
    let(:total_sums) { OpenStruct.new(estimated_hours: 1) }

    it "renders the groups object as json" do
      expected = { "estimatedTime" => "PT1H",
                   "remainingTime" => nil,
                   "storyPoints" => nil }
      expect(collection).to be_json_eql(expected.to_json).at_path("totalSums")
    end

    it "has a link to the sums schema" do
      expected = {
        href: api_v3_paths.work_package_sums_schema
      }

      expect(collection).to be_json_eql(expected.to_json).at_path("_links/sumsSchema")
    end
  end

  context "when passing schemas" do
    let(:embed_schemas) { true }

    it "embeds a schema collection", :aggregate_failures do
      expected_path = api_v3_paths.work_package_schema(first_wp.project.id,
                                                       first_wp.type.id)

      expect(collection)
        .to be_json_eql(expected_path.to_json)
        .at_path("_embedded/schemas/_embedded/elements/0/_links/self/href")

      # All work packages share the same project and type
      expect(collection)
        .to have_json_size(1)
              .at_path("_embedded/schemas/_embedded/elements")
    end

    context "when having timestamps leads to a different schema at the baseline time (because of a different type)",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:other_type) { create(:type) }
      let(:timestamps) { [Timestamp.parse("2023-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
      let!(:member) do
        create(:member,
               user: current_user,
               project: first_wp.project,
               roles: create_list(:project_role, 1, permissions: [:view_work_packages]))
      end
      let(:created_work_packages) do
        # Let the work package behave as if it used to have a different type forcing the inclusion of
        # another schema and set the creation date to be before the baseline time.
        create_list(:work_package,
                    1,
                    subject: "Some new subject",
                    journals: {
                      DateTime.parse("2022-01-01T00:00:00Z") => { type_id: other_type.id },
                      1.day.ago => {}
                    })
      end

      it "embeds a schema collection", :aggregate_failures do
        expect(collection)
          .to have_json_size(2)
                .at_path("_embedded/schemas/_embedded/elements")

        expected_former_path = api_v3_paths.work_package_schema(first_wp.project.id,
                                                                other_type.id)
        expect(collection)
          .to be_json_eql(expected_former_path.to_json)
                .at_path("_embedded/schemas/_embedded/elements/0/_links/self/href")

        expected_current_path = api_v3_paths.work_package_schema(first_wp.project.id,
                                                                 first_wp.type.id)
        expect(collection)
          .to be_json_eql(expected_current_path.to_json)
                .at_path("_embedded/schemas/_embedded/elements/1/_links/self/href")
      end
    end
  end

  context "when passing timestamps" do
    let(:work_package) do
      create(:work_package,
             subject: "The current work package",
             assigned_to: current_user,
             project:,
             journals: {
               baseline_time - 1.day => { subject: "The original work package" },
               1.day.ago => {}
             })
    end
    let(:created_work_packages) { [work_package] }
    let(:original_journal) { work_package.journals.first }
    let(:current_journal) { work_package.journals.last }
    let(:baseline_time) { "2022-01-01".to_time }
    let(:project) { create(:project) }
    let(:current_user) do
      create(:user,
             firstname: "user",
             lastname: "1",
             member_with_permissions: { project => %i[view_work_packages] })
    end

    shared_examples_for "includes the properties of the current work package" do
      it "includes the properties of the current work package" do
        expect(collection)
          .to be_json_eql("The current work package".to_json)
          .at_path("_embedded/elements/0/subject")
      end
    end

    shared_examples_for "embeds the properties of the baseline work package" do
      it "embeds the properties of the baseline work package in attributesByTimestamp" do
        expect(collection)
          .to be_json_eql("The original work package".to_json)
          .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
      end

      it "embeds the link to the baseline work package in attributesByTimestamp" do
        expect(collection)
          .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
          .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/self/href")
      end
    end

    shared_examples_for "has the absolute timestamps within the self link" do
      let(:absolute_timestamp_strings) { timestamps.collect(&:absolute) }
      let(:absolute_timestamps_query_param) { { timestamps: absolute_timestamp_strings.join(",") }.to_query }

      it "has the absolute timestamps within the self link" do
        expect(subject)
          .to include_json(absolute_timestamps_query_param.to_json)
          .at_path("_embedded/elements/0/_links/self/href")
      end
    end

    context "with baseline and current timestamps" do
      let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }

      it_behaves_like "includes the properties of the current work package"
      it_behaves_like "embeds the properties of the baseline work package"
      it_behaves_like "has the absolute timestamps within the self link"
    end

    context "with current timestamp only" do
      let(:timestamps) { [Timestamp.parse("PT0S")] }

      it_behaves_like "includes the properties of the current work package"

      it "has no timestamps within the self link" do
        expect(subject)
          .not_to include_json("timestamps".to_json)
          .at_path("_embedded/elements/0/_links/self/href")
      end
    end

    context "with baseline timestamp only" do
      let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

      it "includes the properties of the baseline work package" do
        expect(collection)
          .to be_json_eql("The original work package".to_json)
          .at_path("_embedded/elements/0/subject")
      end

      it_behaves_like "has the absolute timestamps within the self link"
    end

    context "with empty timestamp" do
      let(:timestamps) { [] }

      it_behaves_like "includes the properties of the current work package"

      it "has no timestamps within the self link" do
        expect(subject)
          .not_to include_json("timestamps".to_json)
          .at_path("_embedded/elements/0/_links/self/href")
      end
    end

    context "when passing a query" do
      let(:search_term) { "original" }
      let(:query) do
        build(:query, user: current_user, project: nil).tap do |query|
          query.filters.clear
          query.add_filter "subject", "~", search_term
          query.timestamps = timestamps
        end
      end

      context "with baseline and current timestamps", with_ee: %i[baseline_comparison] do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }

        describe "attributesByTimestamp" do
          it "states whether the work package matches the query filters at the timestamp" do
            expect(subject)
              .to be_json_eql(true.to_json)
              .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
            expect(subject)
              .to be_json_eql(false.to_json)
              .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
          end
        end
      end
    end
  end
end

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
require "rack/test"

RSpec.describe "API v3 Work package resource",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  create_shared_association_defaults_for_work_package_factory

  let(:work_package) do
    create(:work_package,
           project_id: project.id,
           description: "lorem ipsum")
  end
  let(:project) do
    create(:project, identifier: "test_project", public: false)
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  describe "GET /api/v3/work_packages" do
    subject do
      get path
      last_response
    end

    let(:path) { api_v3_paths.work_packages }
    let(:other_work_package) { create(:work_package) }
    let(:work_packages) { [work_package, other_work_package] }

    before do
      work_packages
    end

    it "succeeds" do
      expect(subject.status).to be 200
    end

    it "returns visible work packages" do
      expect(subject.body).to be_json_eql(1.to_json).at_path("total")
    end

    it "embeds the work package schemas" do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.work_package_schema(project.id, work_package.type.id).to_json)
              .at_path("_embedded/schemas/_embedded/elements/0/_links/self/href")
    end

    context "with filtering by typeahead" do
      before { get path }

      subject { last_response }

      let(:path) { api_v3_paths.path_for :work_packages, filters: }
      let(:filters) do
        [
          {
            typeahead: {
              operator: "**",
              values: "lorem ipsum"
            }
          }
        ]
      end

      let(:lorem_ipsum_work_package) { create(:work_package, project:, subject: "lorem ipsum") }
      let(:lorem_project) { create(:project, members: { current_user => role }, name: "lorem other") }
      let(:ipsum_work_package) { create(:work_package, subject: "other ipsum", project: lorem_project) }
      let(:other_lorem_work_package) { create(:work_package, subject: "lorem", project: lorem_project) }
      let(:work_packages) { [work_package, lorem_ipsum_work_package, ipsum_work_package, other_lorem_work_package] }

      it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [lorem_ipsum_work_package, ipsum_work_package] }
      end
    end

    context "with a user not seeing any work packages" do
      # Create a public project so that the non-member permission has something to attach to
      let!(:public_project) { create(:project, public: true, active: true) }

      let(:current_user) { create(:user) }
      let(:non_member_permissions) { [:view_work_packages] }

      include_context "with non-member permissions from non_member_permissions"

      it "succeeds" do
        expect(subject.status).to be 200
      end

      it "returns no work packages" do
        expect(subject.body).to be_json_eql(0.to_json).at_path("total")
      end

      context "with the user not allowed to see work packages in general" do
        let(:non_member_permissions) { [] }

        before { get path }

        it_behaves_like "unauthorized access"
      end
    end

    describe "encoded query props" do
      before { get path }

      subject { last_response }

      let(:props) do
        eprops = {
          filters: [{ id: { operator: "=", values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
          sortBy: [%w(id asc)].to_json,
          pageSize: 1
        }.to_json

        {
          eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
        }.to_query
      end
      let(:path) { "#{api_v3_paths.work_packages}?#{props}" }
      let(:other_visible_work_package) do
        create(:work_package,
               project:)
      end
      let(:another_visible_work_package) do
        create(:work_package,
               project:)
      end

      let(:work_packages) { [work_package, other_work_package, other_visible_work_package, another_visible_work_package] }

      it "succeeds" do
        expect(subject.status)
          .to be 200
      end

      it "returns visible and filtered work packages" do
        expect(subject.body)
          .to be_json_eql(2.to_json)
                .at_path("total")

        # because of the page size
        expect(subject.body)
          .to be_json_eql(1.to_json)
                .at_path("count")

        expect(subject.body)
          .to be_json_eql(work_package.id.to_json)
                .at_path("_embedded/elements/0/id")
      end

      context "without zlibbed" do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: "=", values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Base64.encode64(eprops)
          }.to_query
        end

        it_behaves_like "param validation error"
      end

      context "non json encoded" do
        let(:props) do
          eprops = "some non json string"

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like "param validation error"
      end

      context "non base64 encoded" do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: "=", values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Zlib::Deflate.deflate(eprops)
          }.to_query
        end

        it_behaves_like "param validation error"
      end

      context "non hash" do
        let(:props) do
          eprops = [{
            filters: [{ id: { operator: "=",
                              values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }].to_json

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like "param validation error"
      end
    end

    context "when providing timestamps", with_ee: %i[baseline_comparison] do
      subject do
        get path
        last_response
      end

      let(:timestamps) { [Timestamp.parse("2015-01-01T00:00:00Z"), Timestamp.now] }
      let(:timestamps_param) { CGI.escape(timestamps.join(",")) }
      let(:path) { "#{api_v3_paths.work_packages}?timestamps=#{timestamps_param}" }
      let(:baseline_time) { timestamps.first.to_time }
      let(:created_at) { baseline_time - 1.day }

      let!(:work_package) do
        create(:work_package,
               created_at:,
               subject: "The current work package",
               assigned_to: current_user,
               project:,
               journals: {
                 created_at => { subject: "The original work package" },
                 1.day.ago => {}
               })
      end

      let(:custom_field) do
        create(:string_wp_custom_field,
               name: "String CF",
               types: project.types,
               projects: [project])
      end

      let(:custom_value) do
        create(:custom_value,
               custom_field:,
               customized: work_package,
               value: "This the current value")
      end

      let(:original_journal) { work_package.journals.first }
      let(:current_journal) { work_package.journals.last }

      def create_customizable_journal(journal:, custom_field:, value:)
        create(:journal_customizable_journal,
               journal:,
               custom_field:,
               value:)
      end

      it "succeeds" do
        expect(subject.status).to be 200
      end

      it "embeds the attributesByTimestamp" do
        expect(subject.body)
          .to be_json_eql("The original work package".to_json)
          .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
        expect(subject.body)
          .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
      end

      it "does not embed the attributes in attributesByTimestamp if they are the same as the current attributes" do
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/description")
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/2/description")
      end

      it "has the current attributes as attributes" do
        expect(subject.body)
          .to be_json_eql("The current work package".to_json)
          .at_path("_embedded/elements/0/subject")
      end

      it "has an embedded link to the baseline work package" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
          .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/self/href")
      end

      it "has the absolute timestamps within the self links of the elements" do
        Timecop.freeze do
          expect(subject.body)
            .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.map(&:absolute)).to_json)
            .at_path("_embedded/elements/0/_links/self/href")
        end
      end

      it "has the absolute timestamps within the collection self link" do
        Timecop.freeze do
          expect(subject.body)
            .to include_json({ timestamps: api_v3_paths.timestamps_to_param_value(timestamps.map(&:absolute)) }.to_query.to_json)
            .at_path("_links/self/href")
        end
      end

      it "has no redundant timestamp attribute in the main section" do
        # The historic work packages have a timestamp attribute. But we do not expose that here
        # because the timestamp is already given in the _meta section.
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/timestamp")
      end

      it "has no redundant timestamp attribute in the attributesByTimestamp" do
        # The historic work packages have a timestamp attribute. But we do not expose that here
        # because the timestamp is already given in the _meta section.
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/timestamp")
      end

      it "has the relative timestamps within the _meta timestamps" do
        expect(subject.body)
          .to be_json_eql("2015-01-01T00:00:00Z".to_json)
          .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
        expect(subject.body)
          .to be_json_eql("PT0S".to_json)
          .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
        expect(subject.body)
          .to be_json_eql("PT0S".to_json)
          .at_path("_embedded/elements/0/_meta/timestamp")
      end

      context "when a custom value changes" do
        before do
          custom_value
          create_customizable_journal(journal: original_journal, custom_field:, value: "Original value")
          create_customizable_journal(journal: current_journal, custom_field:, value: custom_value.value)
        end

        it "embeds the custom fields in the attributesByTimestamp" do
          expect(subject.body)
            .to be_json_eql("Original value".to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/customField#{custom_field.id}")
          expect(subject.body)
            .to be_json_eql("This the current value".to_json)
                  .at_path("_embedded/elements/0/customField#{custom_field.id}")
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/customField#{custom_field.id}")
        end

        it "includes a custom field description in the schema" do
          expect(subject.body)
            .to be_json_eql(custom_field.name.to_json)
                  .at_path("_embedded/schemas/_embedded/elements/0/customField#{custom_field.id}/name")
        end
      end

      context "when a link type custom value changes" do
        let(:original_user) { create(:user, member_with_roles: { project => role }) }
        let(:custom_field) do
          create(:user_wp_custom_field,
                 name: "User CF",
                 types: project.types,
                 projects: [project])
        end

        let(:custom_value) do
          create(:custom_value,
                 custom_field:,
                 customized: work_package,
                 value: current_user.id)
        end

        before do
          custom_value
          create_customizable_journal(journal: original_journal, custom_field:, value: original_user.id)
          create_customizable_journal(journal: current_journal, custom_field:, value: custom_value.value)
        end

        it "embeds the custom fields in the attributesByTimestamp" do
          expect(subject.body)
            .to be_json_eql(original_user.name.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/customField#{custom_field.id}/title")
          expect(subject.body)
            .to be_json_eql(current_user.name.to_json)
                  .at_path("_embedded/elements/0/_links/customField#{custom_field.id}/title")
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_links/customField#{custom_field.id}")
        end

        it "includes a custom field description in the schema" do
          expect(subject.body)
            .to be_json_eql(custom_field.name.to_json)
                  .at_path("_embedded/schemas/_embedded/elements/0/customField#{custom_field.id}/name")
        end
      end

      context "when there is a custom value in the past but not in the now as the custom field has been destroyed" do
        before do
          create_customizable_journal(journal: original_journal, custom_field:, value: "Original value")
          custom_field.destroy
        end

        it "does not embed the custom fields in the attributesByTimestamp" do
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/customField#{custom_field.id}")
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/customField#{custom_field.id}")
        end
      end

      context "when there is a custom value in the past but not in the now" \
              "as the custom field has been disabled for the project" do
        before do
          create_customizable_journal(journal: original_journal, custom_field:, value: "Original value")
          project.update(work_package_custom_fields: [])
        end

        it "does not embed the custom fields in the attributesByTimestamp" do
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/customField#{custom_field.id}")
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/customField#{custom_field.id}")
        end
      end

      context "when there is a custom value now but not in the past" do
        before do
          custom_value
          create_customizable_journal(journal: current_journal, custom_field:, value: custom_value.value)
        end

        it "has an empty value in the attributesByTimestamp of the past and no value in the now (since it is the current one)" do
          expect(subject.body)
            .to be_json_eql(nil.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/customField#{custom_field.id}")
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/customField#{custom_field.id}")
        end

        it "includes a custom field description in the schema" do
          expect(subject.body)
            .to be_json_eql(custom_field.name.to_json)
                  .at_path("_embedded/schemas/_embedded/elements/0/customField#{custom_field.id}/name")
        end
      end

      context "when there is a custom value in the past but not now" do
        before do
          create_customizable_journal(journal: original_journal, custom_field:, value: "Original value")
        end

        it "embeds the custom fields in the attributesByTimestamp of the past but not in the now" do
          expect(subject.body)
            .to be_json_eql("Original value".to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/customField#{custom_field.id}")
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/customField#{custom_field.id}")
        end

        it "includes a custom field description in the schema" do
          expect(subject.body)
            .to be_json_eql(custom_field.name.to_json)
                  .at_path("_embedded/schemas/_embedded/elements/0/customField#{custom_field.id}/name")
        end
      end

      describe "when filtering such that the filters do not match at all timestamps" do
        let(:path) { api_v3_paths.path_for(:work_packages, filters:, timestamps:) }
        let(:filters) do
          [
            {
              subject: {
                operator: "~",
                values: [search_term]
              }
            }
          ]
        end

        describe "when the filters match the work package today" do
          let(:search_term) { "current" }

          it "finds the work package" do
            expect(subject.body)
              .to be_json_eql(work_package.id.to_json)
              .at_path("_embedded/elements/0/id")
          end

          describe "_meta" do
            describe "matchesFilters" do
              it "marks the work package as matching the filters" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path("_embedded/elements/0/_meta/matchesFilters")
              end

              it "marks the work package as existing today" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path("_embedded/elements/0/_meta/exists")
              end
            end
          end

          describe "attributesByTimestamp/0 (baseline attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it "marks the work package as not matching the filters at the baseline time" do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
                end
              end

              describe "exists" do
                it "marks the work package as existing at the baseline time" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists")
                end
              end
            end
          end

          describe "attributesByTimestamp/1 (current attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it "marks the work package as matching the filters today" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
                end
              end

              describe "exists" do
                it "marks the work package as existing today" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists")
                end
              end
            end
          end
        end

        describe "when the filters match the work package at the baseline time" do
          let(:search_term) { "original" }

          it "finds the work package" do
            expect(subject.body)
              .to be_json_eql(work_package.id.to_json)
              .at_path("_embedded/elements/0/id")
          end

          describe "_meta" do
            it "marks the work package as not matching the filters in its current state" do
              expect(subject.body)
              .to be_json_eql(false.to_json)
                .at_path("_embedded/elements/0/_meta/matchesFilters")
            end

            it "marks the work package as existing today" do
              expect(subject.body)
                .to be_json_eql(true.to_json)
                .at_path("_embedded/elements/0/_meta/exists")
            end
          end

          describe "attributesByTimestamp/0 (baseline attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it "marks the work package as matching the filters at the baseline time" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
                end
              end

              describe "exists" do
                it "marks the work package as existing at the baseline time" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists")
                end
              end
            end
          end

          describe "attributesByTimestamp/1 (current attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it "marks the work package as not matching the filters today" do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
                end
              end

              describe "exists" do
                it "marks the work package as existing today" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists")
                end
              end
            end
          end
        end
      end

      describe "when the work package has not been present at the baseline time" do
        let(:timestamps) { [Timestamp.parse("2015-01-01T00:00:00Z"), Timestamp.now] }
        let(:created_at) { 10.days.ago }

        describe "attributesByTimestamp" do
          describe "0 (baseline attributes)" do
            it "has no attributes because the work package did not exist at the baseline time" do
              expect(subject.body)
                .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
            end

            describe "_meta" do
              describe "timestamp" do
                it "has the baseline timestamp, which is the first timestmap" do
                  expect(subject.body)
                    .to be_json_eql(timestamps.first.to_s.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
                end
              end

              describe "exists" do
                it "marks the work package as not existing at the baseline time" do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists")
                end
              end

              describe "matchesFilters" do
                it "marks the work package as not matching the filters at the baseline time" do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
                end
              end
            end

            describe "_links" do
              it "is not present" do
                expect(subject.body)
                  .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links")
              end
            end
          end

          describe "1 (current attributes)" do
            it "has no embedded attributes because they are the same as in the main object" do
              expect(subject.body)
                .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/subject")
            end

            describe "_meta" do
              describe "timestamp" do
                it "has the current timestamp, which is the second timestamp" do
                  expect(subject.body)
                    .to be_json_eql(timestamps.last.to_s.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
                end
              end

              describe "exists" do
                it "marks the work package as existing today" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists")
                end
              end

              describe "matchesFilters" do
                it "marks the work package as matching the filters today" do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
                end
              end
            end

            describe "_links" do
              it "has a self link" do
                expect(subject.body)
                  .to be_json_eql(api_v3_paths.work_package(work_package.id).to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_links/self/href")
              end
            end
          end
        end
      end

      describe "when the work package has not changed at all between the baseline and today" do
        let(:timestamps) { [Timestamp.new(1.minute.ago), Timestamp.now] }

        it "has the attributes in the main object" do
          expect(subject.body)
            .to be_json_eql(work_package.subject.to_json)
            .at_path("_embedded/elements/0/subject")
        end

        describe "_meta" do
          describe "matchesFilters" do
            it "marks the work package as matching the filters today" do
              expect(subject.body)
                .to be_json_eql(true.to_json)
                .at_path("_embedded/elements/0/_meta/matchesFilters")
            end
          end

          describe "exists" do
            it "marks the work package as existing today" do
              expect(subject.body)
                .to be_json_eql(true.to_json)
                .at_path("_embedded/elements/0/_meta/exists")
            end
          end

          describe "timestamp" do
            it "has the current timestamp, which is the second timestamp, in the same format as given in the request parameter" do
              expect(subject.body)
                .to be_json_eql("PT0S".to_json)
                .at_path("_embedded/elements/0/_meta/timestamp")
            end
          end
        end

        describe "attributesByTimestamp" do
          it "has no attributes in the embedded objects because they are the same as in the main object" do
            expect(subject.body)
              .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0")
            expect(subject.body)
              .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
            expect(subject.body)
              .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
            expect(subject.body)
              .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/subject")
          end

          context "when the custom fields are not changed" do
            before do
              custom_field
              custom_value
              create_customizable_journal(journal: original_journal,
                                          custom_field:,
                                          value: custom_value.value)
              create_customizable_journal(journal: current_journal,
                                          custom_field:,
                                          value: custom_value.value)
            end

            it "has no attributes in the embedded objects because they are the same as in the main object" do
              expect(subject.body)
                .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0")
              expect(subject.body)
                .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/customField#{custom_field.id}")
              expect(subject.body)
                .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
              expect(subject.body)
                .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/customField#{custom_field.id}")
              expect(subject.body)
                .to be_json_eql("This the current value".to_json)
                .at_path("_embedded/elements/0/customField#{custom_field.id}")
            end
          end

          describe "_meta" do
            describe "matchesFilters" do
              it "marks the work package as matching the filters today" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
              end

              it "marks the work package as matching the filters at the baseline time" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
              end
            end

            describe "exists" do
              it "marks the work package as existing today" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists")
              end

              it "marks the work package as existing at the baseline time" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists")
              end
            end

            describe "timestamp" do
              it "has the current timestamp, which is the second timestamp, " \
                 "in the same format as given in the request parameter" do
                expect(subject.body)
                  .to be_json_eql("PT0S".to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
              end

              it "has the baseline timestamp, which is the first timestamp, " \
                 "in the same format as given in the request parameter" do
                expect(subject.body)
                  .to be_json_eql(timestamps.first.to_s.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
              end
            end
          end
        end
      end

      describe "when providing only the current timestamp PT0S, which is equivalent to providing no timestamps" do
        let(:timestamps) { [Timestamp.now] }

        it "has the attributes in the main object" do
          expect(subject.body)
            .to be_json_eql(work_package.subject.to_json)
            .at_path("_embedded/elements/0/subject")
        end

        it "has no _meta" do
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_meta/matchesFilters")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_meta/exists")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_meta/timestamp")
        end

        it "has no attributesByTimestamp" do
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp")
        end
      end

      describe "when no longer being allowed to see the work package but used to in the past (moved to different project)" do
        let(:project2) { create(:project) }
        let(:work_packages) { [work_package] }

        before do
          work_package.update_column(:project_id, project2.id)
          current_journal.data.update_column(:project_id, project2.id)
        end

        it "finds the work package" do
          expect(subject.body)
            .to be_json_eql(work_package.id.to_json)
                  .at_path("_embedded/elements/0/id")
        end

        it "has no attributes in the main object" do
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/subject")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/0/_links/project")
        end

        describe "_meta" do
          it "marks the work package as not matching the filters" do
            expect(subject.body)
              .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_meta/matchesFilters")
          end

          it "marks the work package as not existing today" do
            expect(subject.body)
              .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_meta/exists")
          end
        end

        describe "attributesByTimestamp/0 (baseline attributes)" do
          describe "_meta" do
            describe "matchesFilters" do
              it "marks the work package as matching the filters at the baseline time" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
              end
            end

            describe "exists" do
              it "marks the work package as existing at the baseline time" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists")
              end
            end
          end

          it "has all the supported attributes including those that did not change" do
            expect(subject.body)
              .to be_json_eql("The original work package".to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
            expect(subject.body)
              .to be_json_eql(project.name.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/project/title")
            expect(subject.body)
              .to be_json_eql(current_user.name.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/assignee/title")
          end
        end

        describe "attributesByTimestamp/1 (current attributes)" do
          describe "_meta" do
            describe "matchesFilters" do
              it "marks the work package as not matching the filters today" do
                expect(subject.body)
                  .to be_json_eql(false.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
              end
            end

            describe "exists" do
              it "marks the work package as not existing today" do
                expect(subject.body)
                  .to be_json_eql(false.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists")
              end
            end
          end
        end
      end

      describe "when now being allowed to see the work package but not in the past (moved to different project)" do
        let(:project2) { create(:project) }
        let(:work_packages) { [work_package] }

        before do
          # Move the old journal entry into another project where the user has no access
          original_journal.data.update_columns(project_id: project2.id)
        end

        it "finds the work package" do
          expect(subject.body)
            .to be_json_eql(work_package.id.to_json)
                  .at_path("_embedded/elements/0/id")
        end

        it "has the current attributes in the main object" do
          expect(subject.body)
            .to be_json_eql(work_package.subject.to_json)
                  .at_path("_embedded/elements/0/subject")
          expect(subject.body)
            .to be_json_eql(api_v3_paths.project(project.id).to_json)
                  .at_path("_embedded/elements/0/_links/project/href")
        end

        describe "_meta" do
          it "marks the work package as matching the filters" do
            expect(subject.body)
              .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_meta/matchesFilters")
          end

          it "marks the work package as existing today" do
            expect(subject.body)
              .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_meta/exists")
          end

          describe "timestamp" do
            it "has the current timestamp, which is the second timestamp, in the same format as given in the request parameter" do
              expect(subject.body)
                .to be_json_eql("PT0S".to_json)
                      .at_path("_embedded/elements/0/_meta/timestamp")
            end
          end
        end

        describe "attributesByTimestamp/0 (baseline attributes)" do
          describe "_meta" do
            describe "matchesFilters" do
              it "marks the work package as not matching the filters at the baseline time" do
                expect(subject.body)
                  .to be_json_eql(false.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
              end
            end

            describe "exists" do
              it "marks the work package as existing at the baseline time" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists")
              end
            end
          end

          it "has all the supported attribute change" do
            expect(subject.body)
              .to be_json_eql("The original work package".to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
            expect(subject.body)
              .to be_json_eql(project2.name.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/project/title")
          end
        end

        describe "attributesByTimestamp/1 (current attributes)" do
          describe "_meta" do
            describe "matchesFilters" do
              it "marks the work package as matching the filters today" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
              end
            end

            describe "exists" do
              it "marks the work package as existing today" do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                        .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists")
              end
            end
          end
        end
      end

      describe "for multiple work packages" do
        let!(:work_package2) do
          create(:work_package, :created_in_past, created_at:, subject: "Other work package", project:)
        end

        it "succeeds" do
          expect(subject.status).to eq(200)
        end

        it "has the current attributes of both work packages" do
          expect(subject.body)
            .to be_json_eql(work_package.subject.to_json)
            .at_path("_embedded/elements/0/subject")
          expect(subject.body)
            .to be_json_eql(work_package2.subject.to_json)
            .at_path("_embedded/elements/1/subject")
        end

        it "embeds the attributesByTimestamp for both work packages" do
          expect(subject.body)
            .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp")
          expect(subject.body)
            .to have_json_path("_embedded/elements/1/_embedded/attributesByTimestamp")
        end

        it "has the attributes that are different from the current attributes in the embedded objects" do
          expect(subject.body)
            .to be_json_eql("The original work package".to_json)
            .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
          expect(subject.body)
            .not_to have_json_path("_embedded/elements/1/_embedded/attributesByTimestamp/0/subject")
        end
      end

      describe "for a milestone typed work package" do
        let(:type) { create(:type_milestone) }
        let(:original_date) { Date.current }
        let(:current_date) { Date.current + 1.day }

        let!(:work_package) do
          create(:work_package,
                 due_date: current_date,
                 start_date: current_date,
                 duration: 1,
                 project:,
                 type:,
                 journals: {
                   created_at => { due_date: original_date, start_date: original_date },
                   1.day.ago => {}
                 })
        end

        it "displays the original date in the attributesByTimestamp" do
          expect(subject.body)
            .to be_json_eql(original_date.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/date")
        end
      end

      context "when the timestamps are relative date keywords" do
        let(:timestamps) { [Timestamp.parse("oneWeekAgo@11:00+00:00"), Timestamp.parse("lastWorkingDay@12:00+00:00")] }

        it "has an embedded link to the baseline work package" do
          expect(subject.body)
            .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
            .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/self/href")
        end

        it "has the absolute timestamps within the self links of the elements" do
          Timecop.freeze do
            expect(subject.body)
              .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.map(&:absolute)).to_json)
              .at_path("_embedded/elements/0/_links/self/href")
          end
        end

        it "has the absolute timestamps within the collection self link" do
          Timecop.freeze do
            expected_self_href = { timestamps: api_v3_paths.timestamps_to_param_value(timestamps.map(&:absolute)) }.to_query
            expect(subject.body)
              .to include_json(expected_self_href.to_json)
              .at_path("_links/self/href")
          end
        end

        it "has the relative timestamps within the _meta timestamps" do
          expect(subject.body)
            .to be_json_eql("oneWeekAgo@11:00+00:00".to_json)
            .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
          expect(subject.body)
            .to be_json_eql("lastWorkingDay@12:00+00:00".to_json)
            .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
          expect(subject.body)
            .to be_json_eql("lastWorkingDay@12:00+00:00".to_json)
            .at_path("_embedded/elements/0/_meta/timestamp")
        end

        describe "when the work package has not been present at the baseline time" do
          let(:created_at) { 10.days.ago }

          describe "attributesByTimestamp" do
            describe "0 (baseline attributes)" do
              describe "_meta" do
                describe "timestamp" do
                  it "has the baseline timestamp, which is the first timestmap" do
                    expect(subject.body)
                      .to be_json_eql("oneWeekAgo@11:00+00:00".to_json)
                      .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
                  end
                end
              end
            end

            describe "1 (current attributes)" do
              describe "_meta" do
                describe "timestamp" do
                  it "has the current timestamp, which is the second timestamp" do
                    expect(subject.body)
                      .to be_json_eql("lastWorkingDay@12:00+00:00".to_json)
                      .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
                  end
                end
              end
            end
          end
        end

        describe "when the work package has not changed at all between the baseline and today" do
          let(:timestamps) { [Timestamp.parse("lastWorkingDay@12:00+00:00"), Timestamp.now] }

          describe "_meta" do
            describe "timestamp" do
              it "has the current timestamp, which is the second timestamp, " \
                 "in the same format as given in the request parameter" do
                expect(subject.body)
                  .to be_json_eql("PT0S".to_json)
                  .at_path("_embedded/elements/0/_meta/timestamp")
              end
            end
          end

          describe "attributesByTimestamp" do
            describe "_meta" do
              describe "timestamp" do
                it "has the current timestamp, which is the second timestamp, " \
                   "in the same format as given in the request parameter" do
                  expect(subject.body)
                    .to be_json_eql("PT0S".to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
                end

                it "has the baseline timestamp, which is the first timestamp, " \
                   "in the same format as given in the request parameter" do
                  expect(subject.body)
                    .to be_json_eql("lastWorkingDay@12:00+00:00".to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
                end
              end
            end
          end
        end
      end

      context "with caching" do
        context "with relative timestamps" do
          let(:timestamps) { [Timestamp.parse("P-2D"), Timestamp.now] }
          let(:created_at) { Date.parse("2015-01-01") }

          describe "when the filter becomes outdated" do
            # The work package has been updated 1 day ago, which is after the baseline
            # date (2 days ago). When time progresses, the date of the update will be
            # date (last week). When time progresses, the date of the update will be
            # before the baseline date, because the baseline date is relative to the
            # current date. This means that the filter will become outdated and we cannot
            # use a cached result in this case.
            let(:path) { "#{api_v3_paths.path_for(:work_packages, filters:)}&timestamps=#{timestamps_param}" }
            let(:filters) do
              [
                {
                  subject: {
                    operator: "~",
                    values: [search_term]
                  }
                }
              ]
            end
            let(:search_term) { "original" }

            it "has the relative timestamps within the _meta timestamps" do
              expect(timestamps.first.to_s).to eq("P-2D")
              expect(timestamps.first).to be_relative
              expect(subject.body)
                .to be_json_eql("P-2D".to_json)
                .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
              expect(subject.body)
                .to be_json_eql("PT0S".to_json)
                .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
              expect(subject.body)
               .to be_json_eql("PT0S".to_json)
               .at_path("_embedded/elements/0/_meta/timestamp")
            end

            it "does not use an outdated cache" do
              get path
              expect do
                Timecop.travel 5.days do
                  get path
                end
              end.to change {
                JSON.parse(last_response.body).dig("_embedded", "elements").count
              }.from(1).to(0)
            end
          end
        end

        context "with relative date keyword timestamps" do
          let(:timestamps) { [Timestamp.parse("oneWeekAgo@12:00+00:00"), Timestamp.now] }
          let(:created_at) { Date.parse("2015-01-01") }

          describe "when the filter becomes outdated" do
            # The work package has been updated 1 day ago, which is after the baseline
            # date (last week). When time progresses, the date of the update will be
            # before the baseline date, because the baseline date is relative to the
            # current date. This means that the filter will become outdated and we cannot
            # use a cached result in this case.

            let(:path) { "#{api_v3_paths.path_for(:work_packages, filters:)}&timestamps=#{timestamps_param}" }
            let(:filters) do
              [
                {
                  subject: {
                    operator: "~",
                    values: [search_term]
                  }
                }
              ]
            end
            let(:search_term) { "original" }

            it "has the relative timestamps within the _meta timestamps" do
              expect(timestamps.first.to_s).to eq("oneWeekAgo@12:00+00:00")
              expect(timestamps.first).to be_relative
              expect(subject.body)
                .to be_json_eql("oneWeekAgo@12:00+00:00".to_json)
                .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp")
              expect(subject.body)
                .to be_json_eql("PT0S".to_json)
                .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp")
              expect(subject.body)
                .to be_json_eql("PT0S".to_json)
                .at_path("_embedded/elements/0/_meta/timestamp")
            end

            it "does not use an outdated cache" do
              get path
              expect do
                Timecop.travel 1.week do
                  get path
                end
              end.to change {
                JSON.parse(last_response.body).dig("_embedded", "elements").count
              }.from(1).to(0)
            end
          end
        end
      end
    end
  end
end

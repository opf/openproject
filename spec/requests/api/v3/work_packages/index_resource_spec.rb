#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource',
         content_type: :json do
  include API::V3::Utilities::PathHelper

  create_shared_association_defaults_for_work_package_factory

  let(:work_package) do
    create(:work_package,
           project_id: project.id,
           description: 'lorem ipsum')
  end
  let(:project) do
    create(:project, identifier: 'test_project', public: false)
  end
  let(:role) { create(:role, permissions:) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }

  current_user do
    create(:user, member_in_project: project, member_through_role: role)
  end

  describe 'GET /api/v3/work_packages' do
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

    it 'succeeds' do
      expect(subject.status).to be 200
    end

    it 'returns visible work packages' do
      expect(subject.body).to be_json_eql(1.to_json).at_path('total')
    end

    it 'embeds the work package schemas' do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.work_package_schema(project.id, work_package.type.id).to_json)
              .at_path('_embedded/schemas/_embedded/elements/0/_links/self/href')
    end

    context 'with filtering by typeahead' do
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

      it_behaves_like 'API V3 collection response', 2, 2, 'WorkPackage', 'WorkPackageCollection' do
        let(:elements) { [lorem_ipsum_work_package, ipsum_work_package] }
      end
    end

    context 'with a user not seeing any work packages' do
      include_context 'with non-member permissions from non_member_permissions'
      let(:current_user) { create(:user) }
      let(:non_member_permissions) { [:view_work_packages] }

      it 'succeeds' do
        expect(subject.status).to be 200
      end

      it 'returns no work packages' do
        expect(subject.body).to be_json_eql(0.to_json).at_path('total')
      end

      context 'with the user not allowed to see work packages in general' do
        let(:non_member_permissions) { [] }

        before { get path }

        it_behaves_like 'unauthorized access'
      end
    end

    describe 'encoded query props' do
      before { get path }

      subject { last_response }

      let(:props) do
        eprops = {
          filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
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

      it 'succeeds' do
        expect(subject.status)
          .to be 200
      end

      it 'returns visible and filtered work packages' do
        expect(subject.body)
          .to be_json_eql(2.to_json)
                .at_path('total')

        # because of the page size
        expect(subject.body)
          .to be_json_eql(1.to_json)
                .at_path('count')

        expect(subject.body)
          .to be_json_eql(work_package.id.to_json)
                .at_path('_embedded/elements/0/id')
      end

      context 'without zlibbed' do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Base64.encode64(eprops)
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non json encoded' do
        let(:props) do
          eprops = "some non json string"

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non base64 encoded' do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Zlib::Deflate.deflate(eprops)
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non hash' do
        let(:props) do
          eprops = [{
            filters: [{ id: { operator: '=',
                              values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }].to_json

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like 'param validation error'
      end
    end

    context 'when providing timestamps', with_ee: %i[baseline_comparison], with_flag: { show_changes: true } do
      subject do
        get path
        last_response
      end

      let(:timestamps) { [Timestamp.parse('2015-01-01T00:00:00Z'), Timestamp.now] }
      let(:timestamps_param) { CGI.escape(timestamps.join(',')) }
      let(:path) { "#{api_v3_paths.work_packages}?timestamps=#{timestamps_param}" }
      let(:baseline_time) { timestamps.first.to_time }
      let(:created_at) { baseline_time - 1.day }

      let(:work_package) do
        new_work_package = create(:work_package, subject: "The current work package", project:)
        new_work_package.update_columns(created_at:)
        new_work_package
      end
      let(:original_journal) do
        create_journal(journable: work_package, timestamp: created_at,
                       version: 1,
                       attributes: { subject: "The original work package" })
      end
      let(:current_journal) do
        create_journal(journable: work_package, timestamp: 1.day.ago,
                       version: 2,
                       attributes: { subject: "The current work package" })
      end

      def create_journal(journable:, version:, timestamp:, attributes: {})
        work_package_attributes = work_package.attributes.except("id")
        journal_attributes = work_package_attributes \
            .extract!(*Journal::WorkPackageJournal.attribute_names) \
            .symbolize_keys.merge(attributes)
        create(:work_package_journal, version:,
                                      journable:, created_at: timestamp, updated_at: timestamp,
                                      data: build(:journal_work_package_journal, journal_attributes))
      end

      before do
        work_package.journals.destroy_all
        original_journal
        current_journal
      end

      it 'succeeds' do
        expect(subject.status).to be 200
      end

      it 'embeds the attributesByTimestamp' do
        expect(subject.body)
          .to be_json_eql("The original work package".to_json)
          .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/subject")
        expect(subject.body)
          .to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1")
      end

      it 'does not embed the attributes in attributesByTimestamp if they are the same as the current attributes' do
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/description")
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/2/description")
      end

      it 'has the current attributes as attributes' do
        expect(subject.body)
          .to be_json_eql("The current work package".to_json)
          .at_path('_embedded/elements/0/subject')
      end

      it 'has an embedded link to the baseline work package' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
          .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/self/href')
      end

      it 'has the absolute timestamps within the self links of the elements' do
        Timecop.freeze do
          expect(subject.body)
            .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.map(&:absolute)).to_json)
            .at_path('_embedded/elements/0/_links/self/href')
        end
      end

      it 'has the absolute timestamps within the collection self link' do
        Timecop.freeze do
          expect(subject.body)
            .to include_json({ timestamps: api_v3_paths.timestamps_to_param_value(timestamps.map(&:absolute)) }.to_query.to_json)
            .at_path('_links/self/href')
        end
      end

      it 'has no redundant timestamp attribute in the main section' do
        # The historic work packages have a timestamp attribute. But we do not expose that here
        # because the timestamp is already given in the _meta section.
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/timestamp")
      end

      it 'has no redundant timestamp attribute in the attributesByTimestamp' do
        # The historic work packages have a timestamp attribute. But we do not expose that here
        # because the timestamp is already given in the _meta section.
        expect(subject.body)
          .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/timestamp")
      end

      it 'has the relative timestamps within the _meta timestamps' do
        expect(subject.body)
          .to be_json_eql('2015-01-01T00:00:00Z'.to_json)
          .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
        expect(subject.body)
          .to be_json_eql('PT0S'.to_json)
          .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
        expect(subject.body)
          .to be_json_eql('PT0S'.to_json)
          .at_path('_embedded/elements/0/_meta/timestamp')
      end

      describe "when filtering such that the filters do not match at all timestamps" do
        let(:path) { "#{api_v3_paths.path_for(:work_packages, filters:)}&timestamps=#{timestamps_param}" }
        let(:filters) do
          [
            {
              subject: {
                operator: '~',
                values: [search_term]
              }
            }
          ]
        end

        describe "when the filters match the work package today" do
          let(:search_term) { 'current' }

          it 'finds the work package' do
            expect(subject.body)
              .to be_json_eql(work_package.id.to_json)
              .at_path('_embedded/elements/0/id')
          end

          describe "_meta" do
            describe "matchesFilters" do
              it 'marks the work package as matching the filters' do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path('_embedded/elements/0/_meta/matchesFilters')
              end

              it 'marks the work package as existing today' do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path('_embedded/elements/0/_meta/exists')
              end
            end
          end

          describe "attributesByTimestamp/0 (baseline attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it 'marks the work package as not matching the filters at the baseline time' do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters')
                end
              end

              describe "exists" do
                it 'marks the work package as existing at the baseline time' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists')
                end
              end
            end
          end

          describe "attributesByTimestamp/1 (current attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it 'marks the work package as matching the filters today' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters')
                end
              end

              describe "exists" do
                it 'marks the work package as existing today' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists')
                end
              end
            end
          end
        end

        describe "when the filters match the work package at the baseline time" do
          let(:search_term) { 'original' }

          it 'finds the work package' do
            expect(subject.body)
              .to be_json_eql(work_package.id.to_json)
              .at_path('_embedded/elements/0/id')
          end

          describe "_meta" do
            it 'marks the work package as not matching the filters in its current state' do
              expect(subject.body)
              .to be_json_eql(false.to_json)
                .at_path('_embedded/elements/0/_meta/matchesFilters')
            end

            it 'marks the work package as existing today' do
              expect(subject.body)
                .to be_json_eql(true.to_json)
                .at_path('_embedded/elements/0/_meta/exists')
            end
          end

          describe "attributesByTimestamp/0 (baseline attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it 'marks the work package as matching the filters at the baseline time' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters')
                end
              end

              describe "exists" do
                it 'marks the work package as existing at the baseline time' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists')
                end
              end
            end
          end

          describe "attributesByTimestamp/1 (current attributes)" do
            describe "_meta" do
              describe "matchesFilters" do
                it 'marks the work package as not matching the filters today' do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters')
                end
              end

              describe "exists" do
                it 'marks the work package as existing today' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists')
                end
              end
            end
          end
        end
      end

      describe "when the work package has not been present at the baseline time" do
        let(:timestamps) { [Timestamp.parse('2015-01-01T00:00:00Z'), Timestamp.now] }
        let(:created_at) { 10.days.ago }

        describe "attributesByTimestamp" do
          describe "0 (baseline attributes)" do
            it 'has no attributes because the work package did not exist at the baseline time' do
              expect(subject.body)
                .not_to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/subject')
            end

            describe "_meta" do
              describe "timestamp" do
                it 'has the baseline timestamp, which is the first timestmap' do
                  expect(subject.body)
                    .to be_json_eql(timestamps.first.to_s.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
                end
              end

              describe "exists" do
                it 'marks the work package as not existing at the baseline time' do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists")
                end
              end

              describe "matchesFilters" do
                it 'marks the work package as not matching the filters at the baseline time' do
                  expect(subject.body)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters")
                end
              end
            end

            describe "_links" do
              it 'is not present' do
                expect(subject.body)
                  .not_to have_json_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/_links")
              end
            end
          end

          describe "1 (current attributes)" do
            it 'has no embedded attributes because they are the same as in the main object' do
              expect(subject.body)
                .not_to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/subject')
            end

            describe "_meta" do
              describe "timestamp" do
                it 'has the current timestamp, which is the second timestamp' do
                  expect(subject.body)
                    .to be_json_eql(timestamps.last.to_s.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
                end
              end

              describe "exists" do
                it 'marks the work package as existing today' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists")
                end
              end

              describe "matchesFilters" do
                it 'marks the work package as matching the filters today' do
                  expect(subject.body)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters")
                end
              end
            end

            describe "_links" do
              it 'has a self link' do
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
            .at_path('_embedded/elements/0/subject')
        end

        describe "_meta" do
          describe "matchesFilters" do
            it 'marks the work package as matching the filters today' do
              expect(subject.body)
                .to be_json_eql(true.to_json)
                .at_path('_embedded/elements/0/_meta/matchesFilters')
            end
          end

          describe "exists" do
            it 'marks the work package as existing today' do
              expect(subject.body)
                .to be_json_eql(true.to_json)
                .at_path('_embedded/elements/0/_meta/exists')
            end
          end

          describe "timestamp" do
            it 'has the current timestamp, which is the second timestamp, in the same format as given in the request parameter' do
              expect(subject.body)
                .to be_json_eql("PT0S".to_json)
                .at_path('_embedded/elements/0/_meta/timestamp')
            end
          end
        end

        describe "attributesByTimestamp" do
          it "has no attributes in the embedded objects because they are the same as in the main object" do
            expect(subject.body)
              .to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp/0')
            expect(subject.body)
              .not_to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/subject')
            expect(subject.body)
              .to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp/1')
            expect(subject.body)
              .not_to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/subject')
          end

          describe "_meta" do
            describe "matchesFilters" do
              it 'marks the work package as matching the filters today' do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/matchesFilters')
              end

              it 'marks the work package as matching the filters at the baseline time' do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/matchesFilters')
              end
            end

            describe "exists" do
              it 'marks the work package as existing today' do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/exists')
              end

              it 'marks the work package as existing at the baseline time' do
                expect(subject.body)
                  .to be_json_eql(true.to_json)
                  .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/exists')
              end
            end

            describe "timestamp" do
              it 'has the current timestamp, which is the second timestamp, ' \
                 'in the same format as given in the request parameter' do
                expect(subject.body)
                  .to be_json_eql("PT0S".to_json)
                  .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
              end

              it 'has the baseline timestamp, which is the first timestamp, ' \
                 'in the same format as given in the request parameter' do
                expect(subject.body)
                  .to be_json_eql(timestamps.first.to_s.to_json)
                  .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
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
            .at_path('_embedded/elements/0/subject')
        end

        it "has no _meta" do
          expect(subject.body)
            .not_to have_json_path('_embedded/elements/0/_meta/matchesFilters')
          expect(subject.body)
            .not_to have_json_path('_embedded/elements/0/_meta/exists')
          expect(subject.body)
            .not_to have_json_path('_embedded/elements/0/_meta/timestamp')
        end

        it "has no attributesByTimestamp" do
          expect(subject.body)
            .not_to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp')
        end
      end

      describe "for multiple work packages" do
        let!(:work_package2) do
          new_work_package = create(:work_package, subject: "Other work package", project:)
          new_work_package.update_columns(created_at:)
          new_work_package.journals.update_all(created_at:)
          new_work_package
        end

        it "succeeds" do
          expect(subject.status).to eq(200)
        end

        it "has the current attributes of both work packages" do
          expect(subject.body)
            .to be_json_eql(work_package.subject.to_json)
            .at_path('_embedded/elements/0/subject')
          expect(subject.body)
            .to be_json_eql(work_package2.subject.to_json)
            .at_path('_embedded/elements/1/subject')
        end

        it "embeds the attributesByTimestamp for both work packages" do
          expect(subject.body)
            .to have_json_path('_embedded/elements/0/_embedded/attributesByTimestamp')
          expect(subject.body)
            .to have_json_path('_embedded/elements/1/_embedded/attributesByTimestamp')
        end

        it "has the attributes that are different from the current attributes in the embedded objects" do
          expect(subject.body)
            .to be_json_eql("The original work package".to_json)
            .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/subject')
          expect(subject.body)
            .not_to have_json_path('_embedded/elements/1/_embedded/attributesByTimestamp/0/subject')
        end
      end

      describe "for a milestone typed work package" do
        let(:type) { create(:type_milestone) }
        let(:original_date) { Date.current }
        let(:current_date) { Date.current + 1.day }

        let(:work_package) do
          new_work_package = create(:work_package, due_date: current_date, start_date: current_date, project:, type:)
          new_work_package.update_columns(created_at:)
          new_work_package
        end

        let(:original_journal) do
          create_journal(journable: work_package,
                         timestamp: created_at,
                         version: 1,
                         attributes: { due_date: original_date, start_date: original_date, duration: 1 })
        end
        let(:current_journal) do
          create_journal(journable: work_package,
                         timestamp: 1.day.ago,
                         version: 2,
                         attributes: { due_date: current_date, start_date: current_date, duration: 1 })
        end

        it 'displays the original date in the attributesByTimestamp' do
          expect(subject.body)
            .to be_json_eql(original_date.to_json)
                  .at_path("_embedded/elements/0/_embedded/attributesByTimestamp/0/date")
        end
      end

      context 'when the timestamps are relative date keywords' do
        let(:timestamps) { [Timestamp.parse('oneWeekAgo@11:00+00:00'), Timestamp.parse('lastWorkingDay@12:00+00:00')] }

        it 'has an embedded link to the baseline work package' do
          expect(subject.body)
            .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
            .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_links/self/href')
        end

        it 'has the absolute timestamps within the self links of the elements' do
          Timecop.freeze do
            expect(subject.body)
              .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.map(&:absolute)).to_json)
              .at_path('_embedded/elements/0/_links/self/href')
          end
        end

        it 'has the absolute timestamps within the collection self link' do
          Timecop.freeze do
            expected_self_href = { timestamps: api_v3_paths.timestamps_to_param_value(timestamps.map(&:absolute)) }.to_query
            expect(subject.body)
              .to include_json(expected_self_href.to_json)
              .at_path('_links/self/href')
          end
        end

        it 'has the relative timestamps within the _meta timestamps' do
          expect(subject.body)
            .to be_json_eql('oneWeekAgo@11:00+00:00'.to_json)
            .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
          expect(subject.body)
            .to be_json_eql('lastWorkingDay@12:00+00:00'.to_json)
            .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
          expect(subject.body)
            .to be_json_eql('lastWorkingDay@12:00+00:00'.to_json)
            .at_path('_embedded/elements/0/_meta/timestamp')
        end

        describe "when the work package has not been present at the baseline time" do
          let(:created_at) { 10.days.ago }

          describe "attributesByTimestamp" do
            describe "0 (baseline attributes)" do
              describe "_meta" do
                describe "timestamp" do
                  it 'has the baseline timestamp, which is the first timestmap' do
                    expect(subject.body)
                      .to be_json_eql('oneWeekAgo@11:00+00:00'.to_json)
                      .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
                  end
                end
              end
            end

            describe "1 (current attributes)" do
              describe "_meta" do
                describe "timestamp" do
                  it 'has the current timestamp, which is the second timestamp' do
                    expect(subject.body)
                      .to be_json_eql('lastWorkingDay@12:00+00:00'.to_json)
                      .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
                  end
                end
              end
            end
          end
        end

        describe "when the work package has not changed at all between the baseline and today" do
          let(:timestamps) { [Timestamp.parse('lastWorkingDay@12:00+00:00'), Timestamp.now] }

          describe "_meta" do
            describe "timestamp" do
              it 'has the current timestamp, which is the second timestamp, ' \
                 'in the same format as given in the request parameter' do
                expect(subject.body)
                  .to be_json_eql("PT0S".to_json)
                  .at_path('_embedded/elements/0/_meta/timestamp')
              end
            end
          end

          describe "attributesByTimestamp" do
            describe "_meta" do
              describe "timestamp" do
                it 'has the current timestamp, which is the second timestamp, ' \
                   'in the same format as given in the request parameter' do
                  expect(subject.body)
                    .to be_json_eql("PT0S".to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
                end

                it 'has the baseline timestamp, which is the first timestamp, ' \
                   'in the same format as given in the request parameter' do
                  expect(subject.body)
                    .to be_json_eql('lastWorkingDay@12:00+00:00'.to_json)
                    .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
                end
              end
            end
          end
        end
      end

      context "with caching" do
        context "with relative timestamps" do
          let(:timestamps) { [Timestamp.parse("P-2D"), Timestamp.now] }
          let(:created_at) { '2015-01-01' }

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
                    operator: '~',
                    values: [search_term]
                  }
                }
              ]
            end
            let(:search_term) { 'original' }

            it 'has the relative timestamps within the _meta timestamps' do
              expect(timestamps.first.to_s).to eq('P-2D')
              expect(timestamps.first).to be_relative
              expect(subject.body)
                .to be_json_eql('P-2D'.to_json)
                .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
              expect(subject.body)
                .to be_json_eql('PT0S'.to_json)
                .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
              expect(subject.body)
               .to be_json_eql('PT0S'.to_json)
               .at_path('_embedded/elements/0/_meta/timestamp')
            end

            it "does not use an outdated cache" do
              get path
              expect do
                Timecop.travel 5.days do
                  get path
                end
              end.to change {
                JSON.parse(last_response.body).dig('_embedded', 'elements').count
              }.from(1).to(0)
            end
          end
        end

        context "with relative date keyword timestamps" do
          let(:timestamps) { [Timestamp.parse('oneWeekAgo@12:00+00:00'), Timestamp.now] }
          let(:created_at) { '2015-01-01' }

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
                    operator: '~',
                    values: [search_term]
                  }
                }
              ]
            end
            let(:search_term) { 'original' }

            it 'has the relative timestamps within the _meta timestamps' do
              expect(timestamps.first.to_s).to eq('oneWeekAgo@12:00+00:00')
              expect(timestamps.first).to be_relative
              expect(subject.body)
                .to be_json_eql('oneWeekAgo@12:00+00:00'.to_json)
                .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/0/_meta/timestamp')
              expect(subject.body)
                .to be_json_eql('PT0S'.to_json)
                .at_path('_embedded/elements/0/_embedded/attributesByTimestamp/1/_meta/timestamp')
              expect(subject.body)
                .to be_json_eql('PT0S'.to_json)
                .at_path('_embedded/elements/0/_meta/timestamp')
            end

            it "does not use an outdated cache" do
              get path
              expect do
                Timecop.travel 1.week do
                  get path
                end
              end.to change {
                JSON.parse(last_response.body).dig('_embedded', 'elements').count
              }.from(1).to(0)
            end
          end
        end
      end
    end
  end
end

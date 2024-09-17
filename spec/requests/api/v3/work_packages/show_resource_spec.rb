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
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, identifier: "test_project", public: false) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:priority) { create(:priority) }
  shared_let(:status) { create(:status) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages edit_work_packages assign_versions] })
  end

  before_all do
    set_factory_default(:priority, priority)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status)
    set_factory_default(:user, user)
  end

  let(:work_package) do
    create(:work_package,
           project_id: project.id,
           description: "lorem ipsum")
  end

  current_user { user }

  describe "GET /api/v3/work_packages/:id" do
    let(:get_path) { api_v3_paths.work_package work_package.id }

    context "when acting as a user with permission to view work package" do
      before do
        get get_path
      end

      it "responds with 200" do
        expect(last_response).to have_http_status(:ok)
      end

      describe "response body" do
        subject { last_response.body }

        shared_let(:other_wp) { create(:work_package, status: closed_status) }
        let(:work_package) do
          create(:work_package,
                 description:,
                 remaining_hours: 5) do |wp|
            wp.children << children
          end
        end
        let(:children) { [] }
        let(:description) do
          <<~DESCRIPTION
            <macro class="toc"><macro>

            # OpenProject Masterplan for 2015

            ## three point plan

            1) One ###{other_wp.id}
            2) Two
            3) Three

            ### random thoughts

            ### things we like

            * Pointed
            * Relaxed
            * Debonaire
          DESCRIPTION
        end

        it "responds with work package in HAL+JSON format" do
          expect(subject)
            .to be_json_eql(work_package.id.to_json)
                  .at_path("id")
        end

        describe "description" do
          subject { JSON.parse(last_response.body)["description"] }

          it "renders to html" do
            expect(subject).to have_css("h1")
            expect(subject).to have_css("h2")

            # resolves links
            expect(subject["html"])
              .to have_css("opce-macro-wp-quickinfo[data-id='#{other_wp.id}']")
            # resolves macros, e.g. toc
            expect(subject["html"])
              .to have_css(".op-uc-toc--list-item", text: "OpenProject Masterplan for 2015")
          end
        end

        describe "derived dates" do
          let(:children) do
            # This will be in another project but the user is still allowed to see the dates
            [create(:work_package,
                    start_date: Time.zone.today,
                    due_date: Time.zone.today + 5.days)]
          end

          it "has derived dates" do
            expect(subject)
              .to be_json_eql(Time.zone.today.to_json)
                    .at_path("derivedStartDate")

            expect(subject)
              .to be_json_eql((Time.zone.today + 5.days).to_json)
                    .at_path("derivedDueDate")
          end
        end

        describe "relations" do
          let(:directly_related_wp) do
            create(:work_package, project_id: project.id)
          end
          let(:transitively_related_wp) do
            create(:work_package, project_id: project.id)
          end

          let(:work_package) do
            create(:work_package,
                   project_id: project.id,
                   description: "lorem ipsum").tap do |wp|
              create(:relation, relation_type: Relation::TYPE_RELATES, from: wp, to: directly_related_wp)
              create(:relation, relation_type: Relation::TYPE_RELATES, from: directly_related_wp, to: transitively_related_wp)
            end
          end

          it "embeds all direct relations" do
            expect(subject)
              .to be_json_eql(1.to_json)
                    .at_path("_embedded/relations/total")

            expect(subject)
              .to be_json_eql(api_v3_paths.work_package(directly_related_wp.id).to_json)
                    .at_path("_embedded/relations/_embedded/elements/0/_links/to/href")
          end
        end

        describe "remaining time" do
          it { is_expected.to be_json_eql("PT5H".to_json).at_path("remainingTime") }
        end

        describe "derived remaining time" do
          it { is_expected.to be_json_eql(nil.to_json).at_path("derivedRemainingTime") }
        end
      end

      context "when requesting nonexistent work package" do
        let(:get_path) { api_v3_paths.work_package 909090 }

        it_behaves_like "not found",
                        I18n.t("api_v3.errors.not_found.work_package")
      end
    end

    context "when acting as a user without permission to view work package" do
      shared_let(:unauthorized_user) { create(:user) }

      current_user { unauthorized_user }

      before do
        get get_path
      end

      it_behaves_like "not found",
                      I18n.t("api_v3.errors.not_found.work_package")
    end

    context "when acting as an anonymous user" do
      current_user { User.anonymous }

      before do
        get get_path
      end

      it_behaves_like "not found response based on login_required",
                      I18n.t("api_v3.errors.not_found.work_package")
    end
  end

  describe "GET /api/v3/work_packages/:id?timestamps=" do
    let(:timestamps_param) { CGI.escape(timestamps.map(&:to_s).join(",")) }
    let(:get_path) { "#{api_v3_paths.work_package(work_package.id)}?timestamps=#{timestamps_param}" }

    describe "response body" do
      subject do
        get get_path
        last_response.body
      end

      context "when providing timestamps" do
        let(:timestamps) { [Timestamp.parse("2015-01-01T00:00:00Z"), Timestamp.now] }
        let(:baseline_time) { timestamps.first.to_time }
        let(:created_at) { baseline_time - 1.day }

        let(:work_package) do
          create(:work_package,
                 subject: "The current work package",
                 journals: {
                   created_at => { subject: "The original work package" },
                   # This journal creation conflicts with the timestamp "P-1D" due to timing issues.
                   # P-1D is always evaluated to the current time at runtime, thus we cannot control that.
                   # To solve the issue, we modify the journal's creation time, we add 1 second to it.
                   1.day.ago + 1 => {}
                 })
        end
        let(:original_journal) { work_package.journals.first }
        let(:current_journal) { work_package.journals.last }

        context "with EE", with_ee: %i[baseline_comparison] do
          it "responds with 200" do
            expect(subject && last_response).to have_http_status(:ok)
          end

          it "has the current attributes as attributes" do
            expect(subject)
              .to be_json_eql("The current work package".to_json)
              .at_path("subject")
          end

          it "has an embedded link to the baseline work package" do
            expect(subject)
              .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
              .at_path("_embedded/attributesByTimestamp/0/_links/self/href")
          end

          it "has the absolute timestamps within the self link" do
            Timecop.freeze do
              expect(subject)
                .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.map(&:absolute)).to_json)
                .at_path("_links/self/href")
            end
          end

          describe "attributesByTimestamp" do
            it "embeds the attributesByTimestamp" do
              expect(subject)
                .to be_json_eql("The original work package".to_json)
                .at_path("_embedded/attributesByTimestamp/0/subject")
              expect(subject)
                .to have_json_path("_embedded/attributesByTimestamp/1")
            end

            it "does not embed the attributes in attributesByTimestamp if they are the same as the current attributes" do
              expect(subject)
                .not_to have_json_path("_embedded/attributesByTimestamp/0/description")
              expect(subject)
                .not_to have_json_path("_embedded/attributesByTimestamp/1/description")
            end

            describe "_meta" do
              describe "timestamp" do
                it "has the relative timestamps" do
                  expect(subject)
                    .to be_json_eql("2015-01-01T00:00:00Z".to_json)
                    .at_path("_embedded/attributesByTimestamp/0/_meta/timestamp")
                  expect(subject)
                    .to be_json_eql("PT0S".to_json)
                    .at_path("_embedded/attributesByTimestamp/1/_meta/timestamp")
                end
              end
            end
          end

          describe "when the work package has not been present at the baseline time" do
            let(:timestamps) { [Timestamp.parse("2015-01-01T00:00:00Z"), Timestamp.now] }
            let(:created_at) { 10.days.ago }

            describe "attributesByTimestamp" do
              describe "exists" do
                it "marks the work package as not existing at the baseline time" do
                  expect(subject)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/attributesByTimestamp/0/_meta/exists")
                end

                it "marks the work package as existing at the current time" do
                  expect(subject)
                    .to be_json_eql(true.to_json)
                    .at_path("_embedded/attributesByTimestamp/1/_meta/exists")
                end
              end
            end

            describe "_meta" do
              describe "exits" do
                it "is true because the work package does exist at the last given timestamp" do
                  expect(subject)
                    .to be_json_eql(true.to_json)
                    .at_path("_meta/exists")
                end
              end
            end
          end

          describe "when the work package does not exist at the only requested timestamp" do
            let(:timestamps) { [Timestamp.parse("2015-01-01T00:00:00Z")] }
            let(:created_at) { 10.days.ago }

            describe "attributesByTimestamp" do
              describe "exists" do
                it "marks the work package as not existing at the requested time" do
                  expect(subject)
                    .to be_json_eql(false.to_json)
                    .at_path("_embedded/attributesByTimestamp/0/_meta/exists")
                end
              end
            end

            describe "_meta" do
              describe "exits" do
                it "is false because the work package does not exist at the requested timestamp" do
                  expect(subject)
                    .to be_json_eql(false.to_json)
                    .at_path("_meta/exists")
                end
              end
            end
          end

          context "with caching" do
            context "with relative timestamps" do
              let(:timestamps) { [Timestamp.parse("P-2D"), Timestamp.now] }
              let(:created_at) { Date.parse("2015-01-01") }

              describe "attributesByTimestamp" do
                it "does not cache the self link" do
                  get get_path
                  expect do
                    Timecop.travel 20.minutes do
                      get get_path
                    end
                  end.to change {
                    JSON.parse(last_response.body)
                      .dig("_embedded", "attributesByTimestamp", 0, "_links", "self", "href")
                  }
                end

                it "does not cache the attributes" do
                  get get_path
                  expect do
                    Timecop.travel 2.days do
                      get get_path
                    end
                  end.to change {
                    JSON.parse(last_response.body)
                      .dig("_embedded", "attributesByTimestamp", 0, "subject")
                  }
                end
              end

              describe "_meta" do
                describe "exists" do
                  let(:timestamps) { [Timestamp.parse("P-2D")] }
                  let(:created_at) { 25.hours.ago }

                  it "is not cached" do
                    get get_path
                    expect do
                      Timecop.travel 2.days do
                        get get_path
                      end
                    end.to change {
                      JSON.parse(last_response.body)
                        .dig("_meta", "exists")
                    }
                  end
                end
              end
            end
          end

          context "when the timestamps are relative date keywords" do
            let(:timestamps) { [Timestamp.new("oneWeekAgo@12:00+00:00"), Timestamp.now] }

            it "has an embedded link to the baseline work package" do
              expect(subject)
                .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
                .at_path("_embedded/attributesByTimestamp/0/_links/self/href")
            end

            it "has the absolute timestamps within the self link" do
              Timecop.freeze do
                expect(subject)
                  .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.map(&:absolute)).to_json)
                  .at_path("_links/self/href")
              end
            end

            describe "attributesByTimestamp" do
              describe "_meta" do
                describe "timestamp" do
                  it "has the relative timestamps" do
                    expect(subject)
                      .to be_json_eql("oneWeekAgo@12:00+00:00".to_json)
                      .at_path("_embedded/attributesByTimestamp/0/_meta/timestamp")
                    expect(subject)
                      .to be_json_eql("PT0S".to_json)
                      .at_path("_embedded/attributesByTimestamp/1/_meta/timestamp")
                  end
                end
              end
            end

            context "with caching" do
              context "with relative timestamps" do
                let(:timestamps) { [Timestamp.parse("oneDayAgo@00:00+00:00"), Timestamp.now] }
                let(:created_at) { Date.parse("2015-01-01") }

                describe "attributesByTimestamp" do
                  it "does not cache the self link" do
                    get get_path

                    expect do
                      # Travel 1 day to test the href not being cached, because the
                      # relative date keyword has a fixed hour part, which means the timestamp
                      # will change its value only in 1 day units
                      Timecop.travel 1.day do
                        get get_path
                      end
                    end.to change {
                      JSON.parse(last_response.body)
                        .dig("_embedded", "attributesByTimestamp", 0, "_links", "self", "href")
                    }
                  end

                  it "does not cache the attributes" do
                    get get_path
                    expect do
                      Timecop.travel 2.days do
                        get get_path
                      end
                    end.to change {
                      JSON.parse(last_response.body)
                        .dig("_embedded", "attributesByTimestamp", 0, "subject")
                    }
                  end
                end

                describe "_meta" do
                  describe "exists" do
                    let(:timestamps) { [Timestamp.parse("oneDayAgo@00:00+00:00")] }
                    let(:created_at) { 25.hours.ago }

                    it "is not cached" do
                      get get_path
                      expect do
                        Timecop.travel 2.days do
                          get get_path
                        end
                      end.to change {
                        JSON.parse(last_response.body)
                          .dig("_meta", "exists")
                      }
                    end
                  end
                end
              end
            end
          end
        end

        context "without EE" do
          shared_examples "success" do
            it "responds with 200" do
              expect(subject && last_response).to have_http_status(:ok)
            end
          end

          shared_examples "error" do
            it "responds with 400" do
              expect(subject && last_response).to have_http_status(:bad_request)
            end

            it "has the invalid timestamps message" do
              message = JSON.parse(subject)["message"]
              expect(message)
                .to eq("Bad request: Timestamps contain forbidden values: #{timestamps.join(',')}")
            end
          end

          context "when the 'oneDayAgo' value is provided" do
            let(:timestamps) { [Timestamp.parse("oneDayAgo@12:00+00:00")] }

            it_behaves_like "success"
          end

          context "when the shortcut value 'now' is provided" do
            let(:timestamps) { [Timestamp.parse("now")] }

            it_behaves_like "success"
          end

          context "when the 'PT0S' duration value is provided" do
            let(:timestamps) { [Timestamp.parse("PT0S")] }

            it_behaves_like "success"
          end

          context "when the 'P-1D' duration value is provided" do
            let(:timestamps) { [Timestamp.parse("P-1D")] }

            it_behaves_like "success"
          end

          context "when an iso8601 datetime value from yesterday is provided" do
            let(:timestamps) { [1.day.ago.beginning_of_day.iso8601] }

            it_behaves_like "success"
          end

          context "when the 'lastWorkingDay' value is provided and it's yesterday" do
            let(:timestamps) { [Timestamp.parse("lastWorkingDay@00:00+00:00")] }

            it_behaves_like "success"
          end

          Timestamp::ALLOWED_DATE_KEYWORDS[2..].each do |timestamp_date_keyword|
            context "when the '#{timestamp_date_keyword}' value is provided" do
              let(:timestamps) { [Timestamp.parse("#{timestamp_date_keyword}@12:00+00:00")] }

              it_behaves_like "error"
            end
          end

          context "when the 'lastWorkingDay' value is provided and it's before yesterday" do
            let(:timestamps) { [Timestamp.parse("lastWorkingDay@00:00+00:00")] }

            before do
              allow(Day).to receive(:last_working) { Day.new(date: 7.days.ago) }
            end

            it_behaves_like "error"
          end

          context "when a duration value older than yesterday is provided" do
            let(:timestamps) { [Timestamp.parse("P-2D")] }

            it_behaves_like "error"
          end

          context "when an iso8601 datetime value older than yesterday is provided" do
            let(:timestamps) { [2.days.ago.end_of_day.iso8601] }

            it_behaves_like "error"
          end
        end
      end
    end
  end
end

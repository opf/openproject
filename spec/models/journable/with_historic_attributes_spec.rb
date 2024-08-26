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

RSpec.describe Journable::WithHistoricAttributes,
               with_ee: %i[baseline_comparison] do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:baseline_time) { "2022-01-01".to_time }
  shared_let(:created_at) { baseline_time - 1.day }

  shared_let(:project) { create(:project) }
  shared_let(:work_package1) do
    create(:work_package,
           subject: "The current work package 1",
           project:,
           journals: {
             created_at => { subject: "The original work package 1" },
             1.day.ago => {}
           })
  end
  shared_let(:work_package2) do
    create(:work_package,
           subject: "The current work package 2",
           project:,
           start_date: created_at - 3.days,
           journals: {
             created_at => { subject: "The original work package 2", start_date: created_at - 5.days },
             1.day.ago => {}
           })
  end
  shared_let(:original_journal_wp1) { work_package1.journals.first }
  shared_let(:current_journal_wp1) { work_package1.last_journal }
  shared_let(:original_journal_wp2) { work_package2.journals.first }
  shared_let(:current_journal_wp2) { work_package2.last_journal }

  let(:user1) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_permissions: { project => %i[view_work_packages view_file_links] })
  end
  let(:build_query) do
    build(:query, user: nil, project: nil).tap do |query|
      query.filters.clear
      query.add_filter "subject", "~", search_term
    end
  end

  let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
  let(:query) { nil }
  let(:include_only_changed_attributes) { nil }

  current_user { user1 }

  subject { described_class.wrap(work_packages, timestamps:, query:, include_only_changed_attributes:) }

  describe ".wrap" do
    context "with a single work package" do
      let(:work_packages) { work_package1 }

      it "returns a Journable::WithHistoricAttributes instance" do
        expect(subject).to be_a described_class
      end
    end

    context "with an array of work packages" do
      let(:work_packages) { [work_package1, work_package2] }

      it "returns an array of Journable::WithHistoricAttributes instances" do
        expect(subject).to all be_a described_class
      end
    end

    context "with active record relation of work packages" do
      let(:work_packages) { WorkPackage.all }

      it "returns an array of Journable::WithHistoricAttributes instances" do
        expect(subject).to all be_a described_class
      end
    end
  end

  describe "delegation to original object" do
    context "with a single work package" do
      let(:work_packages) { work_package1 }

      it "provides access to the work-package attributes" do
        expect(subject.subject).to eq "The current work package 1"
      end

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "provides access to the historic work-package attributes" do
          expect(subject.subject).to eq "The original work package 1"
        end
      end

      describe "when the work package did not exist yet at the baseline date" do
        let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }

        it "provides access to the work-package attributes" do
          expect(subject.subject).to eq "The current work package 1"
        end
      end

      describe "when the work package did not exist at the only requested date" do
        let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z")] }

        it "has no attributes" do
          expect(subject.attributes).to be_empty
        end
      end
    end

    context "with an array of work packages" do
      let(:work_packages) { [work_package1, work_package2] }

      it "provides access to the work-package attributes" do
        expect(subject.map(&:subject)).to eq ["The current work package 1", "The current work package 2"]
      end
    end

    context "with active record relation of work packages" do
      let(:work_packages) { WorkPackage.all }

      it "provides access to the work-package attributes" do
        expect(subject.map(&:subject)).to eq ["The current work package 1", "The current work package 2"]
      end

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "provides access to the historic work-package attributes" do
          expect(subject.map(&:subject)).to eq ["The original work package 1", "The original work package 2"]
        end
      end
    end
  end

  describe "#attributes_by_timestamp" do
    let(:work_packages) { work_package1 }

    context "with a single work package" do
      it "provides access to the work-package attributes at timestamps" do
        expect(subject.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        expect(subject.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 1"
      end

      describe "with include_only_changed_attributes: true" do
        let(:include_only_changed_attributes) { true }

        it "provides access to the work-package attributes at timestamps " \
           "where the attribute is different from the work package's attribute" do
          expect(subject.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        end

        specify "the attributes at timestamps do not include attributes that are the same as the work package's attribute" do
          expect(subject.attributes_by_timestamp["PT0S"].subject).to be_nil
        end
      end

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "provides access to the historic work-package attributes at timestamps" do
          expect(subject.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        end
      end

      describe "when the work package did not exist yet at the baseline date" do
        let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }

        it "has no attributes at the baseline date" do
          expect(subject.attributes_by_timestamp["2021-01-01T00:00:00Z"]).to be_nil
        end
      end

      describe "when the work package did not exist at the only requested date" do
        let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z")] }

        it "has no attributes at the baseline date, which is the only given date" do
          expect(subject.attributes_by_timestamp["2021-01-01T00:00:00Z"]).to be_nil
        end
      end
    end

    context "with an array of work packages" do
      let(:work_packages) { [work_package1, work_package2] }

      it "provides access to the work-package attributes at timestamps" do
        expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        expect(subject.first.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 1"
        expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        expect(subject.last.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 2"
      end

      describe "with include_only_changed_attributes: true" do
        let(:include_only_changed_attributes) { true }

        it "provides access to the work-package attributes at timestamps " \
           "where the attribute is different from the work package's attribute" do
          expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        end

        specify "the attributes at timestamps do not include attributes that are the same as the work package's attribute" do
          expect(subject.first.attributes_by_timestamp["PT0S"].subject).to be_nil
        end
      end

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "provides access to the historic work-package attributes at timestamps" do
          expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
          expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        end
      end
    end

    context "with active record relation of work packages" do
      let(:work_packages) { WorkPackage.all }

      it "provides access to the work-package attributes at timestamps" do
        expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        expect(subject.first.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 1"
        expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        expect(subject.last.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 2"
      end

      describe "with include_only_changed_attributes: true" do
        let(:include_only_changed_attributes) { true }

        it "provides access to the work-package attributes at timestamps " \
           "where the attribute is different from the work package's attribute" do
          expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        end

        specify "the attributes at timestamps do not include attributes that are the same as the work package's attribute" do
          expect(subject.first.attributes_by_timestamp["PT0S"].subject).to be_nil
        end
      end

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "provides access to the historic work-package attributes at timestamps" do
          expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
          expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        end
      end
    end
  end

  describe "#exists_at_timestamps" do
    context "with a single work package" do
      let(:work_packages) { work_package1 }

      it "determines for each timestamp whether the journable exists at that timestamp" do
        expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
        expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
      end

      context "with the work package not being visible currently" do
        let(:other_project) { create(:project) }

        before do
          current_journal_wp1.data.update_column(:project_id, other_project.id)
          work_package1.update_column(:project_id, other_project.id)
        end

        it "reports the work package to only exist in former times" do
          expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.exists_at_timestamps).not_to include Timestamp.parse("PT0S")
        end
      end

      context "with the work package not having been visible before but being visible now" do
        let(:other_project) { create(:project) }

        before do
          original_journal_wp1.data.update_column(:project_id, other_project.id)
        end

        it "reports the work package to not exist at that point in time" do
          expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
        end
      end

      describe "when providing a query" do
        let(:query) { build_query }
        let(:search_term) { "original" }

        describe "when the work package did not exist yet at the basline date" do
          let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
          let(:search_term) { "current" }

          it "does not include the timestamp in the exists_at_timestamps array" do
            expect(subject.exists_at_timestamps).not_to include Timestamp.parse("2021-01-01T00:00:00Z")
            expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
          end
        end
      end

      describe "with include_only_changed_attributes: true" do
        let(:include_only_changed_attributes) { true }

        it "includes the timestamps in the exists_at_timestamps array" do
          expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
        end
      end

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "includes the timestamp in the exists_at_timestamps array" do
          expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
        end
      end

      describe "when the work package did not exist yet at the baseline date" do
        let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }

        it "does not include the timestamp in the exists_at_timestamps array" do
          expect(subject.exists_at_timestamps).not_to include Timestamp.parse("2021-01-01T00:00:00Z")
          expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
        end
      end

      describe "when the work package did not exist at the only requested date" do
        let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z")] }

        it "does not include the timestamp in the exists_at_timestamps array" do
          expect(subject.exists_at_timestamps).not_to include Timestamp.parse("2021-01-01T00:00:00Z")
        end
      end
    end
  end

  describe "#at_timestamp" do
    context "with a single work package" do
      let(:work_packages) { work_package1 }

      it "returns the journable at a former time it existed with the attributes set to the former values" do
        expect(subject.at_timestamp(Timestamp.parse("2022-01-01T00:00:00Z")).attributes.slice("subject", "id"))
                      .to eq("subject" => "The original work package 1",
                             "id" => work_package1.id)
      end

      it "returns the journable at the current time" do
        expect(subject.at_timestamp(Timestamp.parse("PT0S")).attributes.slice("subject", "id"))
          .to eq("subject" => "The current work package 1",
                 "id" => work_package1.id)
      end

      it "returns nil for a time it did not exist yet" do
        expect(subject.at_timestamp(Timestamp.parse("2021-01-01T00:00:00Z")))
          .to be_nil
      end

      context "with the work package not being visible currently" do
        let(:other_project) { create(:project) }

        before do
          current_journal_wp1.data.update_column(:project_id, other_project.id)
          work_package1.update_column(:project_id, other_project.id)
        end

        it "returns the journable at a former time it existed with the attributes set to the former values" do
          expect(subject.at_timestamp(Timestamp.parse("2022-01-01T00:00:00Z")).attributes.slice("subject", "id"))
            .to eq("subject" => "The original work package 1",
                   "id" => work_package1.id)
        end

        it "returns nil at the current time" do
          expect(subject.at_timestamp(Timestamp.parse("PT0S")))
            .to be_nil
        end
      end

      context "with the work package not having been visible before but being visible now" do
        let(:other_project) { create(:project) }

        before do
          original_journal_wp1.data.update_column(:project_id, other_project.id)
        end

        it "returns the journable at a former time it existed (and was invisible) with the attributes set to the former values" do
          expect(subject.at_timestamp(Timestamp.parse("2022-01-01T00:00:00Z")).attributes.slice("subject", "id"))
            .to eq("subject" => "The original work package 1",
                   "id" => work_package1.id)
        end

        it "returns the journable at the current time" do
          expect(subject.at_timestamp(Timestamp.parse("PT0S")).attributes.slice("subject", "id"))
            .to eq("subject" => "The current work package 1",
                   "id" => work_package1.id)
        end
      end
    end
  end

  describe "#historic?" do
    context "with a single work package" do
      let(:work_packages) { work_package1 }

      it "determines whether the journable attributes are historic" do
        expect(subject.historic?).to be false
      end

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "determines whether the journable attributes are historic" do
          expect(subject.historic?).to be true
        end
      end
    end

    context "with an array of work packages" do
      let(:work_packages) { [work_package1, work_package2] }

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "determines whether the journable attributes are historic" do
          expect(subject).to all be_historic
        end
      end
    end

    context "with active record relation of work packages" do
      let(:work_packages) { WorkPackage.all }

      describe "when requesting only historic data" do
        let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

        it "determines whether the journable attributes are historic" do
          expect(subject).to all be_historic
        end
      end
    end
  end

  describe "#matches_query_filters_at_timestamps" do
    let(:query) { build_query }
    let(:search_term) { "original" }

    context "with a single work package" do
      let(:work_packages) { work_package1 }

      describe "when providing a query" do
        it "determines for each timestamp whether the journable matches the query at that timestamp" do
          expect(subject.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
        end

        describe "when the work package did not exist yet at the baseline date" do
          let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
          let(:search_term) { "current" }

          it "does not include the timestamp in the matches_query_filters_at_timestamps array" do
            expect(subject.matches_query_filters_at_timestamps).not_to include Timestamp.parse("2021-01-01T00:00:00Z")
            expect(subject.matches_query_filters_at_timestamps).to include Timestamp.parse("PT0S")
          end
        end
      end
    end

    context "with an array of work packages" do
      let(:work_packages) { [work_package1, work_package2] }

      describe "when providing a query" do
        it "determines for each timestamp whether the journables matches the query at that timestamp" do
          expect(subject.first.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.first.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
          expect(subject.last.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.last.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
        end
      end
    end

    context "with active record relation of work packages" do
      let(:work_packages) { WorkPackage.all }

      describe "when providing a query" do
        it "determines for each timestamp whether the journables matches the query at that timestamp" do
          expect(subject.first.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.first.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
          expect(subject.last.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.last.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
        end
      end
    end
  end

  describe "#baseline_timestamp" do
    let(:journable) { described_class.wrap(work_package1, timestamps:) }

    subject { journable.baseline_timestamp }

    it "provides simplified access to the baseline timestamp, which is the first given timestamp" do
      expect(subject).to eq Timestamp.parse("2022-01-01T00:00:00Z")
    end
  end

  describe "#baseline_attributes" do
    let(:journable) { described_class.wrap(work_package1, timestamps:) }

    subject { journable.baseline_attributes }

    it "provides access to the work-package attributes at the baseline timestamp" do
      expect(subject.subject).to eq "The original work package 1"
    end

    describe "when the work package did not exist yet at the baseline date" do
      let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }

      it "has no baseline attributes" do
        expect(subject).to be_nil
      end
    end

    describe "when the work package did not exist at the only requested date" do
      let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z")] }

      it "has no baseline attributes" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#matches_query_filters_at_baseline_timestamp?" do
    let(:journable) { described_class.wrap(work_package1, timestamps:, query:) }
    let(:query) { build_query }

    subject { journable.matches_query_filters_at_baseline_timestamp? }

    describe "providing a filter that matches at the baseline timestamp" do
      let(:search_term) { "original" }

      it "determines whether the journable matches the query at the baseline timestamp" do
        expect(subject).to be true
      end
    end

    describe "providing a filter that matches at the current timestamp" do
      let(:search_term) { "current" }

      it "determines whether the journable matches the query at the baseline timestamp" do
        expect(subject).to be false
      end
    end
  end

  describe "#current_timestamp" do
    let(:journable) { described_class.wrap(work_package1, timestamps:) }

    subject { journable.current_timestamp }

    it "provides simplified access to the current timestamp, which is the last given timestamp" do
      expect(subject).to eq Timestamp.parse("PT0S")
    end
  end

  describe "#changed_at_timestamp" do
    subject { described_class.wrap(work_package1, timestamps:) }

    context "for a timestamp where the work package did exist" do
      it "returns the changed attributes at the timestamp compared to the current attribute values" do
        expect(subject.changed_at_timestamp(Timestamp.parse("2022-01-01T00:00:00Z")))
          .to contain_exactly("subject")
      end

      context "when the work package includes custom field changes" do
        let!(:custom_field) do
          create(:string_wp_custom_field,
                 name: "String CF",
                 types: project.types,
                 projects: [project])
        end

        let!(:custom_value) do
          create(:custom_value,
                 custom_field:,
                 customized: work_package1,
                 value: "This is a string value")
        end

        it "returns the changed attributes including custom fields at the timestamp compared to the current attribute values" do
          expect(subject.changed_at_timestamp(Timestamp.parse("2022-01-01T00:00:00Z")))
            .to contain_exactly "subject", "custom_field_#{custom_field.id}"
        end
      end
    end

    context "for a timestamp where the work package did not exist" do
      it "returns no changes" do
        expect(subject.changed_at_timestamp(Timestamp.parse("2021-01-01T00:00:00Z")))
          .to be_empty
      end
    end
  end
end

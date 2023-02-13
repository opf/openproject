#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

describe Journable::WithHistoricAttributes do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:baseline_time) { "2022-01-01".to_time }
  shared_let(:created_at) { baseline_time - 1.day }

  shared_let(:work_package1) do
    new_work_package = create(:work_package, subject: "The current work package 1")
    new_work_package.update_columns(created_at:)
    new_work_package
  end
  shared_let(:original_journal_wp1) do
    work_package1.journals.destroy_all
    create_journal(journable: work_package1,
                   timestamp: created_at,
                   version: 1,
                   attributes: { subject: "The original work package 1" })
  end
  shared_let(:current_journal_wp2) do
    create_journal(journable: work_package1,
                   timestamp: 1.day.ago,
                   version: 2,
                   attributes: { subject: "The current work package 1" })
  end

  shared_let(:work_package2) do
    new_work_package = create(:work_package,
                              project: work_package1.project,
                              subject: "The current work package 2",
                              start_date: created_at - 3.days)
    new_work_package.update_columns(created_at:)
    new_work_package
  end
  shared_let(:original_journal_wp2) do
    work_package2.journals.destroy_all
    create_journal(journable: work_package2,
                   timestamp: created_at,
                   version: 1,
                   attributes: { start_date: created_at - 5.days,
                                 subject: "The original work package 2" })
  end
  shared_let(:current_journal_wp2) do
    create_journal(journable: work_package2,
                   timestamp: 1.day.ago,
                   version: 2,
                   attributes: { start_date: created_at - 3.days,
                                 subject: "The current work package 2" })
  end

  let(:user1) do
    create(:user,
           firstname: 'user',
           lastname: '1',
           member_in_project: work_package1.project,
           member_with_permissions: %i[view_work_packages view_file_links])
  end

  def create_journal(journable:, version:, timestamp:, attributes: {})
    work_package_attributes = journable.attributes.except("id")
    journal_attributes = work_package_attributes \
        .extract!(*Journal::WorkPackageJournal.attribute_names) \
        .symbolize_keys.merge(attributes)
    create(:work_package_journal, version:,
                                  journable:, created_at: timestamp, updated_at: timestamp,
                                  data: build(:journal_work_package_journal, journal_attributes))
  end

  describe ".wrap" do
    let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
    let(:query) { nil }
    let(:include_only_changed_attributes) { nil }

    subject { described_class.wrap(work_package1, timestamps:, query:, include_only_changed_attributes:) }

    it "returns a Journable::WithHistoricAttributes instance" do
      expect(subject).to be_a described_class
    end

    it "provides access to the work-package attributes" do
      expect(subject.subject).to eq "The current work package 1"
    end

    it "provides access to the work-package attributes at timestamps" do
      expect(subject.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
      expect(subject.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 1"
    end

    it "determines for each timestamp whether the journable exists at that timestamp" do
      expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
      expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
    end

    it "determines whether the journable attributes are historic" do
      expect(subject.historic?).to be false
    end

    describe "when providing a query" do
      let(:query) do
        login_as(user1)
        build(:query, user: nil, project: nil).tap do |query|
          query.filters.clear
          query.add_filter 'subject', '~', search_term
        end
      end
      let(:search_term) { "original" }

      it "determines for each timestamp whether the journable matches the query at that timestamp" do
        expect(subject.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
        expect(subject.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
      end

      describe "when the work package did not exist yet at the basline date" do
        let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
        let(:search_term) { "current" }

        it "does not include the timestamp in the matches_query_filters_at_timestamps array" do
          expect(subject.matches_query_filters_at_timestamps).not_to include Timestamp.parse("2021-01-01T00:00:00Z")
          expect(subject.matches_query_filters_at_timestamps).to include Timestamp.parse("PT0S")
        end

        it "does not include the timestamp in the exists_at_timestamps array" do
          expect(subject.exists_at_timestamps).not_to include Timestamp.parse("2021-01-01T00:00:00Z")
          expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
        end
      end
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

      it "includes the timestamps in the exists_at_timestamps array" do
        expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
        expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
      end
    end

    describe "when requesting only historic data" do
      let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z")] }

      it "provides access to the historic work-package attributes" do
        expect(subject.subject).to eq "The original work package 1"
      end

      it "provides access to the historic work-package attributes at timestamps" do
        expect(subject.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
      end

      it "determines whether the journable attributes are historic" do
        expect(subject.historic?).to be true
      end

      it "includes the timestamp in the exists_at_timestamps array" do
        expect(subject.exists_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
      end
    end

    describe "when the work package did not exist yet at the basline date" do
      let(:timestamps) { [Timestamp.parse("2021-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }

      it "provides access to the work-package attributes" do
        expect(subject.subject).to eq "The current work package 1"
      end

      it "has no attributes at the baseline date" do
        expect(subject.attributes_by_timestamp["2021-01-01T00:00:00Z"]).to be_nil
      end

      it "has no baseline attributes" do
        expect(subject.baseline_attributes).to be_nil
      end

      it "does not include the timestamp in the exists_at_timestamps array" do
        expect(subject.exists_at_timestamps).not_to include Timestamp.parse("2021-01-01T00:00:00Z")
        expect(subject.exists_at_timestamps).to include Timestamp.parse("PT0S")
      end
    end
  end

  describe ".wrap_multiple" do
    let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
    let(:query) { nil }
    let(:include_only_changed_attributes) { nil }

    subject { described_class.wrap_multiple(work_packages, timestamps:, query:, include_only_changed_attributes:) }

    context "with a single work package" do
      let(:work_packages) { [work_package1, work_package2] }

      it "returns an array of Journable::WithHistoricAttributes instances" do
        expect(subject).to all be_a described_class
      end

      it "provides access to the work-package attributes" do
        expect(subject.first.subject).to eq "The current work package 1"
      end

      it "provides access to the work-package attributes at timestamps" do
        expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        expect(subject.first.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 1"
      end

      describe "when providing a query" do
        let(:query) do
          login_as(user1)
          build(:query, user: nil, project: nil).tap do |query|
            query.filters.clear
            query.add_filter 'subject', '~', search_term
          end
        end
        let(:search_term) { "original" }

        it "determines for each timestamp whether the journables matches the query at that timestamp" do
          expect(subject.first.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.first.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
        end
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

        it "provides access to the historic work-package attributes" do
          expect(subject.first.subject).to eq "The original work package 1"
        end

        it "provides access to the historic work-package attributes at timestamps" do
          expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        end

        it "determines whether the journable attributes are historic" do
          expect(subject.first.historic?).to be true
        end
      end
    end

    context "with an array of work packages" do
      let(:work_packages) { [work_package1, work_package2] }

      it "returns an array of Journable::WithHistoricAttributes instances" do
        expect(subject).to all be_a described_class
      end

      it "provides access to the work-package attributes" do
        expect(subject.map(&:subject)).to eq ["The current work package 1", "The current work package 2"]
      end

      it "provides access to the work-package attributes at timestamps" do
        expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        expect(subject.first.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 1"
        expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        expect(subject.last.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 2"
      end

      describe "when providing a query" do
        let(:query) do
          login_as(user1)
          build(:query, user: nil, project: nil).tap do |query|
            query.filters.clear
            query.add_filter 'subject', '~', search_term
          end
        end
        let(:search_term) { "original" }

        it "determines for each timestamp whether the journables matches the query at that timestamp" do
          expect(subject.first.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.first.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
          expect(subject.last.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.last.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
        end
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

        it "provides access to the historic work-package attributes" do
          expect(subject.map(&:subject)).to eq ["The original work package 1", "The original work package 2"]
        end

        it "provides access to the historic work-package attributes at timestamps" do
          expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
          expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        end

        it "determines whether the journable attributes are historic" do
          expect(subject).to all be_historic
        end
      end
    end

    context "with an AR of work packages" do
      let(:work_packages) { WorkPackage.all }

      it "returns an array of Journable::WithHistoricAttributes instances" do
        expect(subject).to all be_a described_class
      end

      it "provides access to the work-package attributes" do
        expect(subject.map(&:subject)).to eq ["The current work package 1", "The current work package 2"]
      end

      it "provides access to the work-package attributes at timestamps" do
        expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
        expect(subject.first.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 1"
        expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        expect(subject.last.attributes_by_timestamp["PT0S"].subject).to eq "The current work package 2"
      end

      describe "when providing a query" do
        let(:query) do
          login_as(user1)
          build(:query, user: nil, project: nil).tap do |query|
            query.filters.clear
            query.add_filter 'subject', '~', search_term
          end
        end
        let(:search_term) { "original" }

        it "determines for each timestamp whether the journables matches the query at that timestamp" do
          expect(subject.first.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.first.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
          expect(subject.last.matches_query_filters_at_timestamps).to include Timestamp.parse("2022-01-01T00:00:00Z")
          expect(subject.last.matches_query_filters_at_timestamps).not_to include Timestamp.parse("PT0S")
        end
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

        it "provides access to the historic work-package attributes" do
          expect(subject.map(&:subject)).to eq ["The original work package 1", "The original work package 2"]
        end

        it "provides access to the historic work-package attributes at timestamps" do
          expect(subject.first.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 1"
          expect(subject.last.attributes_by_timestamp["2022-01-01T00:00:00Z"].subject).to eq "The original work package 2"
        end

        it "determines whether the journable attributes are historic" do
          expect(subject).to all be_historic
        end
      end
    end
  end

  describe "#baseline_timestamp" do
    let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
    let(:journable) { described_class.wrap(work_package1, timestamps:) }

    subject { journable.baseline_timestamp }

    it "provides simplified access to the baseline timestamp, which is the first given timestamp" do
      expect(subject).to eq Timestamp.parse("2022-01-01T00:00:00Z")
    end
  end

  describe "#baseline_attributes" do
    let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
    let(:journable) { described_class.wrap(work_package1, timestamps:) }

    subject { journable.baseline_attributes }

    it "provides access to the work-package attributes at the baseline timestamp" do
      expect(subject.subject).to eq "The original work package 1"
    end
  end

  describe "#matches_query_filters_at_baseline_timestamp?" do
    let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
    let(:journable) { described_class.wrap(work_package1, timestamps:, query:) }
    let(:query) do
      login_as(user1)
      build(:query, user: nil, project: nil).tap do |query|
        query.filters.clear
        query.add_filter 'subject', '~', search_term
      end
    end

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
    let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
    let(:journable) { described_class.wrap(work_package1, timestamps:) }

    subject { journable.current_timestamp }

    it "provides simplified access to the current timestamp, which is the last given timestamp" do
      expect(subject).to eq Timestamp.parse("PT0S")
    end
  end

  describe "#matches_query_filters_at_current_timestamp?" do
    let(:timestamps) { [Timestamp.parse("2022-01-01T00:00:00Z"), Timestamp.parse("PT0S")] }
    let(:journable) { described_class.wrap(work_package1, timestamps:, query:) }
    let(:query) do
      login_as(user1)
      build(:query, user: nil, project: nil).tap do |query|
        query.filters.clear
        query.add_filter 'subject', '~', search_term
      end
    end

    subject { journable.matches_query_filters_at_current_timestamp? }

    describe "providing a filter that matches at the baseline timestamp" do
      let(:search_term) { "original" }

      it "determines whether the journable matches the query at the current timestamp" do
        expect(subject).to be false
      end
    end

    describe "providing a filter that matches at the current timestamp" do
      let(:search_term) { "current" }

      it "determines whether the journable matches the query at the current timestamp" do
        expect(subject).to be true
      end
    end
  end
end

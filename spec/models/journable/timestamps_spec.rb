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

RSpec.describe Journable::Timestamps do
  # See: https://github.com/opf/openproject/pull/11243

  let(:before_monday) { "2022-01-01".to_datetime }
  let(:monday) { "2022-08-01".to_datetime }
  let(:tuesday) { "2022-08-02".to_datetime }
  let(:wednesday) { "2022-08-03".to_datetime }
  let(:thursday) { "2022-08-04".to_datetime }
  let(:friday) { "2022-08-05".to_datetime }

  let(:project) { create(:project_with_types) }
  let!(:work_package) do
    create(:work_package,
           description: "The work package as it is since Friday",
           estimated_hours: 10,
           project:,
           journals: {
             monday => { description: "The work package as it has been on Monday", estimated_hours: 5 },
             wednesday => { description: "The work package as it has been on Wednesday", estimated_hours: 10 },
             friday => { description: "The work package as it is since Friday", estimated_hours: 15 }
           })
  end
  let(:journable) { work_package }

  describe "when there are journals for Monday, Wednesday, and Friday" do
    let(:monday_journal) do
      work_package.journals.find_by(created_at: monday)
    end
    let(:wednesday_journal) do
      work_package.journals.find_by(created_at: wednesday)
    end
    let(:friday_journal) do
      work_package.journals.find_by(created_at: friday)
    end

    describe ".at_timestamp" do
      let(:timestamp) { monday }

      subject { WorkPackage.at_timestamp(timestamp) }

      it "returns a historic active-record relation" do
        expect(subject).to be_a Journable::HistoricActiveRecordRelation
        expect(subject).to be_an ActiveRecord::Relation
      end

      describe "chaining a where clause" do
        subject { WorkPackage.at_timestamp(timestamp).where(assigned_to_id: 1) }

        it "still returns a historic active-record relation" do
          expect(subject).to be_a Journable::HistoricActiveRecordRelation
          expect(subject).to be_an ActiveRecord::Relation
        end
      end

      it "returns readonly objects" do
        expect(subject.first.readonly?).to be true
      end

      it "adds a `timestamp` property to the returned work packages" do
        expect(subject.first.timestamp).to eq timestamp.iso8601
      end

      it "returns the records with the journable id rather than the id of the journal record" do
        expect(subject.pluck(:id)).to eq [work_package.id]
        expect(subject.first.id).to eq work_package.id
      end

      describe ".at_timestamp(something before Monday)" do
        let(:timestamp) { before_monday }

        it "returns [] because before Monday, no journal exists" do
          expect(subject).to eq []
        end
      end

      describe ".at_timestamp(Monday)" do
        let(:timestamp) { monday }

        it "returns the work packages in their state of Monday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end

      describe ".at_timestamp(Tuesday)" do
        let(:timestamp) { tuesday }

        it "returns the work packages in their state of Monday because this is the most current on Tuesday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end

      describe ".at_timestamp(Wednesday)" do
        let(:timestamp) { wednesday }

        it "returns the work packages in their state of Wednesday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Wednesday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end

      describe ".at_timestamp(Thursday)" do
        let(:timestamp) { thursday }

        it "returns the work packages in their state of Wednesday because this is the most current on Thursday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Wednesday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end

      describe ".at_timestamp(Friday)" do
        let(:timestamp) { friday }

        it "returns the work packages in their state of Friday" do
          expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end

      describe ".at_timestamp(Monday and Friday)" do
        let(:timestamp) { [monday, friday] }

        it "returns the work packages two times, in their state on Monday and the one on Friday", :aggregate_failures do
          expect(subject.length)
            .to eq 2

          expect(subject.find { |wp| wp.timestamp == monday.iso8601 }.description)
            .to eq "The work package as it has been on Monday"

          expect(subject.find { |wp| wp.timestamp == friday.iso8601 }.description)
            .to eq "The work package as it is since Friday"
        end
      end

      describe ".at_timestamp(Monday and PT0S)" do
        let(:timestamp) { [monday, Timestamp.now] }

        it "returns the work packages two times, in their state on Monday and the one on Friday", :aggregate_failures do
          expect(subject.length)
            .to eq 2

          expect(subject.find { |wp| wp.timestamp == monday.iso8601 }.description)
            .to eq "The work package as it has been on Monday"

          expect(subject.find { |wp| wp.timestamp == "PT0S" }.description)
            .to eq "The work package as it is since Friday"
        end
      end

      describe "when filtering on a column that only matches in the past" do
        let(:relation) { WorkPackage.where(description: "The work package as it has been on Monday") }

        describe "when querying the timestamp where the column matches" do
          subject { relation.at_timestamp(monday) }

          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
          end
        end

        describe "when querying the timestamp where the column does not match" do
          subject { relation.at_timestamp(wednesday) }

          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end

        describe "when querying without at_timestamp" do
          subject { relation }

          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end
      end

      describe "when filtering on a column that only matches in the present" do
        let(:relation) { WorkPackage.where(description: "The work package as it is since Friday") }

        describe "when querying the timestamp where the column matches" do
          subject { relation.at_timestamp(friday) }

          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to be true
          end
        end

        describe "when querying the timestamp where the column does not match" do
          subject { relation.at_timestamp(wednesday) }

          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end

        describe "when querying without at_timestamp" do
          subject { relation }

          it "returns the matching records" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to be false
          end
        end
      end

      describe "when filtering with a negative condition" do
        let(:relation) { WorkPackage.where.not(description: "The work package as it is since Friday") }

        describe "when querying a timestamp where the column matches" do
          subject { relation.at_timestamp(tuesday) }

          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to be true
          end
        end

        describe "when querying a timestamp where the column does not match" do
          subject { relation.at_timestamp(friday) }

          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end
      end

      describe "when filtering on a column of an associated table" do
        let(:time_entry) do
          work_package.time_entries.create! user_id: User.first.id, hours: 1, activity_id: 1, project_id: create(:project).id,
                                            spent_on: monday, logged_by_id: User.first.id
        end
        let(:relation) { WorkPackage.joins(:time_entries).where(time_entries: { id: time_entry.id }) }

        describe "when querying with at_timestamp" do
          subject { relation.at_timestamp(friday) }

          it "joins the journable table rather than the journal-data table" do
            expect(subject.to_sql).not_to include \
              "INNER JOIN \"time_entries\" ON \"time_entries\".\"work_package_id\" = \"work_package_journals\".\"id\""
            expect(subject.to_sql).to include \
              "INNER JOIN \"time_entries\" ON \"time_entries\".\"work_package_id\" = \"journals\".\"journable_id\""
          end

          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to be true
          end
        end

        describe "when querying with a past timestamp" do
          # This is a case we have to watch out. Even if the association has been created later
          # this still finds the historic record.
          subject { relation.at_timestamp(wednesday) }

          it "returns still matches because at_timestamp only filters the journable journal and not the associated journal" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Wednesday"]
          end
        end

        describe "when querying without at_timestamp" do
          subject { relation }

          it "returns the matching records" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to be false
          end
        end
      end

      describe "when filtering on a historic relation" do
        subject { WorkPackage.at_timestamp(monday).where(description:) }

        describe "when the data on that point in history has no matches" do
          let(:description) { "The work package as it is since Friday" }

          it "returns []" do
            expect(subject).to eq []
          end
        end

        describe "when the data on that point in history has matches" do
          let(:description) { "The work package as it has been on Monday" }

          it "returns the matching records" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to be true
          end
        end
      end

      describe "when filtering on a historic relation with a negative condition" do
        subject { WorkPackage.at_timestamp(timestamp).where.not(description: "The work package as it is since Friday") }

        describe "when querying a timestamp where the column matches" do
          let(:timestamp) { tuesday }

          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to be true
          end
        end

        describe "when querying a timestamp where the column does not match" do
          let(:timestamp) { friday }

          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end
      end

      describe "when using the calculational function 'maximum'" do
        describe "without at_timestamp" do
          subject { WorkPackage.maximum(:estimated_hours) }

          it "returns the correct result for today" do
            expect(subject).to eq 10
          end
        end

        describe "after at_timestamp" do
          subject { WorkPackage.at_timestamp(monday).maximum(:estimated_hours) }

          it "returns the correct result for that timestamp" do
            expect(subject).to eq 5
          end
        end

        describe "before at_timestamp" do
          subject { WorkPackage.maximum(:estimated_hours).at_timestamp(monday) }

          it "returns an error because maximum returns a float rather than a relation" do
            expect { subject }.to raise_error NoMethodError
            expect(WorkPackage.maximum(:estimated_hours)).to be_a Float
          end
        end
      end

      describe "when using a GROUP BY COUNT query" do
        describe "without at_timestamp" do
          subject { WorkPackage.group(:estimated_hours).count }

          it "returns the correct result for today" do
            expect(subject).to eq({ 10.0 => 1 })
          end
        end

        describe "after at_timestamp" do
          subject { WorkPackage.at_timestamp(monday).group(:estimated_hours).count }

          it "returns the correct result for that timestamp" do
            expect(subject).to eq({ 5.0 => 1 })
          end
        end
      end

      describe "when using a GROUP BY COUNT HAVING query" do
        describe "without at_timestamp" do
          subject { WorkPackage.group(:estimated_hours).having("estimated_hours > 3").count }

          it "returns the correct result for today" do
            expect(subject).to eq({ 10.0 => 1 })
          end
        end

        describe "after at_timestamp" do
          subject { WorkPackage.at_timestamp(monday).group(:estimated_hours).having("estimated_hours > 3").count }

          it "returns the correct result for that timestamp" do
            expect(subject).to eq({ 5.0 => 1 })
          end
        end
      end

      describe "#created_at" do
        subject { WorkPackage.at_timestamp(timestamp).first.created_at }

        describe "for at_timestamp(before monday)" do
          let(:timestamp) { before_monday }

          it "raises an error because no result exists for that timestamp" do
            expect { subject }.to raise_error NoMethodError
          end
        end

        describe "for at_timestamp(monday)" do
          let(:timestamp) { monday }

          it "returns the date the record itself has been created" do
            expect(subject).to eq work_package.created_at
            expect(subject).to eq monday
          end
        end

        describe "for at_timestamp(tuesday)" do
          let(:timestamp) { tuesday }

          it "returns the date the record itself has been created" do
            expect(subject).to eq work_package.created_at
            expect(subject).to eq monday
          end
        end

        describe "for at_timestamp(wednesday)" do
          let(:timestamp) { wednesday }

          it "returns the date the record itself has been created" do
            expect(subject).to eq work_package.created_at
            expect(subject).to eq monday
          end
        end
      end

      describe "#updated_at" do
        subject { WorkPackage.at_timestamp(timestamp).first.updated_at }

        describe "for at_timestamp(before monday)" do
          let(:timestamp) { before_monday }

          it "raises an error because no result exists for that timestamp" do
            expect { subject }.to raise_error NoMethodError
          end
        end

        describe "for at_timestamp(monday)" do
          let(:timestamp) { monday }

          it "returns the date of the monday journal entry" do
            expect(subject).to eq monday
          end
        end

        describe "for at_timestamp(tuesday)" do
          let(:timestamp) { tuesday }

          it "returns the date of the monday journal entry" do
            expect(subject).to eq monday
          end
        end

        describe "for at_timestamp(wednesday)" do
          let(:timestamp) { wednesday }

          it "returns the date of the wednesday journal entry" do
            expect(subject).to eq wednesday
          end
        end
      end

      describe "when using historic queries as sub queries" do
        subject do
          sub_query = WorkPackage.at_timestamp(monday).where(description: "The work package as it has been on Monday")
          WorkPackage.where(id: sub_query)
        end

        it "returns the current records that have matched the filter on monday" do
          expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
        end

        describe "when plucking the id as sub query (workaround)" do
          subject do
            sub_query_ids = WorkPackage.at_timestamp(monday) \
                .where(description: "The work package as it has been on Monday") \
                .pluck(:id)
            WorkPackage.where(id: sub_query_ids)
          end

          it "returns the current records that have matched the filter on monday" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
          end
        end
      end

      describe "when chaining where(id:) in order to request specific work packages at a specific point in time" do
        subject { WorkPackage.where(id: [work_package.id]).at_timestamp(wednesday) }

        it "returns the work packages in their state at the requested point in time" do
          expect(subject.first.description).to eq "The work package as it has been on Wednesday"
        end

        describe "when the work package does not exist at the requested time" do
          subject { WorkPackage.where(id: [work_package.id]).at_timestamp(before_monday) }

          it "returns an empty result" do
            expect(subject.count).to eq 0
          end
        end
      end

      context "when including projects and filtering on it (e.g. done by the work package query)" do
        before do
          # Pretend the work package had been moved to a different project on wednesday
          wednesday_journal.data.update_column(:project_id, work_package.project_id + 1)
        end

        subject { WorkPackage.at_timestamp(timestamp).includes(:project).where(projects: { id: [work_package.project.id] }) }

        context "when the work package was in the filtered for project at that time" do
          let(:timestamp) { monday }

          it "returns the work package" do
            expect(subject).to eq [work_package]
          end
        end

        context "when the work package wasn't in the filtered for project at that time" do
          let(:timestamp) { wednesday }

          it "does not return the work package" do
            expect(subject).to be_empty
          end
        end
      end
    end

    describe "#at_timestamp" do
      subject { work_package.at_timestamp(timestamp) }

      describe "#at_timestamp(something before monday)" do
        let(:timestamp) { before_monday }

        it "returns nil because before Monday, no journal exists" do
          expect(subject).to be_nil
        end
      end

      describe "#at_timestamp(Monday)" do
        let(:timestamp) { monday }

        it "returns a record of the same type as the journable" do
          expect(subject.class).to eq journable.class
        end

        it "has the same id as the journable" do
          expect(subject.id).to eq journable.id
        end

        it "has the same created_at attribute as the journable" do
          expect(subject.created_at).to eq journable.created_at
        end

        it "has an older updated_at attribute as the journable" do
          expect(subject.updated_at).to be < journable.updated_at
        end

        it "has the attributes from monday" do
          expect(subject.description).to eq "The work package as it has been on Monday"
          expect(journable.description).to eq "The work package as it is since Friday"
        end

        describe "for columns that don't exist in the journal-data table" do
          let(:column_name) { :lock_version }

          specify "the column name does exist in the journable table" do
            expect(WorkPackage.column_names).to include column_name.to_s
          end

          specify "the column name does not exist in the journal-data table" do
            expect(Journal::WorkPackageJournal.column_names).not_to include column_name.to_s
          end

          it "has the attribute with null value" do
            expect(subject.attributes_before_type_cast[column_name]).to be_nil
          end

          it "has the typecasted value matching the journable class's data type" do
            expect(subject.send(column_name)).to eq 0
          end
        end

        context "with a custom field present" do
          let!(:custom_field) do
            create(:string_wp_custom_field,
                   name: "String CF",
                   types: project.types,
                   projects: [project])
          end

          let!(:monday_customizable_journal) do
            create(:journal_customizable_journal,
                   journal: monday_journal,
                   custom_field:,
                   value: "The custom field as it has been on Monday")
          end

          it "loads the custom_values relation with the historic values" do
            expect(subject.send(:"custom_field_#{custom_field.id}"))
              .to eq "The custom field as it has been on Monday"
          end
        end
      end
    end

    describe "#historic?" do
      describe "when querying historic values of a journable" do
        subject { work_package.at_timestamp(monday).historic? }

        it "returns true" do
          expect(subject).to be true
        end
      end

      describe "for the current journable without querying historic data" do
        subject { work_package.historic? }

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    describe "#valid?" do
      describe "when querying historic values of a journable" do
        subject { work_package.at_timestamp(monday).valid? }

        it "returns true" do
          expect(subject).to be true
        end
      end
    end

    describe "#save" do
      describe "when trying to save a historic record" do
        subject do
          historic_work_package = work_package.at_timestamp(monday)
          historic_work_package.description = "New description"
          historic_work_package.save
        end

        it "raises an error" do
          expect { subject }.to raise_error ActiveRecord::ReadOnlyRecord
        end
      end
    end

    describe "#update" do
      describe "when trying to update a historic record" do
        subject do
          historic_work_package = work_package.at_timestamp(monday)
          historic_work_package.update description: "New description"
        end

        it "raises an error" do
          expect { subject }.to raise_error ActiveRecord::ReadOnlyRecord
        end
      end
    end

    describe "#rollback!" do
      describe "when trying to rollback to a current (non-historic) record" do
        subject { work_package.rollback! }

        it "raises an error" do
          expect { subject }.to raise_error ActiveRecord::RecordNotSaved
        end
      end

      describe "when rolling back to historic data" do
        subject { work_package.at_timestamp(wednesday).rollback! }

        it "updates the journable records to its historic values" do
          expect(work_package.reload.description).to eq "The work package as it is since Friday"
          subject
          expect(work_package.reload.description).to eq "The work package as it has been on Wednesday"
        end
      end
    end

    describe "#position (unjournalized column)" do
      let(:timestamp) { monday }
      let(:position) { 42 }

      before do
        work_package.update_attribute :position, position
      end

      describe "when retrieving the position of the current (nin-historic) record" do
        subject { work_package.position }

        it "returns the value of the work_packages table" do
          expect(subject).to eq position
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "does not print a warning" do
          allow(Rails.logger).to receive(:warn)
          subject
          expect(Rails.logger).not_to have_received(:warn).with(/position/)
        end
      end

      describe "when retrieving the position of a historic record" do
        subject { work_package.at_timestamp(timestamp).position }

        it "returns nil" do
          expect(subject).to be_nil
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
  end
end

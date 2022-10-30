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

describe Journable::Timestamps, type: :model do
  # See: https://github.com/opf/openproject/pull/11243

  before do
    @before_monday = "2022-01-01".to_datetime
    @monday = "2022-08-01".to_datetime
    @tuesday = "2022-08-02".to_datetime
    @wednesday = "2022-08-03".to_datetime
    @thursday = "2022-08-04".to_datetime
    @friday = "2022-08-05".to_datetime
  end

  let!(:work_package) do
    new_work_package = create :work_package, description: "The work package as it is since Friday", estimated_hours: 10
    new_work_package.update_columns created_at: @monday
    new_work_package
  end
  let(:journable) { work_package }

  describe "when there are journals for Monday, Wednesday, and Friday" do
    def create_journal(journable:, timestamp:, attributes: {})
      work_package_attributes = work_package.attributes.except("id")
      journal_attributes = work_package_attributes.extract!(*Journal::WorkPackageJournal.attribute_names).symbolize_keys.merge(attributes)
      create :work_package_journal, journable:, created_at: timestamp, updated_at: timestamp,
          data: build(:journal_work_package_journal, journal_attributes)
    end

    before do
      @before_monday = "2022-01-01".to_datetime
      @monday = "2022-08-01".to_datetime
      @tuesday = "2022-08-02".to_datetime
      @wednesday = "2022-08-03".to_datetime
      @thursday = "2022-08-04".to_datetime
      @friday = "2022-08-05".to_datetime
      work_package.journals.destroy_all
      @monday_journal = create_journal(journable: work_package, timestamp: @monday, attributes: {description: "The work package as it has been on Monday", estimated_hours: 5})
      @wednesday_journal = create_journal(journable: work_package, timestamp: @wednesday, attributes: {description: "The work package as it has been on Wednesday", estimated_hours: 10})
      @friday_journal = create_journal(journable: work_package, timestamp: @friday, attributes: {description: "The work package as it is since Friday", estimated_hours: 10})
      work_package.reload
    end

    describe ".at_timestamp" do
      before { @timestamp = @monday }
      subject { WorkPackage.at_timestamp(@timestamp) }

      it "returns a historic active-record relation" do
        expect(subject).to be_kind_of Journable::HistoricActiveRecordRelation
        expect(subject).to be_kind_of ActiveRecord::Relation
      end

      describe "chaining a where clause" do
        subject { WorkPackage.at_timestamp(@timestamp).where(assigned_to_id: 1) }
        it "still returns a historic active-record relation" do
          expect(subject).to be_kind_of Journable::HistoricActiveRecordRelation
          expect(subject).to be_kind_of ActiveRecord::Relation
        end
      end

      it "returns readonly objects" do
        expect(subject.first.readonly?).to eq true
      end

      it "returns the records with the journable id rather than the id of the journal record" do
        expect(subject.pluck(:id)).to eq [work_package.id]
        expect(subject.first.id).to eq work_package.id
      end

      describe ".at_timestamp(something before Monday)" do
        before { @timestamp = @before_monday }
        it "returns [] because before Monday, no journal exists" do
          expect(subject).to eq []
        end
      end
      describe ".at_timestamp(Monday)" do
        before { @timestamp = @monday }
        it "returns the work packages in their state of Monday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end
      describe ".at_timestamp(Tuesday)" do
        before { @timestamp = @tuesday }
        it "returns the work packages in their state of Monday because this is the most current on Tuesday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end
      describe ".at_timestamp(Wednesday)" do
        before { @timestamp = @wednesday }
        it "returns the work packages in their state of Wednesday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Wednesday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end
      describe ".at_timestamp(Thursday)" do
        before { @timestamp = @thursday }
        it "returns the work packages in their state of Wednesday because this is the most current on Thursday" do
          expect(subject.pluck(:description)).to eq ["The work package as it has been on Wednesday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end
      describe ".at_timestamp(Friday)" do
        before { @timestamp = @friday }
        it "returns the work packages in their state of Friday" do
          expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
          expect(subject.pluck(:id)).to eq [work_package.id]
        end
      end

      describe "when filtering on a column that only matches in the past" do
        before { @relation = WorkPackage.where(description: "The work package as it has been on Monday") }
        describe "when querying the timestamp where the column matches" do
          subject { @relation.at_timestamp(@monday) }
          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
          end
        end
        describe "when querying the timestamp where the column does not match" do
          subject { @relation.at_timestamp(@wednesday) }
          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end
        describe "when querying without at_timestamp" do
          subject { @relation }
          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end
      end

      describe "when filtering on a column that only matches in the present" do
        before { @relation = WorkPackage.where(description: "The work package as it is since Friday") }
        describe "when querying the timestamp where the column matches" do
          subject { @relation.at_timestamp(@friday) }
          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to eq true
          end
        end
        describe "when querying the timestamp where the column does not match" do
          subject { @relation.at_timestamp(@wednesday) }
          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end
        describe "when querying without at_timestamp" do
          subject { @relation }
          it "returns the matching records" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to eq false
          end
        end
      end

      describe "when filtering with a negative condition" do
        before { @relation = WorkPackage.where.not(description: "The work package as it is since Friday") }
        describe "when querying a timestamp where the column matches" do
          subject { @relation.at_timestamp(@tuesday) }
          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to eq true
          end
        end
        describe "when querying a timestamp where the column does not match" do
          subject { @relation.at_timestamp(@friday) }
          it "returns [] because nothing matches" do
            expect(subject).to eq []
          end
        end
      end

      describe "when filtering on a column of an associated table" do
        before do
          @time_entry = work_package.time_entries.create! user_id: User.first.id, hours: 1, activity_id: 1, project_id: create(:project).id, spent_on: @monday, logged_by_id: User.first.id
          @relation = WorkPackage.joins(:time_entries).where(time_entries: {id: @time_entry.id})
        end
        describe "when querying with at_timestamp" do
          subject { @relation.at_timestamp(@friday) }
          it "joins the journable table rather than the journal-data table" do
            expect(subject.to_sql).not_to include "INNER JOIN \"time_entries\" ON \"time_entries\".\"work_package_id\" = \"work_package_journals\".\"id\""
            expect(subject.to_sql).to include "INNER JOIN \"time_entries\" ON \"time_entries\".\"work_package_id\" = \"journals\".\"journable_id\""
          end
          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to eq true
          end
        end
        describe "when querying with a past timestamp" do
          # This is a case we have to watch out. Even if the association has been created later
          # this still finds the historic record.
          subject { @relation.at_timestamp(@wednesday) }
          it "returns still matches because at_timestamp only filters the journable journal and not the associated journal" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Wednesday"]
          end
        end
        describe "when querying without at_timestamp" do
          subject { @relation }
          it "returns the matching records" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to eq false
          end
        end
      end

      describe "when filtering on a historic relation" do
        subject { WorkPackage.at_timestamp(@monday).where(description: @description) }
        describe "when the data on that point in history has no matches" do
          before { @description = "The work package as it is since Friday" }
          it "returns []" do
            expect(subject).to eq []
          end
        end
        describe "when the data on that point in history has matches" do
          before { @description = "The work package as it has been on Monday" }
          it "returns the matching records" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to eq true
          end
        end
      end

      describe "when filtering on a historic relation with a negative condition" do
        subject { WorkPackage.at_timestamp(@timestamp).where.not(description: "The work package as it is since Friday") }
        describe "when querying a timestamp where the column matches" do
          before { @timestamp = @tuesday }
          it "returns the matching records in their historic states" do
            expect(subject.pluck(:description)).to eq ["The work package as it has been on Monday"]
            expect(subject.pluck(:id)).to eq [work_package.id]
            expect(subject.first.historic?).to eq true
          end
        end
        describe "when querying a timestamp where the column does not match" do
          before { @timestamp = @friday }
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
          subject { WorkPackage.at_timestamp(@monday).maximum(:estimated_hours) }
          it "returns the correct result for that timestamp" do
            expect(subject).to eq 5
          end
        end
        describe "before at_timestamp" do
          subject { WorkPackage.maximum(:estimated_hours).at_timestamp(@monday) }
          it "returns an error because maximum returns a float rather than a relation" do
            expect { subject }.to raise_error NoMethodError
            expect(WorkPackage.maximum(:estimated_hours)).to be_kind_of Float
          end
        end
      end

      describe "when using a GROUP BY COUNT query" do
        describe "without at_timestamp" do
          subject { WorkPackage.group(:estimated_hours).count }
          it "returns the correct result for today" do
            expect(subject).to eq({10.0 => 1})
          end
        end
        describe "after at_timestamp" do
          subject { WorkPackage.at_timestamp(@monday).group(:estimated_hours).count }
          it "returns the correct result for that timestamp" do
            expect(subject).to eq({5.0 => 1})
          end
        end
      end

      describe "when using a GROUP BY COUNT HAVING query" do
        describe "without at_timestamp" do
          subject { WorkPackage.group(:estimated_hours).having('estimated_hours > 3').count }
          it "returns the correct result for today" do
            expect(subject).to eq({10.0 => 1})
          end
        end
        describe "after at_timestamp" do
          subject { WorkPackage.at_timestamp(@monday).group(:estimated_hours).having('estimated_hours > 3').count }
          it "returns the correct result for that timestamp" do
            expect(subject).to eq({5.0 => 1})
          end
        end
      end

      describe "#created_at" do
        subject { WorkPackage.at_timestamp(@timestamp).first.created_at }
        describe "for at_timestamp(before monday)" do
          before { @timestamp = @before_monday }
          it "raises an error because no result exists for that timestamp" do
            expect { subject }.to raise_error NoMethodError
          end
        end
        describe "for at_timestamp(monday)" do
          before { @timestamp = @monday }
          it "returns the date the record itself has been created" do
            expect(subject).to eq work_package.created_at
            expect(subject).to eq @monday
          end
        end
        describe "for at_timestamp(tuesday)" do
          before { @timestamp = @tuesday }
          it "returns the date the record itself has been created" do
            expect(subject).to eq work_package.created_at
            expect(subject).to eq @monday
          end
        end
        describe "for at_timestamp(wednesday)" do
          before { @timestamp = @wednesday }
          it "returns the date the record itself has been created" do
            expect(subject).to eq work_package.created_at
            expect(subject).to eq @monday
          end
        end
      end

      describe "#updated_at" do
        subject { WorkPackage.at_timestamp(@timestamp).first.updated_at }
        describe "for at_timestamp(before monday)" do
          before { @timestamp = @before_monday }
          it "raises an error because no result exists for that timestamp" do
            expect { subject }.to raise_error NoMethodError
          end
        end
        describe "for at_timestamp(monday)" do
          before { @timestamp = @monday }
          it "returns the date of the monday journal entry" do
            expect(subject).to eq @monday
          end
        end
        describe "for at_timestamp(tuesday)" do
          before { @timestamp = @tuesday }
          it "returns the date of the monday journal entry" do
            expect(subject).to eq @monday
          end
        end
        describe "for at_timestamp(wednesday)" do
          before { @timestamp = @wednesday }
          it "returns the date of the wednesday journal entry" do
            expect(subject).to eq @wednesday
          end
        end
      end

      describe "when using historic queries as sub queries" do
        subject do
          sub_query = WorkPackage.at_timestamp(@monday).where(description: "The work package as it has been on Monday")
          WorkPackage.where(id: sub_query)
        end
        pending "returns the current records that have matched the filter on monday" do
          expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
        end
        describe "when plucking the id as sub query (workaround)" do
          subject do
            sub_query = WorkPackage.at_timestamp(@monday).where(description: "The work package as it has been on Monday").pluck(:id)
            WorkPackage.where(id: sub_query)
          end
          it "returns the current records that have matched the filter on monday" do
            expect(subject.pluck(:description)).to eq ["The work package as it is since Friday"]
          end
        end
      end


      describe "when chaining a sql where clause (as used by Query#statement)" do
        subject { WorkPackage.where("(work_packages.description ILIKE '%been on Wednesday%')").at_timestamp(@wednesday) }

        it "transforms the table name" do
          expect(subject.to_sql).to include "work_package_journals.description ILIKE"
        end

        it "returns the requested work package" do
          expect(subject).to include work_package
        end
      end

      describe "when chaining an order clause" do
        subject { WorkPackage.at_timestamp(@wednesday).order(description: :desc) }

        it "transforms the table name" do
          expect(subject.to_sql).to include "\"work_package_journals\".\"description\" DESC"
        end

        it "returns the requested work package" do
          expect(subject).to include work_package
        end

        describe "when chaining a manual order clause" do
          subject { WorkPackage.order("work_packages.description DESC").at_timestamp(@wednesday) }

          it "transforms the table name" do
            expect(subject.to_sql).to include "work_package_journals.description DESC"
          end

          it "returns the requested work package" do
            expect(subject).to include work_package
          end
        end
      end

    end

    describe "#at_timestamp" do
      subject { work_package.at_timestamp(@timestamp) }

      describe "#at_timestamp(something before monday)" do
        before { @timestamp = @before_monday}
        it "returns nil because before Monday, no journal exists" do
          expect(subject).to eq nil
        end
      end

      describe "#at_timestamp(Monday)" do
        before { @timestamp = @monday }

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
      end
    end

    describe "#historic?" do
      describe "when querying historic values of a journable" do
        subject { work_package.at_timestamp(@monday).historic? }
        it "returns true" do
          expect(subject).to eq true
        end
      end

      describe "for the current journable without querying historic data" do
        subject { work_package.historic? }
        it "returns false" do
          expect(subject).to eq false
        end
      end
    end

    describe "#valid?" do
      describe "when querying historic values of a journable" do
        subject { work_package.at_timestamp(@monday).valid? }
        it "returns true" do
          expect(subject).to eq true
        end
      end
    end

    describe "#save" do
      describe "when trying to save a historic record" do
        subject do
          @work_package = work_package.at_timestamp(@monday)
          @work_package.description = "New description"
          @work_package.save
        end
        it "raises an error" do
          expect { subject }.to raise_error ActiveRecord::ReadOnlyRecord
        end
      end
    end

    describe "#update" do
      describe "when trying to update a historic record" do
        subject do
          @work_package = work_package.at_timestamp(@monday)
          @work_package.update description: "New description"
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
        subject { work_package.at_timestamp(@wednesday).rollback! }
        it "updates the journable records to its historic values" do
          expect(work_package.reload.description).to eq "The work package as it is since Friday"
          subject
          expect(work_package.reload.description).to eq "The work package as it has been on Wednesday"
        end
      end
    end

  end
end
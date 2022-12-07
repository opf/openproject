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

describe Journable::HistoricActiveRecordRelation do
  # See: https://github.com/opf/openproject/pull/11243

  let(:before_monday) { "2022-01-01".to_datetime }
  let(:monday) { "2022-08-01".to_datetime }
  let(:tuesday) { "2022-08-02".to_datetime }
  let(:wednesday) { "2022-08-03".to_datetime }
  let(:thursday) { "2022-08-04".to_datetime }
  let(:friday) { "2022-08-05".to_datetime }

  let(:project) { create(:project) }
  let!(:work_package) do
    new_work_package = create(:work_package, description: "The work package as it is since Friday", estimated_hours: 10, project:)
    new_work_package.update_columns created_at: monday
    new_work_package
  end
  let(:journable) { work_package }

  let(:monday_journal) do
    create_journal(journable: work_package, timestamp: monday,
                   attributes: { description: "The work package as it has been on Monday", estimated_hours: 5 })
  end
  let(:wednesday_journal) do
    create_journal(journable: work_package, timestamp: wednesday,
                   attributes: { description: "The work package as it has been on Wednesday", estimated_hours: 10 })
  end
  let(:friday_journal) do
    create_journal(journable: work_package, timestamp: friday,
                   attributes: { description: "The work package as it is since Friday", estimated_hours: 10 })
  end

  let(:relation) { WorkPackage.at_timestamp(wednesday) }

  def create_journal(journable:, timestamp:, attributes: {})
    work_package_attributes = work_package.attributes.except("id")
    journal_attributes = work_package_attributes \
        .extract!(*Journal::WorkPackageJournal.attribute_names) \
        .symbolize_keys.merge(attributes)
    create(:work_package_journal,
           journable:, created_at: timestamp, updated_at: timestamp,
           data: build(:journal_work_package_journal, journal_attributes))
  end

  before do
    work_package.journals.destroy_all
    monday_journal
    wednesday_journal
    friday_journal
    work_package.reload
  end

  describe "#where" do
    describe "project_id in array (Arel::Nodes::HomogeneousIn)" do
      subject { relation.where(project_id: [project.id, 1, 2, 3]) }

      describe "#to_sql" do
        it "transforms the expression to query the correct table" do
          expect(subject.to_sql).to include "\"work_package_journals\".\"project_id\" IN (#{project.id}, 1, 2, 3)"
        end
      end

      describe "#to_a" do
        it "returns the requested work package" do
          expect(subject.to_a).to include work_package
        end
      end
    end

    describe "project_id not in array (Arel::Nodes::HomogeneousIn)" do
      subject { relation.where.not(project_id: [9999, 999]) }

      describe "#to_sql" do
        it "transforms the expression to query the correct table" do
          expect(subject.to_sql).to include "\"work_package_journals\".\"project_id\" NOT IN (9999, 999)"
        end
      end

      describe "#to_a" do
        it "returns the requested work package" do
          expect(subject.to_a).to include work_package
        end
      end
    end
  end
end

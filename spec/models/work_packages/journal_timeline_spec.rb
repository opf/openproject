# frozen_string_literal: true

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

RSpec.describe WorkPackages::JournalTimeline do
  subject(:relation) { described_class.new(filters, ticks:, user:).relation }

  shared_let(:sunday) { Time.utc(2026, 10, 11, 12) }
  shared_let(:monday) { Time.utc(2026, 10, 12, 12) }
  shared_let(:tuesday) { Time.utc(2026, 10, 13, 12) }
  shared_let(:wednesday) { Time.utc(2026, 10, 14, 12) }

  let(:ticks) { [monday, tuesday, wednesday] }
  let(:filters) { Journal::WorkPackageJournal.all }
  let(:user) { create(:admin) }

  describe "sampling values over time" do
    shared_let(:project) { create(:project) }
    shared_let(:work_package) do
      create(:work_package,
             project:,
             journals: {
               sunday => { story_points: 5 },
               tuesday - 1.hour => { story_points: 8 }
             })
    end

    it "reports the value in effect at each tick" do
      expect(relation.group(:tick).sum(:story_points))
        .to eq(monday => 5, tuesday => 8, wednesday => 8)
    end

    it "yields one row per tick and work package" do
      expect(relation.count).to eq 3
      expect(relation.distinct.count(:id)).to eq 1
    end

    it "exposes the work package id rather than the journal id" do
      expect(relation.distinct.pluck(:id)).to eq [work_package.id]
    end

    context "when a tick falls exactly on the instant a journal becomes valid" do
      let(:ticks) { [tuesday - 1.hour] }

      it "takes the newly valid journal, since validity_period is lower-bound inclusive" do
        expect(relation.pluck(:story_points)).to eq [8]
      end
    end

    context "with a tick from before the work package existed" do
      let(:ticks) { [sunday - 5.days] }

      it { is_expected.to be_empty }
    end

    context "without any ticks" do
      let(:ticks) { [] }

      it { is_expected.to be_empty }
    end
  end

  describe "filters" do
    shared_let(:project) { create(:project) }
    shared_let(:other_project) { create(:project) }

    shared_let(:included) do
      create(:work_package, project:, journals: { sunday => { story_points: 3 } })
    end
    shared_let(:excluded) do
      create(:work_package, project: other_project, journals: { sunday => { story_points: 99 } })
    end

    let(:filters) { Journal::WorkPackageJournal.where(project_id: project.id) }

    it "narrows the result before the visibility check runs" do
      expect(relation.group(:tick).sum(:story_points).values.uniq).to eq [3]
    end

    it "composes with further conditions chained onto the relation" do
      expect(relation.where.not(story_points: 3)).to be_empty
    end

    it "stays usable for an arbitrary aggregate unrelated to story points" do
      expect(relation.group(:tick).count).to eq(monday => 1, tuesday => 1, wednesday => 1)
    end
  end

  describe "historic visibility" do
    shared_let(:visible_project) { create(:project) }
    shared_let(:hidden_project) { create(:project) }
    shared_let(:role) { create(:project_role, permissions: %i[view_work_packages]) }

    let(:user) { create(:user, member_with_roles: { visible_project => role }) }

    context "when the work package moves into a project the user cannot see" do
      shared_let(:work_package) do
        create(:work_package,
               project: hidden_project,
               journals: {
                 sunday => { story_points: 7, project_id: visible_project.id },
                 tuesday - 1.hour => { story_points: 7, project_id: hidden_project.id }
               })
      end

      it "keeps the earlier ticks and drops the later ones" do
        expect(relation.group(:tick).sum(:story_points)).to eq(monday => 7)
      end
    end

    context "when the work package moves out of a project the user cannot see" do
      shared_let(:work_package) do
        create(:work_package,
               project: visible_project,
               journals: {
                 sunday => { story_points: 7, project_id: hidden_project.id },
                 tuesday - 1.hour => { story_points: 7, project_id: visible_project.id }
               })
      end

      it "hides the ticks from while it was out of sight" do
        expect(relation.group(:tick).sum(:story_points)).to eq(tuesday => 7, wednesday => 7)
      end
    end

    context "when the work package is visible only through a share" do
      shared_let(:work_package) do
        create(:work_package, project: hidden_project, journals: { sunday => { story_points: 7 } })
      end

      before do
        create(:work_package_member, entity: work_package, user:, roles: [create(:view_work_package_role)])
      end

      it "counts at every tick, since a share carries no validity period" do
        expect(relation.group(:tick).sum(:story_points))
          .to eq(monday => 7, tuesday => 7, wednesday => 7)
      end
    end

    context "with an admin" do
      shared_let(:work_package) do
        create(:work_package, project: hidden_project, journals: { sunday => { story_points: 7 } })
      end

      let(:user) { create(:admin) }

      it "sees every tick regardless of project" do
        expect(relation.group(:tick).sum(:story_points))
          .to eq(monday => 7, tuesday => 7, wednesday => 7)
      end
    end

    context "with an anonymous user and a non-public project" do
      shared_let(:work_package) do
        create(:work_package, project: hidden_project, journals: { sunday => { story_points: 7 } })
      end

      let(:user) { create(:anonymous) }

      it { is_expected.to be_empty }
    end
  end
end

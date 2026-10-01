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

RSpec.describe Query::Results, "sort by id" do
  let(:user) { create(:admin) }

  # Three work packages in one project arranged so primary-key order does not
  # match sequence-number order. Mirrors a moved-in work package: its row was
  # inserted earliest (lowest PK) but received a later sequence in this project.
  def build_three_with_inverted_sequence(project)
    moved_in = create(:work_package, project:, subject: "Moved in", skip_semantic_id_allocation: true)
    native_first = create(:work_package, project:, subject: "Native first", skip_semantic_id_allocation: true)
    native_second = create(:work_package, project:, subject: "Native second", skip_semantic_id_allocation: true)

    moved_in.update_columns(sequence_number: 3, identifier: "#{project.identifier}-3")
    native_first.update_columns(sequence_number: 1, identifier: "#{project.identifier}-1")
    native_second.update_columns(sequence_number: 2, identifier: "#{project.identifier}-2")

    [moved_in, native_first, native_second]
  end

  def build_query(project, sort_criteria: [%w[id asc]])
    build_stubbed(:query,
                  user:,
                  project:,
                  show_hierarchies: false,
                  sort_criteria:,
                  column_names: %i[id subject])
  end

  current_user { user }

  context "in semantic mode",
          with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, identifier: "LARGE") }
    let!(:wps) { build_three_with_inverted_sequence(project) }
    let(:moved_in) { wps[0] }
    let(:native_first) { wps[1] }
    let(:native_second) { wps[2] }

    it "orders ascending by sequence number, not primary key" do
      results = described_class.new(build_query(project)).work_packages

      expect(results.pluck(:id)).to eq([native_first.id, native_second.id, moved_in.id])
    end

    it "orders descending by sequence number" do
      results = described_class.new(build_query(project, sort_criteria: [%w[id desc]])).work_packages

      expect(results.pluck(:id)).to eq([moved_in.id, native_second.id, native_first.id])
    end

    context "with rows from two projects" do
      let(:other_project) { create(:project, identifier: "SMALL") }
      let!(:other_wp) do
        wp = create(:work_package, project: other_project, subject: "Other", skip_semantic_id_allocation: true)
        wp.update_columns(sequence_number: 1, identifier: "SMALL-1")
        wp
      end

      let(:query) do
        build_stubbed(:query,
                      user:,
                      project: nil,
                      show_hierarchies: false,
                      sort_criteria: [%w[id asc]],
                      column_names: %i[id subject])
      end

      it "groups by project before ordering by sequence number" do
        results = described_class.new(query).work_packages.pluck(:id, :project_id)
        large_ids = results.select { it[1] == project.id }.map(&:first)
        small_ids = results.select { it[1] == other_project.id }.map(&:first)

        expect(large_ids).to eq([native_first.id, native_second.id, moved_in.id])
        expect(small_ids).to eq([other_wp.id])
      end
    end

    context "with rows from two projects whose identifiers invert the creation order" do
      let(:np_project) { create(:project, identifier: "ABC") }
      let!(:np_wp) do
        wp = create(:work_package, project: np_project, subject: "First in ABC", skip_semantic_id_allocation: true)
        wp.update_columns(sequence_number: 1, identifier: "ABC-1")
        wp
      end

      let(:query) do
        build_stubbed(:query,
                      user:,
                      project: nil,
                      show_hierarchies: false,
                      sort_criteria: [%w[id asc]],
                      column_names: %i[id subject])
      end

      it "orders rows by the project identifier prefix, not by project_id" do
        identifiers = described_class.new(query).work_packages.pluck(:identifier)

        expect(identifiers).to eq(%w[ABC-1 LARGE-1 LARGE-2 LARGE-3])
      end
    end

    context "with a non-ID primary sort and a tie" do
      before do
        WorkPackage.where(id: wps.map(&:id)).update_all(subject: "Same subject")
      end

      it "breaks the tie deterministically using the semantic ID sort key" do
        query = build_query(project, sort_criteria: [%w[subject asc]])
        results = described_class.new(query).work_packages

        # The implicit `id` tiebreaker resolves through the same sort key as an
        # explicit ID sort — so ties break by (project_id, sequence_number) DESC,
        # i.e. highest sequence first.
        expect(results.pluck(:id)).to eq([moved_in.id, native_second.id, native_first.id])
      end
    end

    context "with a sequence_number still NULL (pre-backfill row)" do
      let!(:unsequenced) do
        wp = create(:work_package, project:, subject: "Unsequenced", skip_semantic_id_allocation: true)
        wp.update_columns(sequence_number: nil, identifier: nil)
        wp
      end

      it "places unsequenced rows at the end on ascending sort" do
        ids = described_class.new(build_query(project)).work_packages.pluck(:id)

        expect(ids.last).to eq(unsequenced.id)
        expect(ids.first(3)).to eq([native_first.id, native_second.id, moved_in.id])
      end
    end
  end

  context "in classic mode",
          with_settings: { work_packages_identifier: "classic" } do
    let(:project) { create(:project, identifier: "large") }
    let!(:wps) { build_three_with_inverted_sequence(project) }
    let(:moved_in) { wps[0] }
    let(:native_first) { wps[1] }
    let(:native_second) { wps[2] }

    it "orders ascending by primary key, ignoring sequence_number" do
      results = described_class.new(build_query(project)).work_packages

      expect(results.pluck(:id)).to eq([moved_in.id, native_first.id, native_second.id])
    end
  end
end

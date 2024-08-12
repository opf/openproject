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

RSpec.describe WorkPackage::Exports::CSV, "integration" do
  before do
    login_as current_user
  end

  let(:project) { create(:project) }
  let(:type_a) { create(:type, name: "Type A") }
  let(:type_b) { create(:type, name: "Type B") }
  let(:wp1) { create(:work_package, project:, done_ratio: 25, subject: 'WP1', type: type_a) }
  let(:wp2) { create(:work_package, project:, done_ratio: 0, subject: 'WP2', type: type_a) }
  let(:wp3) { create(:work_package, project:, done_ratio: 0, subject: 'WP3', type: type_b) }
  let(:wp4) { create(:work_package, project:, done_ratio: 0, subject: 'WP4', type: type_a) }
  let(:current_user) do
    create(:user,
           member_with_permissions: { project => %i(view_work_packages) })
  end
  let(:instance) do
    described_class.new(query)
  end

  context "when the query is not grouped" do
    let(:query) do
      Query.new_default.tap do |query|
        query.column_names = %i(type subject assigned_to updated_at estimated_hours)
      end
    end

    ##
    # When Ruby tries to join the following work package's subject encoded in ISO-8859-1
    # and its description encoded in UTF-8 it will result in a CompatibilityError.
    # This would not happen if the description contained only letters covered by
    # ISO-8859-1. Since this can happen, though, it is more sensible to encode everything
    # in UTF-8 which gets rid of this problem altogether.
    let!(:work_package) do
      create(
        :work_package,
        subject: "Ruby encodes ß as '\\xDF' in ISO-8859-1.",
        description: "\u2022 requires unicode.",
        assigned_to: current_user,
        derived_estimated_hours: 15.0,
        type: type_a,
        project:
      )
    end

    it "performs a successful export" do
      work_package.reload

      data = CSV.parse instance.export!.content

      expect(data.size).to eq(2)
      expect(data.last).to include(work_package.type.name)
      expect(data.last).to include(work_package.subject)
      expect(data.last).to include(work_package.description)
      expect(data.last).to include(current_user.name)
      expect(data.last).to include(work_package.updated_at.localtime.strftime("%m/%d/%Y %I:%M %p"))
      expect(data.last).to include("· Σ 15h")
    end
  end

  context "when the query is grouped" do
    let(:query) do
      Query.new_default.tap do |query|
        query.show_hierarchies = false
        query.group_by = 'type'
        query.sort_criteria = [["id", "asc"]]
        query.column_names = %i(type subject)
      end
    end
    it "performs a successful grouped export" do
      wp1
      wp2
      wp3
      wp4

      data = CSV.parse instance.export!.content

      expect(data.size).to eq(5)
      # grouped by type
      expect(data.map { |row| row[1] }).to eq %w[Subject WP3 WP1 WP2 WP4]
    end
  end

  context "when the query is filtered" do
    let(:query) do
      Query.new_default.tap do |query|
        query.column_names = %i(subject done_ratio)
        query.add_filter "done_ratio", "=", [25]
      end
    end
    it "performs a successful grouped export" do
      wp1
      wp2
      wp3
      wp4

      data = CSV.parse instance.export!.content

      expect(data.size).to eq(2)
      expect(data.last).to include(wp1.name)
    end
  end
  context "when the query is manually ordered" do
    let(:query) do
      Query.new_default.tap do |query|
        query.column_names = %i(subject done_ratio)
        query.sort_criteria = [[:manual_sorting, "asc"]]
        query.name = "Manual sorting"
        query.user_id = current_user.id
      end
    end
    before do
      OrderedWorkPackage.create(query:, work_package: wp4, position: 0)
      OrderedWorkPackage.create(query:, work_package: wp2, position: 1)
      OrderedWorkPackage.create(query:, work_package: wp1, position: 2)
      OrderedWorkPackage.create(query:, work_package: wp3, position: 3)
    end
    it "performs a successful manually ordered export" do
      data = CSV.parse instance.export!.content

      expect(data.size).to eq(5)
      expect(data.map { |row| row[0] }).to eq %w[Subject WP4 WP2 WP1 WP3]
    end
  end
end

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
    login_as user
  end

  let(:project) { create(:project) }
  let(:options) { { show_descriptions: true } }
  let(:type_a) { create(:type, name: "Type A") }
  let(:type_b) { create(:type, name: "Type B") }
  let(:wp1) { create(:work_package, project:, done_ratio: 25, subject: "WP1", type: type_a, id: 1) }
  let(:wp2) { create(:work_package, project:, done_ratio: 0, subject: "WP2", type: type_a, id: 2) }
  let(:wp3) { create(:work_package, project:, done_ratio: 0, subject: "WP3", type: type_b, id: 3) }
  let(:wp4) { create(:work_package, project:, done_ratio: 0, subject: "WP4", type: type_a, id: 4) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i(view_work_packages) })
  end
  let(:instance) do
    described_class.new(query, options)
  end
  let(:work_packages) do
    [wp1, wp2, wp3, wp4]
  end

  context "when the query is default" do
    let(:query) do
      create(:query, project:, user:, column_names: %i(type subject assigned_to updated_at estimated_hours))
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
        assigned_to: user,
        derived_estimated_hours: 15.0,
        type: type_a,
        project:
      )
    end

    context "when description is included" do
      it "performs a successful export" do
        work_package.reload

        data = CSV.parse instance.export!.content

        expect(data.size).to eq(2)
        expect(data.last).to include(work_package.type.name)
        expect(data.last).to include(work_package.subject)
        expect(data.last).to include(work_package.description)
        expect(data.last).to include(user.name)
        expect(data.last).to include(work_package.updated_at.localtime.strftime("%m/%d/%Y %I:%M %p"))
        expect(data.last).to include("· Σ 15h")
      end
    end

    context "when description is not included" do
      let(:options) { { show_descriptions: false } }

      it "performs a successful export" do
        work_package.reload

        data = CSV.parse instance.export!.content

        expect(data.size).to eq(2)
        expect(data.last).to include(work_package.type.name)
        expect(data.last).to include(work_package.subject)
        expect(data.last).not_to include(work_package.description)
        expect(data.last).to include(user.name)
        expect(data.last).to include(work_package.updated_at.localtime.strftime("%m/%d/%Y %I:%M %p"))
        expect(data.last).to include("· Σ 15h")
      end
    end
  end

  context "when the query is grouped" do
    let(:query) do
      create(:query, project:, user:, column_names: %i(type subject id),
                     group_by: "type",
                     show_hierarchies: false, sort_criteria: [%w[type asc], %w[id asc]])
    end

    it "performs a successful grouped export" do
      type_a.update_column(:position, 1)
      type_b.update_column(:position, 2)
      work_packages
      data = CSV.parse instance.export!.content

      expect(data.size).to eq(5)
      expect(data.pluck(0)).to eq ["Type", "Type A", "Type A", "Type A", "Type B"]
    end
  end

  context "when the query is filtered" do
    let(:query) do
      create(:query, project:, user:, column_names: %i(subject done_ratio))
        .tap do |query|
        query.add_filter "done_ratio", "=", [25]
      end
    end

    it "performs a successful grouped export" do
      work_packages
      data = CSV.parse instance.export!.content

      expect(data.size).to eq(2)
      expect(data.last).to include(wp1.name)
    end
  end

  context "when the query is manually ordered" do
    let(:query) do
      create(
        :query, project:, user:,
                column_names: %i(subject done_ratio),
                sort_criteria: [[:manual_sorting, "asc"]]
      )
    end

    before do
      OrderedWorkPackage.delete_all
      OrderedWorkPackage.create(query:, work_package: wp4, position: 0)
      OrderedWorkPackage.create(query:, work_package: wp2, position: 1)
      OrderedWorkPackage.create(query:, work_package: wp1, position: 2)
      OrderedWorkPackage.create(query:, work_package: wp3, position: 3)
    end

    after do
      OrderedWorkPackage.delete_all
    end

    it "performs a successful manually ordered export" do
      work_packages
      data = CSV.parse instance.export!.content

      expect(data.size).to eq(5)
      expect(data.pluck(0)).to eq %w[Subject WP4 WP2 WP1 WP3]
    end
  end
end

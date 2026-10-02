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

RSpec.describe FullCalendar::ResourceAllocationEvent do
  let(:project) { build_stubbed(:project, name: "Apollo") }
  let(:type) { build_stubbed(:type) }
  let(:work_package) { build_stubbed(:work_package, project:, type:, subject: "Fix the thing") }
  let(:allocation) { build_stubbed(:resource_allocation, entity: work_package) }
  let(:date) { Date.new(2026, 10, 5) }
  let(:scheduled_entry) do
    ResourceAllocations::ScheduledEntry.new(allocation:, work_package:, allocated_on: date, minutes: 150)
  end
  let(:visible) { true }

  subject(:json) { described_class.from_scheduled_entry(scheduled_entry, visible:).as_json }

  it "is an all-day event on the scheduled date" do
    expect(json).to include("allDay" => true, "start" => date.as_json, "end" => date.as_json)
  end

  it "is identified per allocation and day, grouped by the allocation" do
    expect(json).to include("id" => "#{allocation.id}-2026-10-05", "groupId" => allocation.id.to_s)
  end

  it "carries the scheduled minutes as hours" do
    expect(json).to include("allocationId" => allocation.id, "hours" => 2.5)
  end

  context "when the work package is visible" do
    it "describes the work package" do
      expect(json).to include(
        "title" => "Apollo: #{work_package.formatted_id} Fix the thing",
        "typeId" => type.id,
        "workPackageId" => work_package.to_param,
        "workPackageFormattedId" => work_package.formatted_id,
        "workPackageSubject" => "Fix the thing",
        "projectId" => project.id,
        "projectIdentifier" => project.identifier,
        "projectName" => "Apollo"
      )
    end
  end

  context "when the work package is not visible" do
    let(:visible) { false }

    it "shows a placeholder title" do
      expect(json["title"]).to eq(I18n.t("resource_management.my_work.hidden_work_package"))
    end

    it "does not reveal the work package or its project" do
      expect(json.keys).not_to include("typeId", "workPackageId", "workPackageFormattedId", "workPackageSubject",
                                       "projectId", "projectIdentifier", "projectName")
    end
  end
end

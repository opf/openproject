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

RSpec.describe ScheduleHelpers::LetSchedule do
  create_shared_association_defaults_for_work_package_factory

  describe "let_schedule" do
    let_schedule(<<~CHART)
      days      | MTWTFSS |
      main      | XX      |
      follower  |   XXX   | follows main with lag 2
      child     |         | child of main
    CHART

    it "creates let calls for each work package" do
      expect([main, follower, child]).to all(be_an_instance_of(WorkPackage))
      expect([main, follower, child]).to all(be_persisted)
      expect(main).to have_attributes(
        subject: "main",
        start_date: schedule.monday,
        due_date: schedule.tuesday
      )
      expect(follower).to have_attributes(
        subject: "follower",
        start_date: schedule.wednesday,
        due_date: schedule.friday
      )
      expect(child).to have_attributes(
        subject: "child",
        start_date: nil,
        due_date: nil
      )
    end

    it "creates follows relations between work packages" do
      expect(follower.follows_relations.count).to eq(1)
      expect(follower.follows_relations.first.to).to eq(main)
    end

    it "creates parent / child relations" do
      expect(child.parent).to eq(main)
    end
  end
end

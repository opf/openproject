#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe "Planning Comparison" do

  let (:project){FactoryGirl.create(:project)}

  let(:journalized_work_package) do
    wp = nil
    Timecop.freeze(1.week.ago) do
      wp = FactoryGirl.create(:work_package, project: project, start_date: "01/01/2020", due_date: "01/03/2020")
      wp.save # triggers the journaling and saves the old due_date, creating the baseline for the comparison
    end

    wp.due_date = "01/04/2020"
    wp.save # adds another journal-entry
    wp
  end

  it "should return the changes as a work_package" do
    wp = journalized_work_package

    # beware of these date-conversions: 1.week.ago does not catch the change, as created_at is stored as a timestamp
    expect(PlanningComparisonService.compare(project, 5.days.ago).size).to eql 1
    expect(PlanningComparisonService.compare(project, 5.days.ago).first).to be_instance_of WorkPackage
  end

  it "should return the old due_date in the comaprison" do
    wp = journalized_work_package

    # beware of these date-conversions: 1.week.ago does not catch the change, as created_at is stored as a timestamp
    old_work_package = PlanningComparisonService.compare(project, 5.days.ago).first
    expect(old_work_package.due_date).to eql Date.parse "01/03/2020"
  end


end

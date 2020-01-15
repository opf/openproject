#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++
require_relative '../legacy_spec_helper'

describe TimeEntry, type: :model do
  fixtures :all

  it 'should hours format' do
    assertions = { '2'      => 2.0,
                   '21.1'   => 21.1,
                   '2,1'    => 2.1,
                   '1,5h'   => 1.5,
                   '7:12'   => 7.2,
                   '10h'    => 10.0,
                   '10 h'   => 10.0,
                   '45m'    => 0.75,
                   '45 m'   => 0.75,
                   '3h15'   => 3.25,
                   '3h 15'  => 3.25,
                   '3 h 15'   => 3.25,
                   '3 h 15m'  => 3.25,
                   '3 h 15 m' => 3.25,
                   '3 hours'  => 3.0,
                   '12min'    => 0.2,
                  }

    assertions.each do |k, v|
      t = TimeEntry.new(hours: k)
      assert_equal v, t.hours, "Converting #{k} failed:"
    end
  end

  it 'should hours should default to nil' do
    assert_nil TimeEntry.new.hours
  end

  it 'should spent on with blank' do
    c = TimeEntry.new
    c.spent_on = ''
    assert_nil c.spent_on
  end

  it 'should spent on with nil' do
    c = TimeEntry.new
    c.spent_on = nil
    assert_nil c.spent_on
  end

  it 'should spent on with string' do
    c = TimeEntry.new
    c.spent_on = '2011-01-14'
    assert_equal Date.parse('2011-01-14'), c.spent_on
  end

  it 'should spent on with invalid string' do
    c = TimeEntry.new
    c.spent_on = 'foo'
    assert_nil c.spent_on
  end

  it 'should spent on with date' do
    c = TimeEntry.new
    c.spent_on = Date.today
    assert_equal Date.today, c.spent_on
  end

  it 'should spent on with time' do
    c = TimeEntry.new
    c.spent_on = Time.now
    assert_equal Date.today, c.spent_on
  end

  context '#earliest_date_for_project' do
    before do
      User.current = nil
      @public_project = FactoryBot.create(:project, public: true)
      @issue = FactoryBot.create(:work_package, project: @public_project)
      FactoryBot.create(:time_entry, spent_on: '2010-01-01',
                          work_package: @issue,
                          project: @public_project)
    end

    context 'without a project' do
      it 'should return the lowest spent_on value that is visible to the current user' do
        assert_equal '2007-03-12', TimeEntry.earliest_date_for_project.to_s
      end
    end

    context 'with a project' do
      it "should return the lowest spent_on value that is visible to the current user for that project and it's subprojects only" do
        assert_equal '2010-01-01', TimeEntry.earliest_date_for_project(@public_project).to_s
      end
    end
  end

  context '#latest_date_for_project' do
    before do
      User.current = nil
      @public_project = FactoryBot.create(:project, public: true)
      @issue = FactoryBot.create(:work_package, project: @public_project)
      FactoryBot.create(:time_entry, spent_on: '2010-01-01',
                          work_package: @issue,
                          project: @public_project)
    end

    context 'without a project' do
      it 'should return the highest spent_on value that is visible to the current user' do
        assert_equal '2010-01-01', TimeEntry.latest_date_for_project.to_s
      end
    end

    context 'with a project' do
      it "should return the highest spent_on value that is visible to the current user for that project and it's subprojects only" do
        project = Project.find(1)
        assert_equal '2007-04-22', TimeEntry.latest_date_for_project(project).to_s
      end
    end
  end
end

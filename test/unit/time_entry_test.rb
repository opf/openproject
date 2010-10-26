# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../test_helper'

class TimeEntryTest < ActiveSupport::TestCase
  fixtures :issues, :projects, :users, :time_entries

  def test_hours_format
    assertions = { "2"      => 2.0,
                   "21.1"   => 21.1,
                   "2,1"    => 2.1,
                   "1,5h"   => 1.5,
                   "7:12"   => 7.2,
                   "10h"    => 10.0,
                   "10 h"   => 10.0,
                   "45m"    => 0.75,
                   "45 m"   => 0.75,
                   "3h15"   => 3.25,
                   "3h 15"  => 3.25,
                   "3 h 15"   => 3.25,
                   "3 h 15m"  => 3.25,
                   "3 h 15 m" => 3.25,
                   "3 hours"  => 3.0,
                   "12min"    => 0.2,
                  }
    
    assertions.each do |k, v|
      t = TimeEntry.new(:hours => k)
      assert_equal v, t.hours, "Converting #{k} failed:"
    end
  end
  
  def test_hours_should_default_to_nil
    assert_nil TimeEntry.new.hours
  end

  context "#earilest_date_for_project" do
    setup do
      User.current = nil
      @public_project = Project.generate!(:is_public => true)
      @issue = Issue.generate_for_project!(@public_project)
      TimeEntry.generate!(:spent_on => '2010-01-01',
                          :issue => @issue,
                          :project => @public_project)
    end
    
    context "without a project" do
      should "return the lowest spent_on value that is visible to the current user" do
        assert_equal "2007-03-12", TimeEntry.earilest_date_for_project.to_s
      end
    end

    context "with a project" do
      should "return the lowest spent_on value that is visible to the current user for that project and it's subprojects only" do
        assert_equal "2010-01-01", TimeEntry.earilest_date_for_project(@public_project).to_s
      end
    end
      
  end

  context "#latest_date_for_project" do
    setup do
      User.current = nil
      @public_project = Project.generate!(:is_public => true)
      @issue = Issue.generate_for_project!(@public_project)
      TimeEntry.generate!(:spent_on => '2010-01-01',
                          :issue => @issue,
                          :project => @public_project)
    end

    context "without a project" do
      should "return the highest spent_on value that is visible to the current user" do
        assert_equal "2010-01-01", TimeEntry.latest_date_for_project.to_s
      end
    end

    context "with a project" do
      should "return the highest spent_on value that is visible to the current user for that project and it's subprojects only" do
        project = Project.find(1)
        assert_equal "2007-04-22", TimeEntry.latest_date_for_project(project).to_s
      end
    end
  end  
end

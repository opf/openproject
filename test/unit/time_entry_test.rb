#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class TimeEntryTest < ActiveSupport::TestCase
  fixtures :all

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

  def test_spent_on_with_blank
    c = TimeEntry.new
    c.spent_on = ''
    assert_nil c.spent_on
  end

  def test_spent_on_with_nil
    c = TimeEntry.new
    c.spent_on = nil
    assert_nil c.spent_on
  end

  def test_spent_on_with_string
    c = TimeEntry.new
    c.spent_on = "2011-01-14"
    assert_equal Date.parse("2011-01-14"), c.spent_on
  end

  def test_spent_on_with_invalid_string
    c = TimeEntry.new
    c.spent_on = "foo"
    assert_nil c.spent_on
  end

  def test_spent_on_with_date
    c = TimeEntry.new
    c.spent_on = Date.today
    assert_equal Date.today, c.spent_on
  end

  def test_spent_on_with_time
    c = TimeEntry.new
    c.spent_on = Time.now
    assert_equal Date.today, c.spent_on
  end

  context "#earliest_date_for_project" do
    setup do
      User.current = nil
      @public_project = Project.generate!(:is_public => true)
      @issue = WorkPackage.generate_for_project!(@public_project)
      TimeEntry.generate!(:spent_on => '2010-01-01',
                          :work_package => @issue,
                          :project => @public_project)
    end

    context "without a project" do
      should "return the lowest spent_on value that is visible to the current user" do
        assert_equal "2007-03-12", TimeEntry.earliest_date_for_project.to_s
      end
    end

    context "with a project" do
      should "return the lowest spent_on value that is visible to the current user for that project and it's subprojects only" do
        assert_equal "2010-01-01", TimeEntry.earliest_date_for_project(@public_project).to_s
      end
    end

  end

  context "#latest_date_for_project" do
    setup do
      User.current = nil
      @public_project = Project.generate!(:is_public => true)
      @issue = WorkPackage.generate_for_project!(@public_project)
      TimeEntry.generate!(:spent_on => '2010-01-01',
                          :work_package => @issue,
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

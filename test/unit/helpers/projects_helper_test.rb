#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)

class ProjectsHelperTest < HelperTestCase
  include ApplicationHelper
  include ProjectsHelper

  def setup
    super
    set_language_if_valid('en')
    User.current = nil
    @test_project = FactoryGirl.create :valid_project
    @user = FactoryGirl.create :user, :member_in_project => @test_project
    @version = FactoryGirl.create :version, :project => @test_project
  end

  def test_link_to_version_within_project
    User.current = @user
    @project = @test_project
    assert_equal "<a href=\"/versions/#{@version.id}\">#{@version.name}</a>", link_to_version(@version)
  end

  def test_link_to_version
    User.current = @user
    assert_equal "<a href=\"/versions/#{@version.id}\">#{@test_project.name} - #{@version.name}</a>", link_to_version(@version)
  end

  def test_link_to_private_version
    assert_equal "#{@test_project.name} - #{@version.name}", link_to_version(@version)
  end

  def test_link_to_version_invalid_version
    assert_equal '', link_to_version(Object)
  end

  def test_format_version_name_within_project
    @project = @test_project
    assert_equal @version.name, format_version_name(@version)
  end

  def test_format_version_name
    assert_equal "#{@test_project.name} - #{@version.name}", format_version_name(@version)
  end

  def test_format_version_name_for_system_version
    version = FactoryGirl.create :version, :project => @test_project, :sharing => 'system'
    assert_equal "#{@test_project.name} - #{version.name}", format_version_name(version)
  end

  def test_version_options_for_select_with_no_versions
    assert_equal '', version_options_for_select([])
    assert_equal "<option value=\"#{@version.id}\" selected=\"selected\">#{@version.name}</option>", version_options_for_select([], @version)
  end
end

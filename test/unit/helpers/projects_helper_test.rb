#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
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

  fixtures :all

  def setup
    super
    set_language_if_valid('en')
    User.current = nil
  end

  def test_link_to_version_within_project
    @project = Project.find(2)
    User.current = User.find(1)
    assert_equal '<a href="/versions/show/5">Alpha</a>', link_to_version(Version.find(5))
  end

  def test_link_to_version
    User.current = User.find(1)
    assert_equal '<a href="/versions/show/5">OnlineStore - Alpha</a>', link_to_version(Version.find(5))
  end

  def test_link_to_private_version
    assert_equal 'OnlineStore - Alpha', link_to_version(Version.find(5))
  end

  def test_link_to_version_invalid_version
    assert_equal '', link_to_version(Object)
  end

  def test_format_version_name_within_project
    @project = Project.find(1)
    assert_equal "0.1", format_version_name(Version.find(1))
  end

  def test_format_version_name
    assert_equal "eCookbook - 0.1", format_version_name(Version.find(1))
  end

  def test_format_version_name_for_system_version
    assert_equal "OnlineStore - Systemwide visible version", format_version_name(Version.find(7))
  end

  def test_version_options_for_select_with_no_versions
    assert_equal '', version_options_for_select([])
    assert_equal '<option value="1" selected="selected">0.1</option>', version_options_for_select([], Version.find(1))
  end
end

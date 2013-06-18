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

class ProjectsTest < ActionDispatch::IntegrationTest
  fixtures :all

  def test_archive_project
    subproject = Project.find(1).children.first
    log_user("admin", "adminADMIN!")
    get "admin/projects"
    assert_response :success
    assert_template "admin/projects"
    post "projects/archive", :id => 1
    assert_redirected_to "/admin/projects"
    assert !Project.find(1).active?

    get 'projects/1'
    assert_response 403
    get "projects/#{subproject.id}"
    assert_response 403

    post "projects/unarchive", :id => 1
    assert_redirected_to "/admin/projects"
    assert Project.find(1).active?
    get "projects/1"
    assert_response :success
  end
end

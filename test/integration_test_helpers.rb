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

module IntegrationTestHelpers

  # Helpers for Capybara tests only
  #
  # Warning: might have API incompatibilities with Rails default
  # integration test methods. Only include where needed.
  module CapybaraHelpers
    # Capybara doesn't set the response object so we need to glue this to
    # it's own object but without @response
    def assert_response(code)
      # Rewrite human status codes to numeric
      converted_code = case code
                       when :success
                         200
                       when :missing
                         404
                       when :redirect
                         302
                       when :error
                         500
                       when code.is_a?(Symbol)
                         ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE[code]
                       else
                         code
                       end

      assert_equal converted_code, page.status_code
    end

    # Override the existing log_user method so it correctly sets
    # the capybara page elements (sessions, etc)
    #
    # Actually drives the login form
    def log_user(user="existing", password="existing")
      visit "/logout" # Make sure the session is cleared

      visit "/login"
      fill_in 'Login', :with => user
      fill_in 'Password', :with => password
      click_button 'login'
      assert_response :success
      assert User.current.logged?
    end

    def visit_home
      visit '/'
      assert_response :success
    end

    def visit_project(project)
      visit_home
      assert_response :success

      click_link 'Projects'
      assert_response :success

      click_link project.name
      assert_response :success
    end

    def visit_issue_page(issue)
      visit '/issues/' + issue.id.to_s
    end

    def visit_issue_bulk_edit_page(issues)
      visit url_for(:controller => 'issues', :action => 'bulk_edit', :ids => issues.collect(&:id))
    end

  end
end

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

module Redmine
  module Info
    class << self
      def app_name; Setting.software_name end
      def url; Setting.software_url end
      def help_url
        "https://www.openproject.org/projects/support"
      end
      def versioned_name; "#{app_name} #{Redmine::VERSION.to_semver}" end

      # Creates the url string to a specific Redmine issue
      def issue(issue_id)
        url + 'issues/' + issue_id.to_s
      end
    end
  end
end

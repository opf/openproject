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

module GroupsHelper
  # Options for the new membership projects combo-box
  def options_for_membership_project_select(user, projects)
    options = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---")
    options << project_tree_options_for_select(projects) do |p|
      {:disabled => (user.projects.include?(p))}
    end
    options
  end

  def group_settings_tabs
    tabs = [{:name => 'general', :partial => 'groups/general', :label => :label_general},
            {:name => 'users', :partial => 'groups/users', :label => :label_user_plural},
            {:name => 'memberships', :partial => 'groups/memberships', :label => :label_project_plural}
            ]
  end
end

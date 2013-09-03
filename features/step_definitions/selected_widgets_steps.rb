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

Given /^the following widgets are selected for the overview page of the "(.+)" project:$/ do |project_name, table|
  project = Project.find_by_name(project_name)
  page = MyProjectsOverview.find_or_create_by_project_id(project.id)

  blocks = ({ "top" => "", "left" => "", "right" => "", "hidden" => "" }).merge(table.rows_hash)

  blocks.each { |k, v| page.send((k + "=").to_sym, v.split(",").map{|s| s.strip.downcase}) }

  page.save
end

Then /^the "(.+)" widget should be in the hidden block$/ do |widget_name|
  steps %{Then I should see "#{widget_name}" within "#list-hidden"}
end

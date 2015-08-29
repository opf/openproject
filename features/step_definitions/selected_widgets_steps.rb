#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

Given /^the following widgets are selected for the overview page of the "(.+)" project:$/ do |project_name, table|
  project = Project.find_by_name(project_name)
  page = MyProjectsOverview.find_or_create_by(project_id: project.id)

  blocks = ({ "top" => "", "left" => "", "right" => "", "hidden" => "" }).merge(table.rows_hash)

  blocks.each { |k, v| page.send((k + "=").to_sym, v.split(",").map{|s| s.strip.downcase}) }

  page.save
end

Then /^the "(.+)" widget should be in the hidden block$/ do |widget_name|
  steps %{Then I should see "#{widget_name}" within "#list-hidden"}
end

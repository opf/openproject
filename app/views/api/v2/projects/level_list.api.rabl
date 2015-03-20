#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

collection @projects => "projects"

# This is a bit verbose as Project.level_list produces an array of hashes with the form:
# [
#  { :project => <Project object>,
#    :level   => <hierarchy level> }
# ]

node(:id)           { |p| p[:project].id }
node(:name)         { |p| p[:project].name }
node(:identifier)   { |p| p[:project].identifier }
node(:has_children) { |p| !p[:project].leaf? }
node(:level)        { |p| p[:level] }

node(:created_on, :if => lambda { |p| p[:project].created_on }) do |p|
  p[:project].created_on.utc
end

node(:updated_on, :if => lambda { |p| p[:project].updated_on }) do |p|
  p[:project].updated_on.utc
end

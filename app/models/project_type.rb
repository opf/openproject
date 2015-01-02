#-- encoding: UTF-8
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

class ProjectType < ActiveRecord::Base
  unloadable

  extend Pagination::Model

  self.table_name = 'project_types'

  acts_as_list
  default_scope order: 'position ASC'

  has_many :projects, class_name:  'Project',
                      foreign_key: 'project_type_id'

  has_many :available_project_statuses, class_name:  'AvailableProjectStatus',
                                        foreign_key: 'project_type_id',
                                        dependent: :destroy
  has_many :reported_project_statuses, through: :available_project_statuses

  include ActiveModel::ForbiddenAttributesProtection

  validates_presence_of :name
  validates_inclusion_of :allows_association, in: [true, false]

  validates_length_of :name, maximum: 255, unless: lambda { |e| e.name.blank? }

  def self.available_grouping_project_types
    # this should be all project types to which there are projects to
    # which there are dependencies from projects that the user can see
    find(:all, order: :name)
  end
end

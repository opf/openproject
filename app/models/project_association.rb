#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class ProjectAssociation < ActiveRecord::Base
  self.table_name = 'project_associations'

  belongs_to :project_a, class_name:  'Project',
                         foreign_key: 'project_a_id'
  belongs_to :project_b, class_name:  'Project',
                         foreign_key: 'project_b_id'

  validates_presence_of :project_a, :project_b

  validate :validate,
           :validate_projects_not_identical

  scope :with_projects, -> (projects) {
    projects = [projects] unless  projects.is_a? Array
    project_ids = projects.first.respond_to?(:id) ? projects.map(&:id).join(',') : projects

    where(["#{table_name}.project_a_id in (?) or #{table_name}.project_b_id in (?)", project_ids, project_ids])
  }

  def projects
    [project_a, project_b].compact.uniq.sort_by(&:id)
  end

  def project(this)
    projects.find { |that| that != this }
  end

  def validate
    condition = '(project_a_id = :first AND project_b_id = :second) OR' +
                '(project_b_id = :first AND project_a_id = :second)'

    condition = "(#{condition}) AND id != :id" unless new_record?

    c = self.class.where([condition, { first: project_a, second: project_b, id: id }]).count

    errors.add(:base, :project_association_already_exists) if c != 0

    [:project_a, :project_b].each do |field|
      project = send(field)
      if project.present? # otherwise the presence_of validation will be triggered
        errors.add(field, :project_association_not_allowed) unless project.allows_association?
      end
    end
  end

  def validate_projects_not_identical
    errors.add(:base, :identical_projects) if project_a == project_b
  end

  def visible?(user = User.current)
    projects.all? { |p| p.visible?(user) }
  end
end

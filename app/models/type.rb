#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class ::Type < ApplicationRecord
  extend Pagination::Model

  # Work Package attributes for this type
  # and constraints to specifc attributes (by plugins).
  include ::Type::Attributes
  include ::Type::AttributeGroups

  before_destroy :check_integrity

  has_many :work_packages
  has_many :workflows, dependent: :delete_all do
    def copy_from_type(source_type)
      Workflow.copy(source_type, nil, proxy_association.owner, nil)
    end
  end

  has_and_belongs_to_many :projects

  has_and_belongs_to_many :custom_fields,
                          class_name: 'WorkPackageCustomField',
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          association_foreign_key: 'custom_field_id'

  belongs_to :color,
             class_name: 'Color',
             foreign_key: 'color_id'

  acts_as_list

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 255 }

  validates_inclusion_of :is_default, :is_milestone, in: [true, false]

  default_scope { order('position ASC') }

  scope :without_standard, -> {
    where(is_standard: false)
      .order(:position)
  }

  def to_s; name end

  def <=>(other)
    name <=> other.name
  end

  def self.statuses(types)
    workflow_table, status_table = [Workflow, Status].map(&:arel_table)
    old_id_subselect, new_id_subselect = [:old_status_id, :new_status_id].map do |foreign_key|
      workflow_table.project(workflow_table[foreign_key]).where(workflow_table[:type_id].in(types))
    end
    Status.where(status_table[:id].in(old_id_subselect).or(status_table[:id].in(new_id_subselect)))
  end

  def self.standard_type
    ::Type.where(is_standard: true).first
  end

  def self.default
    ::Type.where(is_default: true)
  end

  def self.enabled_in(project)
    ::Type.includes(:projects).where(projects: { id: project })
  end

  def statuses(include_default: false)
    if new_record?
      Status.none
    elsif include_default
      ::Type
        .statuses([id])
        .or(Status.where_default)
    else
      ::Type.statuses([id])
    end
  end

  def enabled_in?(object)
    object.types.include?(self)
  end

  private

  def check_integrity
    raise "Can't delete type" if WorkPackage.where(type_id: id).any?
  end
end

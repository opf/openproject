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

class Type < ActiveRecord::Base
  extend Pagination::Model

  include ActiveModel::ForbiddenAttributesProtection

  before_destroy :check_integrity

  has_many :work_packages
  has_many :workflows, dependent: :delete_all do
    def copy(source_type)
      Workflow.copy(source_type, nil, proxy_association.owner, nil)
    end
  end

  has_and_belongs_to_many :projects

  has_and_belongs_to_many :custom_fields,
                          class_name: 'WorkPackageCustomField',
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          association_foreign_key: 'custom_field_id'

  belongs_to :color, class_name:  'PlanningElementTypeColor',
                     foreign_key: 'color_id'

  acts_as_list

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name,
                      maximum: 255,
                      unless: lambda { |e| e.name.blank? }

  validates_inclusion_of :in_aggregation, :is_default, :is_milestone, in: [true, false]

  default_scope order: 'position ASC'

  scope :without_standard, conditions: { is_standard: false },
                           order: :position

  def to_s; name end

  def <=>(type)
    name <=> type.name
  end

  def self.all
    find(:all, order: 'position')
  end

  def self.statuses(types)
    workflow_table, status_table = [Workflow, Status].map(&:arel_table)
    old_id_subselect, new_id_subselect = [:old_status_id, :new_status_id].map do |foreign_key|
      workflow_table.project(workflow_table[foreign_key]).where(workflow_table[:type_id].in(types))
    end
    Status.where(status_table[:id].in(old_id_subselect).or(status_table[:id].in(new_id_subselect)))
  end

  def self.standard_type
    Type.where(is_standard: true).first
  end

  def self.default
    Type.where(is_default: true)
  end

  def statuses
    return [] if new_record?
    @statuses ||= Type.statuses([id])
  end

  def enabled_in?(object)
    object.types.include?(self)
  end

  def available_colors
    PlanningElementTypeColor.all
  end

  def is_valid_transition?(status_id_a, status_id_b, roles)
    transition_exists?(status_id_a, status_id_b, roles.map(&:id))
  end

  private

  def check_integrity
    raise "Can't delete type" if WorkPackage.find(:first, conditions: ['type_id=?', id])
  end

  def transition_exists?(status_id_a, status_id_b, role_ids)
    workflows.where(old_status_id: status_id_a,
                    new_status_id: status_id_b,
                    role_id: role_ids)
      .any?
  end
end

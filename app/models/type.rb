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

class ::Type < ActiveRecord::Base
  extend Pagination::Model

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

  serialize :attribute_visibility, Hash
  validates_each :attribute_visibility do |record, _attr, visibility|
    visibility.each do |attr_name, value|
      unless attribute_visibilities.include? value.to_s
        record.errors.add(:attribute_visibility, "for '#{attr_name}' cannot be '#{value}'")
      end
    end
  end

  serialize :attribute_groups, Array

  acts_as_list

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name,
                      maximum: 255,
                      unless: lambda { |e| e.name.blank? }

  validates_inclusion_of :in_aggregation, :is_default, :is_milestone, in: [true, false]

  default_scope { order('position ASC') }

  scope :without_standard, -> {
    where(is_standard: false)
      .order(:position)
  }

  def to_s; name end

  def <=>(type)
    name <=> type.name
  end

  def self.statuses(types)
    workflow_table, status_table = [Workflow, Status].map(&:arel_table)
    old_id_subselect, new_id_subselect = [:old_status_id, :new_status_id].map { |foreign_key|
      workflow_table.project(workflow_table[foreign_key]).where(workflow_table[:type_id].in(types))
    }
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

  ##
  # The possible visibility values for a work package attribute
  # as defined by a type are:
  #
  #   - default The attribute is displayed in forms if it has a value.
  #   - visible The attribute is displayed in forms even if empty.
  #   - hidden  The attribute is hidden in forms even if it has a value.
  def self.attribute_visibilities
    ['visible', 'hidden', 'default']
  end

  def self.default_attribute_visibility
    'visible'
  end

  def statuses
    return [] if new_record?
    @statuses ||= ::Type.statuses([id])
  end

  def enabled_in?(object)
    object.types.include?(self)
  end

  def available_colors
    PlanningElementTypeColor.all
  end

  def valid_transition?(status_id_a, status_id_b, roles)
    transition_exists?(status_id_a, status_id_b, roles.map(&:id))
  end

  def attribute_groups
    groups = read_attribute :attribute_groups

    if groups.empty?
      default_attribute_groups
    else
      groups
    end
  end

  def default_attribute_groups
    values =  work_package_attributes
              .select do |key|
                [ nil,
                  'default',
                  'visible' ].include?(::TypesHelper::attr_visibility(key, self))
              end
              .group_by { |key| map_attribute_to_group key }

    ordered = []

    ordered.push ["details", values["details"]] if values["details"].try(:any?)
    ordered.push ["people", values["people"]] if values["people"].try(:any?)
    ordered.push ["estimates_and_time", values["estimates_and_time"]] if
      values["estimates_and_time"].try(:any?)
    ordered.push ["other", values["other"]] if values["other"].try(:any?)

    ordered
  end

  def map_attribute_to_group(name)
    if ["author", "assignee", "reponsible"].include?(name)
      "people"
    elsif ["estimated_time", "spent_time"].include?(name)
      "estimates_and_time"
    elsif name =~ /custom/
      "other"
    else
      "details"
    end
  end

  def work_package_attributes
    ::TypesHelper.work_package_form_attributes(merge_date: true).keys
  end

  private

  def check_integrity
    raise "Can't delete type" if WorkPackage.where(['type_id=?', id]).any?
  end

  def transition_exists?(status_id_a, status_id_b, role_ids)
    workflows.where(old_status_id: status_id_a,
                    new_status_id: status_id_b,
                    role_id: role_ids)
      .any?
  end
end

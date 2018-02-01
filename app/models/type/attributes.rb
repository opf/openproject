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

module Type::Attributes
  extend ActiveSupport::Concern

  included do
    # Allow plugins to define constraints
    # that disable a given attribute for this type.
    mattr_accessor :attribute_constraints do
      {}
    end
  end

  class_methods do
    ##
    # Add a constraint for the given attribute
    def add_constraint(attribute, callable)
      unless callable.respond_to?(:call)
        raise ArgumentError, "Expecting callable object for constraint #{key}"
      end

      attribute_constraints[attribute.to_sym] = callable
    end

    ##
    # Provides a map of all work package form attributes as seen when creating
    # or updating a work package. Through this map it can be checked whether or
    # not an attribute is required.
    #
    # E.g.
    #
    #   ::Type.work_package_form_attributes['author'][:required] # => true
    #
    # @return [Hash{String => Hash}] Map from attribute names to options.
    def all_work_package_form_attributes(merge_date: false)
      OpenProject::Cache.fetch('all_work_package_form_attributes',
                               *WorkPackageCustomField.pluck('max(updated_at), count(id)').flatten,
                               merge_date) do
        calculate_all_work_package_form_attributes(merge_date)
      end
    end

    def translated_work_package_form_attributes(merge_date: false)
      all_work_package_form_attributes(merge_date: merge_date)
        .each_with_object({}) do |(k, v), hash|
        hash[k] = translated_attribute_name(k, v)
      end
    end

    def translated_attribute_name(name, attr)
      if attr[:name_source]
        attr[:name_source].call
      else
        attr[:display_name] || attr_translate(name)
      end
    end

    private

    def calculate_all_work_package_form_attributes(merge_date)
      attributes = calculate_default_work_package_form_attributes

      # within the form date is shown as a single entry including start and due
      if merge_date
        merge_date_for_form_attributes(attributes)
      end

      add_custom_fields_to_form_attributes(attributes)

      attributes
    end

    def calculate_default_work_package_form_attributes
      representable_config = API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter
                             .representable_attrs

      # For reasons beyond me, Representable::Config contains the definitions
      #  * nested in [:definitions] in some envs, e.g. development
      #  * directly in other envs, e.g. test
      definitions = representable_config.key?(:definitions) ? representable_config[:definitions] : representable_config

      skip = ['_type', '_dependencies', 'attribute_groups', 'links', 'parent_id', 'parent', 'description']
      definitions.keys
                 .reject { |key| skip.include?(key) || definitions[key][:required] }
                 .map { |key| [key, JSON::parse(definitions[key].to_json)] }.to_h
    end

    def merge_date_for_form_attributes(attributes)
      attributes['date'] = { required: false, has_default: false }
      attributes.delete 'due_date'
      attributes.delete 'start_date'
    end

    def add_custom_fields_to_form_attributes(attributes)
      WorkPackageCustomField.includes(:custom_options).all.each do |field|
        attributes["custom_field_#{field.id}"] = {
          required: field.is_required,
          has_default: field.default_value.present?,
          is_cf: true,
          display_name: field.name
        }
      end
    end


    def attr_i18n_key(name)
      if name == 'percentage_done'
        'done_ratio'
      else
        name
      end
    end

    def attr_translate(name)
      if name == 'date'
        I18n.t('label_date')
      else
        key = attr_i18n_key(name)
        I18n.t("activerecord.attributes.work_package.#{key}", default: '')
          .presence || I18n.t("attributes.#{key}")
      end
    end
  end

  def attr_form_map(key, represented)
    {
      key: key,
      is_cf: custom_field?(key),
      is_required: represented[:required] && !represented[:has_default],
      translation: self.class.translated_attribute_name(key, represented)
    }
  end

  def custom_field?(attribute_name)
    attribute_name.to_s.start_with? 'custom_field_'
  end

  ##
  # Get all applicale work package attributes
  def work_package_attributes(merge_date: true)
    all_attributes = self.class.all_work_package_form_attributes(merge_date: merge_date)

    # Reject those attributes that are not available for this type.
    all_attributes.select { |key, _| passes_attribute_constraint? key }
  end

  ##
  # Verify that the given attribute is applicable
  # in this type instance.
  # If a project context is given, that context is passed
  # to the constraint validator.
  def passes_attribute_constraint?(attribute, project: nil)
    # Check custom field constraints
    if custom_field?(attribute) && !project.nil?
      return custom_field_in_project?(attribute, project)
    end

    # Check other constraints (none in the core, but costs/backlogs adds constraints)
    constraint = attribute_constraints[attribute.to_sym]
    constraint.nil? || constraint.call(self, project: project)
  end

  ##
  # Returns whether this type has the custom field currently
  # (e.g. because it was checked in the removed CF view).
  def has_custom_field?(attribute)
    @has_custom_field_custom_field_ids ||= custom_field_ids.map { |id| "custom_field_#{id}" }

    @has_custom_field_custom_field_ids.include? attribute
  end

  ##
  # Returns whether the custom field is active in the given project.
  def custom_field_in_project?(attribute, project)
    project
      .all_work_package_custom_fields.pluck(:id)
      .map { |id| "custom_field_#{id}" }
      .include? attribute
  end
end

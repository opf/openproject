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

require 'reform'
require 'reform/form/active_model/model_validations'

class ModelContract < Reform::Contract
  class << self
    def writable_attributes
      @writable_attributes ||= []
    end

    def writable_conditions
      @writable_conditions ||= []
    end

    def attribute_validations
      @attribute_validations ||= []
    end

    def attribute_permissions
      @attribute_permissions ||= {}
    end

    def attribute_aliases
      @attribute_aliases ||= {}
    end

    def attribute_alias(db, outside)
      attribute_aliases[db] = outside
    end

    def attribute(attribute, options = {}, &block)
      property attribute

      add_writable(attribute, options[:writeable])
      attribute_permission(attribute, options[:permission])

      if block
        attribute_validations << block
      end
    end

    def default_attribute_permission(permission)
      attribute_permission(:default_permission, permission)
    end

    def attribute_permission(attribute, permission)
      return unless permission

      attribute_permissions[attribute] = Array(permission)
    end

    private

    def add_writable(attribute, writeable)
      attribute_name = attribute.to_s.gsub /_id\z/, ''

      unless writeable == false
        writable_attributes << attribute_name
        # allow the _id variant as well
        writable_attributes << "#{attribute_name}_id"
      end

      if writeable.respond_to?(:call)
        writable_conditions << [attribute_name, writeable]
      end
    end
  end

  attr_reader :user
  attr_accessor :options

  def initialize(model, user, options: {})
    super(model)

    @user = user
    @options = options
  end

  # we want to add a validation error whenever someone sets a property that we don't know.
  # However AR will cleverly try to resolve the value for erroneous properties. Thus we need
  # to hook into this method and return nil for unknown properties to avoid NoMethod errors...
  def read_attribute_for_validation(attribute)
    if respond_to? attribute
      send attribute
    end
  end

  def writable_attributes
    @writable_attributes ||= begin
      reduce_writable_attributes(collect_writable_attributes)
    end
  end

  def writable?(attribute)
    writable_attributes.include?(attribute.to_s)
  end

  def validate
    readonly_attributes_unchanged
    run_attribute_validations

    super

    # Allow subclasses to check only contract errors
    return errors.empty? unless validate_model?

    model.valid?

    # We need to merge the contract errors with the model errors in
    # order to have them available at one place.
    # This is something we need as long as we have validations split
    # among the model and its contract.
    errors.merge!(model.errors, [])

    errors.empty?
  end

  # Methods required to get ActiveModel error messages working
  extend ActiveModel::Naming

  def self.model_name
    ActiveModel::Name.new(model, nil)
  end

  def self.model
    @model ||= name.deconstantize.singularize.constantize
  end

  # use activerecord as the base scope instead of 'activemodel' to be compatible
  # to the messages we have already stored
  def self.i18n_scope
    :activerecord
  end
  # end Methods required to get ActiveModel error messages working

  protected

  ##
  # Allow subclasses to disable model validation
  # during contract validation.
  #
  # This is necessary during, e.g., deletion contract validations
  # to ensure invalid models can be deleted when allowed.
  def validate_model?
    true
  end

  private

  def readonly_attributes_unchanged
    invalid_changes = attributes_changed_by_user - writable_attributes

    invalid_changes.each do |attribute|
      outside_attribute = collect_ancestor_attribute_aliases[attribute] || attribute

      errors.add outside_attribute, :error_readonly
    end
  end

  def attributes_changed_by_user
    changed = model.changed

    if options[:changed_by_system]
      changed -= options[:changed_by_system]
    end

    changed
  end

  def run_attribute_validations
    attribute_validations.each { |validation| instance_exec(&validation) }
  end

  def attribute_validations
    collect_ancestor_attributes(:attribute_validations)
  end

  def collect_ancestor_attribute_aliases
    @ancestor_attribute_aliases ||= collect_ancestor_attributes(:attribute_aliases)
  end

  # Traverse ancestor hierarchy to collect contract information.
  # This allows to define attributes on a common base class of two or more contracts.
  def collect_ancestor_attributes(attribute_to_collect)
    combination_method, cleanup_method = if self.class.send(attribute_to_collect).is_a?(Hash)
                                           %i[merge with_indifferent_access]
                                         else
                                           %i[concat uniq]
                                         end

    collect_ancestor_attributes_by(attribute_to_collect, combination_method, cleanup_method)
  end

  def collect_ancestor_attributes_by(attribute_to_collect, combination_method, cleanup_method)
    klass = self.class
    # `dup` is very important here.
    # As the array/hash queried for here is memoized in the class (e.g. writable_conditions) and that
    # object is later on combined (e.g. with #concat which alters the called on object) with a
    # similar object from the superclass, every call would alter the memoized object as an unwanted side effect.
    # Not only would that lead to the subclass now having all the attributes of the superclass,
    # but those attributes would also be duplicated so that performance suffers significantly.
    attributes = klass.send(attribute_to_collect).dup

    while klass.superclass != ModelContract
      # Collect all the attribute_to_collect from ancestors
      klass = klass.superclass

      attributes = attributes.send(combination_method, klass.send(attribute_to_collect))
    end

    attributes.send(cleanup_method)
  end

  def collect_writable_attributes
    writable = collect_ancestor_attributes(:writable_attributes)

    writable.each do |attribute|
      if collect_ancestor_attribute_aliases[attribute]
        writable << collect_ancestor_attribute_aliases[attribute].to_s
      end
    end

    if model.respond_to?(:available_custom_fields)
      writable += model.available_custom_fields.map { |cf| "custom_field_#{cf.id}" }
    end

    writable
  end

  def reduce_writable_attributes(attributes)
    attributes = reduce_by_writable_conditions(attributes)
    reduce_by_writable_permissions(attributes)
  end

  def reduce_by_writable_conditions(attributes)
    collect_ancestor_attributes(:writable_conditions).each do |attribute, condition|
      attributes -= [attribute, "#{attribute}_id"] unless instance_exec(&condition)
    end

    attributes
  end

  def reduce_by_writable_permissions(attributes)
    attribute_permissions = collect_ancestor_attributes(:attribute_permissions)

    attributes.reject do |attribute|
      canonical_attribute = attribute.gsub(/_id\z/, '')

      permissions = attribute_permissions[canonical_attribute] ||
                    attribute_permissions["#{canonical_attribute}_id"] ||
                    attribute_permissions[:default_permission]

      next unless permissions

      # This will break once a model that does not respond to project is used.
      # This is intended to be worked on then with the additional knowledge.
      next if permissions.any? { |p| user.allowed_to?(p, model.project, global: model.project.nil?) }

      true
    end
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class BaseContract < Disposable::Twin
  require "disposable/twin/composition" # Expose.
  include Expose

  feature Setup
  feature Setup::SkipSetter
  feature Default

  include ActiveModel::Validations
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  # Allows human_attribute_name to resolve custom fields correctly
  extend Redmine::Acts::Customizable::HumanAttributeName

  delegate :id,
           to: :model

  class << self
    def writable_attributes
      @writable_attributes ||= []
    end

    def writable_conditions
      @writable_conditions ||= []
    end

    def attribute_permissions
      @attribute_permissions ||= {}
    end

    def attribute_aliases
      @attribute_aliases ||= {}
    end

    def attribute_alias(db, outside)
      raise "Cannot define the alias to #{db} to be the same: #{outside}" if db == outside

      attribute_aliases[db] = outside
    end

    def property(name, options = {}, &)
      if (twin = options.delete(:form))
        options[:twin] = twin
      end

      if (validates_options = options[:validates])
        validates name, validates_options
      end

      super
    end

    def attribute(attribute, options = {}, &block)
      property attribute, options.slice(:readable)

      add_writable(attribute, options[:writable])
      attribute_permission(attribute, options[:permission])

      validate(attribute, &block) if block
    end

    def default_attribute_permission(permission)
      attribute_permission(:default_permission, permission)
    end

    def attribute_permission(attribute, permission)
      return unless permission

      attribute_permissions[attribute] = Array(permission)
    end

    private

    def add_writable(attribute, writable)
      attribute_name = attribute.to_s.delete_suffix('_id')

      unless writable == false
        writable_attributes << attribute_name
        # allow the _id variant as well
        writable_attributes << "#{attribute_name}_id"
      end

      if writable.respond_to?(:call)
        writable_conditions << [attribute_name, writable]
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
    @writable_attributes ||= reduce_writable_attributes(collect_writable_attributes)
  end

  def writable?(attribute)
    writable_attributes.include?(attribute.to_s)
  end

  # Provide same interface with valid? and validate
  # as with AM::Validations
  #
  # Do not use alias_method as this will not work when
  # valid? is overridden in subclasses
  def validate(*)
    valid?(*)
  end

  # Methods required to get ActiveModel error messages working
  extend ActiveModel::Naming

  def self.model_name
    ActiveModel::Name.new(model, nil)
  end

  def self.model
    @model ||= begin
      name.deconstantize.singularize.constantize
    rescue NameError
      ActiveRecord::Base
    end
  end

  # use activerecord as the base scope instead of 'activemodel' to be compatible
  # to the messages we have already stored
  def self.i18n_scope
    :activerecord
  end
  # end Methods required to get ActiveModel error messages working

  protected

  def ancestor_attribute_aliases
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

    while klass.superclass != ::BaseContract
      # Collect all the attribute_to_collect from ancestors
      klass = klass.superclass

      attributes = attributes.send(combination_method, klass.send(attribute_to_collect))
    end

    attributes.send(cleanup_method)
  end

  def collect_writable_attributes
    writable = collect_ancestor_attributes(:writable_attributes)

    writable.each do |attribute|
      if ancestor_attribute_aliases[attribute]
        writable << ancestor_attribute_aliases[attribute].to_s
      end
    end

    if model.respond_to?(:available_custom_fields)
      writable += model.available_custom_fields.map(&:attribute_name)
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

    attributes.select do |attribute|
      canonical_attribute = attribute.delete_suffix('_id')

      permissions = attribute_permissions[canonical_attribute] ||
                    attribute_permissions["#{canonical_attribute}_id"] ||
                    attribute_permissions[:default_permission]

      permissions.blank? || permissions.any? { |permission| permitted?(permission) }
    end
  end

  def permitted?(permission)
    if Member.can_be_member_of?(model)
      user.allowed_to_in_entity?(permission, model)
    elsif model.respond_to?(:project) && model.project
      user.allowed_to_in_project?(permission, model.project)
    else
      user.allowed_to_globally?(permission)
    end
  end
end

#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

    def attribute(attribute, options = {}, &block)
      property attribute

      add_writable(attribute, options[:writeable])

      if block
        attribute_validations << block
      end
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

  def initialize(model, user)
    super(model)

    @user = user
  end

  # we want to add a validation error whenever someone sets a property that we don't know.
  # However AR will cleverly try to resolve the value for errorneous properties. Thus we need
  # to hook into this method and return nil for unknown properties to avoid NoMethod errors...
  def read_attribute_for_validation(attribute)
    if respond_to? attribute
      send attribute
    end
  end

  def writable_attributes
    writable = collect_ancestor_attributes(:writable_attributes)

    collect_ancestor_attributes(:writable_conditions).each do |attribute, condition|
      writable -= [attribute, "#{attribute}_id"] unless instance_exec(&condition)
    end

    writable
  end

  def validate
    readonly_attributes_unchanged
    run_attribute_validations

    super
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
    raise NotImplementedError
  end

  # use activerecord as the base scope instead of 'activemodel' to be compatible
  # to the messages we have already stored
  def self.i18n_scope
    :activerecord
  end
  # end Methods required to get ActiveModel error messages working

  private

  def readonly_attributes_unchanged
    invalid_changes = model.changed - writable_attributes

    invalid_changes.each do |attribute|
      errors.add attribute, :error_readonly
    end
  end

  def run_attribute_validations
    attribute_validations.each { |validation| instance_exec(&validation) }
  end

  def attribute_validations
    collect_ancestor_attributes(:attribute_validations)
  end

  # Traverse ancestor hierarchy to collect contract information.
  # This allows to define attributes on a common base class of two or more contracts.
  def collect_ancestor_attributes(attribute_to_collect)
    attributes = []
    klass = self.class
    while klass != ModelContract
      # Collect all the attribute_to_collect from ancestors
      attributes += klass.send(attribute_to_collect)
      klass = klass.superclass
    end
    attributes.uniq
  end
end

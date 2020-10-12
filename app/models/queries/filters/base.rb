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

require 'queries/operators'

class Queries::Filters::Base
  include ActiveModel::Validations

  def self.i18n_scope
    :activerecord
  end

  class_attribute :model,
                  :filter_params

  self.filter_params = %i(operator values)

  attr_accessor :context, *filter_params
  attr_reader :name
  alias :field :name

  def initialize(name, options = {})
    @name = name.to_sym
    self.context = options[:context]

    self.class.filter_params.each do |param_field|
      send("#{param_field}=", options[param_field])
    end
  end

  ##
  # Treat the constructor as private, as the filter MAY need to check
  # the options before accepting them as a filter.
  #
  # Use +#create+ instead.
  private_class_method :new

  ##
  # Creates a filter instance with the given name if the options are acceptable.
  # Raises an +InvalidFilterError+ if the given filter cannot be created with this option.
  def self.create!(name: key, **options)
    new(name, options)
  end

  def [](name)
    send(name)
  end

  def filter_instance_options
    values = filter_params.map { |key| [key, send(key)] }
    initial_options.merge(Hash[values])
  end

  def human_name
    raise NotImplementedError
  end

  def type
    raise NotImplementedError
  end

  def allowed_values
    nil
  end

  def valid_values!
    type_strategy.valid_values!
  end

  def available?
    true
  end

  def available_operators
    type_strategy.supported_operator_classes
  end

  def default_operator
    type_strategy.default_operator_class
  end

  def scope
    scope = model.where(where)
    scope = scope.joins(joins) if joins
    scope = scope.left_outer_joins(left_outer_joins) if left_outer_joins
    scope
  end

  def self.key
    to_s.demodulize.underscore.gsub(/_filter$/, '').to_sym
  end

  def self.connection
    model.connection
  end

  def self.all_for(context = nil)
    create!(name: key, context: context)
  end

  def where
    operator_strategy.sql_for_field(values, self.class.model.table_name, self.class.key)
  end

  def joins
    nil
  end

  def left_outer_joins
    nil
  end

  def includes
    nil
  end

  validate :validate_inclusion_of_operator,
           :validate_presence_of_values,
           :validate_values

  def values
    @values || []
  end

  # Values may contain an internal representation for some filters
  alias :values_replaced :values

  def values=(values)
    @values = Array(values).map(&:to_s)
  end

  # Does the filter filter on other models, e.g. User, Status
  def ar_object_filter?
    false
  end

  # List of objects the value represents
  # is empty if the filter does not filter on other AR objects
  def value_objects
    []
  end

  def operator_class
    operator_strategy
  end

  def error_messages
    messages = errors
               .full_messages
               .join(" #{I18n.t('support.array.sentence_connector')} ")

    errors.full_message(human_name, messages)
  end

  protected

  def type_strategy
    @type_strategy ||= Queries::Filters::STRATEGIES[type].new(self)
  end

  def operator_strategy
    type_strategy.operator
  end

  def validate_inclusion_of_operator
    unless operator && available_operators.map(&:to_sym).include?(operator.to_sym)
      errors.add(:operator, :inclusion)
    end
  end

  def validate_presence_of_values
    if operator_strategy && operator_strategy.requires_value? && (values.nil? || values.reject(&:blank?).empty?)
      errors.add(:values, I18n.t('activerecord.errors.messages.blank'))
    end
  end

  def validate_values
    type_strategy.validate
  end
end

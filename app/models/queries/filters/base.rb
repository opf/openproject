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

require 'queries/operators'

class Queries::Filters::Base
  include ActiveModel::Validations

  class_attribute :model,
                  :filter_params

  self.filter_params = %i(operator values)

  attr_accessor :context,
                *filter_params

  def initialize(options = {})
    self.context = options[:context]

    self.class.filter_params.each do |param_field|
      send("#{param_field}=", options[param_field])
    end
  end

  def [](name)
    send(name)
  end

  def name
    @name || self.class.key
  end
  alias :field :name

  def name=(name)
    @name = name.to_sym
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

  def scope
    scope = model.where(where)
    scope = scope.joins(joins) if joins
    scope
  end

  def self.key
    to_s.demodulize.underscore.gsub(/_filter$/, '').to_sym
  end

  def self.connection
    model.connection
  end

  def self.all_for(context = nil)
    filter = new
    filter.context = context
    filter
  end

  def where
    operator_strategy.sql_for_field(values, self.class.model.table_name, self.class.key)
  end

  def joins
    nil
  end

  validate :validate_inclusion_of_operator,
           :validate_presence_of_values,
           :validate_values

  def values
    @values || []
  end

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

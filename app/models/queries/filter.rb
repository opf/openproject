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

class Queries::Filter
  include ActiveModel::Validations
  include ActiveModel::Serialization

  class_attribute :filter_types_by_field, instance_writer: false

  self.filter_types_by_field = {
    created_at: :date_past,
    updated_at: :date_past
  }

  @@filter_params = [:operator, :values] # will be serialized and persisted with the query

  @@operators = {
    label_equals:               '=',
    label_not_equals:           '!',
    label_open_work_packages:   'o',
    label_closed_work_packages: 'c',
    label_none:                 '!*',
    label_all:                  '*',
    label_greater_or_equal:     '>=',
    label_less_or_equal:        '<=',
    label_in_less_than:         '<t+',
    label_in_more_than:         '>t+',
    label_in:                   't+',
    label_today:                't',
    label_this_week:            'w',
    label_less_than_ago:        '>t-',
    label_more_than_ago:        '<t-',
    label_ago:                  't-',
    label_contains:             '~',
    label_not_contains:         '!~'
  }.invert

  @@operators_not_requiring_values = %w(o c !* * t w)

  @@operators_by_filter_type = {
    list:             ['=', '!'],
    list_status:      ['o', '=', '!', 'c', '*'],
    list_optional:    ['=', '!', '!*', '*'],
    list_subprojects: ['*', '!*', '='],
    date:             ['<t+', '>t+', 't+', 't', 'w', '>t-', '<t-', 't-'],
    date_past:        ['>t-', '<t-', 't-', 't', 'w'],
    string:           ['=', '~', '!', '!~'],
    text:             ['~', '!~'],
    integer:          ['=', '>=', '<=', '!*', '*']
  }

  cattr_reader :operators, :operators_by_filter_type

  attr_accessor :field, *@@filter_params

  validates_presence_of :field
  validate :validate_presence_of_values, unless: Proc.new { |filter| @@operators_not_requiring_values.include?(filter.operator) }
  validate :validate_filter_values

  def initialize(field = nil, options = {})
    self.field = field
    values = []

    @@filter_params.each do |param_field|
      send("#{param_field}=", options[param_field])
    end
  end

  # (de-)serialization
  def self.from_hash(filter_hash)
    filter_hash.keys.map { |field| new(field, filter_hash[field]) }
  end

  def to_hash
    { field => attributes_hash }
  end

  alias_method :name, :field

  def attributes
    { name: name, operator: operator, values: values }
  end

  def field=(field)
    @field = field.try :to_sym
  end

  def possible_types_by_operator
    @@operators_by_filter_type.select { |_key, operators| operators.include?(operator) }.keys.sort
  end

  def type
    filter_types_by_field[field]
  end

  def ==(filter)
    filter.attributes_hash == attributes_hash
  end

  protected

  def attributes_hash
    @@filter_params.inject({}) do |params, param_field|
      params.merge(param_field => send(param_field))
    end
  end

  private

  def validate_presence_of_values
    errors.add(:values, I18n.t('activerecord.errors.messages.blank')) if values.nil? || values.reject(&:blank?).empty?
  end

  def validate_filter_values
    return true if @@operators_not_requiring_values.include?(operator)

    case type
    when :integer
      errors.add(:values, I18n.t('activerecord.errors.messages.not_an_integer')) unless values.all? { |value| is_integer?(value) }
    when :date, :date_past
      errors.add(:values, I18n.t('activerecord.errors.messages.not_an_integer')) unless values.all? { |value| is_integer?(value) }
      # ...
    end
  end

  def is_integer?(str)
    true if Integer(str) rescue false
  end
end

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

class CustomField < ActiveRecord::Base
  include CustomField::OrderStatements

  has_many :custom_values, dependent: :delete_all
  has_many :custom_options, -> { order(position: :asc) }, dependent: :delete_all
  accepts_nested_attributes_for :custom_options

  acts_as_list scope: 'type = \'#{self.class}\''

  validates :field_format, presence: true
  validates :custom_options,
            presence: { message: I18n.t(:'activerecord.errors.models.custom_field.at_least_one_custom_option') },
            if: ->(*) { field_format == 'list' }
  validates :name, presence: true, length: { maximum: 30 }

  validate :uniqueness_of_name_with_scope

  def uniqueness_of_name_with_scope
    taken_names = CustomField.where(type: type)
    taken_names = taken_names.where('id != ?', id) if id
    taken_names = taken_names.pluck(:name)

    errors.add(:name, :taken) if name.in?(taken_names)
  end

  validates_inclusion_of :field_format, in: OpenProject::CustomFieldFormat.available_formats

  validate :validate_default_value
  validate :validate_regex

  validates :min_length, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_length, numericality: { less_than_or_equal_to: :max_length, message: :smaller_than_or_equal_to_max_length },
                         unless: Proc.new { |cf| cf.max_length.blank? }

  before_validation :check_searchability

  # make sure int, float, date, and bool are not searchable
  def check_searchability
    self.searchable = false if %w(int float date bool).include?(field_format)
    true
  end

  def default_value
    if list?
      ids = custom_options.select(&:default_value).map(&:id)

      if multi_value?
        ids
      else
        ids.first
      end
    else
      val = read_attribute :default_value
      cast_value val
    end
  end

  def validate_default_value
    # It is not possible to determine the validity of a value, when there is no valid format.
    # another validation will take care of adding an error, but here we need to abort.
    # Also multi value custom fields don't use this field at all, so don't validate it.
    return nil if field_format.blank? || multi_value?

    begin
      required_field = is_required
      self.is_required = false
      v = CustomValue.new(custom_field: self, value: default_value, customized: nil)

      errors.add(:default_value, :invalid) unless v.valid?
    ensure
      self.is_required = required_field
    end
  end

  def validate_regex
    Regexp.new(regexp) if has_regexp?
    true
  rescue RegexpError
    errors.add(:regexp, :invalid)
  end

  def has_regexp?
    regexp.present?
  end

  def required?
    is_required?
  end

  def possible_values_options(obj = nil)
    case field_format
    when 'user', 'version'
      if obj.is_a?(Project)
        possible_values_options_in_project(obj)
      elsif obj.try(:project)
        possible_values_options_in_project(obj.project)
      else
        []
      end
    when 'list'
      possible_values.map { |option| [option.value, option.id.to_s] }
    else
      possible_values
    end
  end

  ##
  # Returns possible values for this custom field.
  # Options may be a customizable, or options suitable for ActiveRecord#read_attribute.
  # Notes: You SHOULD pass a customizable if this CF has a format of user or version.
  #        You MUST NOT pass a customizable if this CF has any other format
  def possible_values(obj = nil)
    case field_format
    when 'user', 'version'
      possible_values_options(obj).map(&:last)
    when 'list'
      custom_options
    else
      read_attribute(:possible_values)
    end
  end

  # Makes possible_values accept a multiline string
  def possible_values=(arg)
    values = possible_values_from_arg arg

    max_position = custom_options.size
    values.zip(custom_options).each_with_index do |(value, custom_option), i|
      if custom_option
        custom_option.value = value
      else
        custom_options.build position: i + 1, value: value
      end

      max_position = i + 1
    end

    custom_options.where("position > ?", max_position).destroy_all
  end

  def cast_value(value)
    casted = nil
    unless value.blank?
      case field_format
      when 'string', 'text', 'list'
        casted = value
      when 'date'
        casted = begin; value.to_date; rescue; nil end
      when 'bool'
        casted = ActiveRecord::Type::Boolean.new.cast(value)
      when 'int'
        casted = value.to_i
      when 'float'
        casted = value.to_f
      when 'user', 'version'
        casted = (value.blank? ? nil : field_format.classify.constantize.find_by(id: value.to_i))
      end
    end
    casted
  end

  def <=>(field)
    if type == 'WorkPackageCustomField'
      name.downcase <=> field.name.downcase
    else
      position <=> field.position
    end
  end

  def self.customized_class
    name =~ /\A(.+)CustomField\z/
    begin
      $1.constantize
    rescue
      nil
    end
  end

  # to move in project_custom_field
  def self.for_all(options = {})
    where(is_for_all: true)
      .includes(options[:include])
      .order("#{table_name}.position")
  end

  def self.filter
    where(is_filter: true)
  end

  def accessor_name
    "custom_field_#{id}"
  end

  def type_name
    nil
  end

  def name_locale
    name
  end

  def list?
    field_format == "list"
  end

  def multi_value?
    multi_value
  end

  ##
  # Overrides cache key so that a custom field's representation
  # is updated correctly when it's mutli_value attribute changes.
  def cache_key
    tag = multi_value? ? "mv" : "sv"

    super + '/' + tag
  end

  private

  def possible_values_options_in_project(project)
    case field_format
    when 'user'
      project.users
    when 'version'
      project.versions
    else
      []
    end.sort.map { |u| [u.to_s, u.id.to_s] }
  end

  def possible_values_from_arg(arg)
    if arg.is_a?(Array)
      arg.compact.map(&:strip).reject(&:blank?)
    else
      arg.to_s.split(/[\n\r]+/).map(&:strip).reject(&:blank?)
    end
  end
end

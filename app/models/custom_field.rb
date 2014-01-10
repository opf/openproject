#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
#

class CustomField < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_many :custom_values, :dependent => :delete_all
  acts_as_list :scope => 'type = \'#{self.class}\''
  translates :name,
             :default_value,
             :possible_values

  accepts_nested_attributes_for :translations,
                                :allow_destroy => true,
                                :reject_if => :blank_attributes

  def translations_attributes_with_globalized=(attr)
    ret = self.translations_attributes_without_globalized=(attr)

    # enable globalize to access newly set attributes
    translations.loaded
    # remove previously set translated attributes so that they do not override
    # the ones set here
    globalize.reset
    globalize.stash.clear

    ret
  end

  alias_method_chain :translations_attributes=, :globalized

  validates_presence_of :name, :field_format

  validate :uniquess_of_name_with_scope
  def uniquess_of_name_with_scope
    taken_names = CustomField.where(:type => type)
    taken_names = taken_names.where('id != ?', id) if id
    taken_names = taken_names.map { |cf| cf.read_attribute(:name, :locale => I18n.locale) }

    errors.add(:name, :taken) if name.in?(taken_names)
  end

  validates_length_of :name, :maximum => 30
  validates_inclusion_of :field_format, :in => Redmine::CustomFieldFormat.available_formats

  validate :validate_presence_of_possible_values
  validate :validate_default_value_in_translations

  def initialize(attributes = nil, options = {})
    super
    self.possible_values ||= []
  end

  before_validation :check_searchability

  # make sure int, float, date, and bool are not searchable
  def check_searchability
    self.searchable = false if %w(int float date bool).include?(field_format)
    true
  end

  def validate_presence_of_possible_values
    if self.field_format == "list"
      errors.add(:possible_values, :blank) if self.possible_values.blank?
      errors.add(:possible_values, :invalid) unless self.possible_values.is_a? Array
    end
  end

  # validate default value in every translation available
  def validate_default_value_in_translations
    required_field = self.is_required
    self.is_required = false
    translated_locales = (translations.map(&:locale) + self.translated_locales).uniq
    translated_locales.each do |locale|
      I18n.with_locale(locale) do
        v = CustomValue.new(:custom_field => self, :value => default_value, :customized => nil)
        errors.add(:default_value, :invalid) unless v.valid?
      end
    end
    self.is_required = required_field
  end

  def possible_values_options(obj=nil)
    case field_format
    when 'user', 'version'
      if obj.respond_to?(:project) && obj.project
        case field_format
        when 'user'
          obj.project.users.sort.collect {|u| [u.to_s, u.id.to_s]}
        when 'version'
          obj.project.versions.sort.collect {|u| [u.to_s, u.id.to_s]}
        end
      else
        []
      end
    else
      locale = obj if obj.is_a?(String) || obj.is_a?(Symbol)
      attribute = possible_values(:locale => locale)
      attribute
    end
  end

  ##
  # Returns possible values for this custom field.
  # Options may be a user, or options suitable for ActiveRecord#read_attribute.
  # read_attribute is localized - to get values for a specific locale pass the following options hash
  # :locale => <locale (-> :en, :de, ...)>
  def possible_values(obj=nil)
    case field_format
    when 'user'
      possible_values_options(obj).collect(&:last)
    else
      options = obj.nil? ? {} : obj
      read_attribute(:possible_values, options)
    end
  end

  # Makes possible_values accept a multiline string
  def possible_values=(arg)
    if arg.is_a?(Array)
      value = arg.compact.collect(&:strip).select{ |v| !v.blank? }

      write_attribute(:possible_values, value, {})
    else
      self.possible_values = arg.to_s.split(/[\n\r]+/)
    end
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
        casted = (value == '1' ? true : false)
      when 'int'
        casted = value.to_i
      when 'float'
        casted = value.to_f
      when 'user', 'version'
        casted = (value.blank? ? nil : field_format.classify.constantize.find_by_id(value.to_i))
      end
    end
    casted
  end

  # Returns a ORDER BY clause that can used to sort customized
  # objects by their value of the custom field.
  # Returns false, if the custom field can not be used for sorting.
  def order_statement
    customized_class = self.class.customized_class
    klass = (customized_class.superclass && !(customized_class.superclass == ActiveRecord::Base)) ? customized_class.superclass : customized_class

    case field_format
      when 'string', 'text', 'list', 'date', 'bool'
        # COALESCE is here to make sure that blank and NULL values are sorted equally
        "COALESCE((SELECT cv_sort.value FROM #{CustomValue.table_name} cv_sort" +
          " WHERE cv_sort.customized_type='#{klass.name}'" +
          " AND cv_sort.customized_id=#{klass.table_name}.id" +
          " AND cv_sort.custom_field_id=#{id} LIMIT 1), '')"
      when 'int', 'float'
        # Make the database cast values into numeric
        # Postgresql will raise an error if a value can not be casted!
        # CustomValue validations should ensure that it doesn't occur
        "(SELECT CAST(cv_sort.value AS decimal(60,3)) FROM #{CustomValue.table_name} cv_sort" +
          " WHERE cv_sort.customized_type='#{klass.name}'" +
          " AND cv_sort.customized_id=#{klass.table_name}.id" +
          " AND cv_sort.custom_field_id=#{id} AND cv_sort.value <> '' AND cv_sort.value IS NOT NULL LIMIT 1)"
      else
        nil
    end
  end

  def <=>(field)
    position <=> field.position
  end

  def self.customized_class
    self.name =~ /\A(.+)CustomField\z/
    begin; $1.constantize; rescue nil; end
  end

  # to move in project_custom_field
  def self.for_all(options = {})
    options.merge!({:conditions => ["is_for_all=?", true], :order => 'position'})
    find :all, options
  end

  def type_name
    nil
  end

  def name_locale
    locales = translations.where(name: name, locale: I18n.locale)

    locales.empty? ? translations.where(name: name).first.locale : I18n.locale
  end

  private

  def blank_attributes(attributes)
    value_keys = attributes.reject{ |k,v| v.blank? }.keys.map(&:to_sym)

    !value_keys.include?(:locale) || (value_keys & translated_attribute_names).size == 0
  end
end

# for the sake of nested attributes it is necessary to redefine possible_values
# the values get set directly on the translations association

class CustomField::Translation < Globalize::ActiveRecord::Translation
  serialize :possible_values

  def possible_values=(arg)
    if arg.is_a?(Array)
      value = arg.compact.collect(&:strip).select {|v| !v.blank?}

      write_attribute(:possible_values, value)
    else
      self.possible_values = arg.to_s.split(/[\n\r]+/)
    end
  end

end

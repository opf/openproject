#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
#

class CustomField < ActiveRecord::Base
  has_many :custom_values, :dependent => :delete_all
  acts_as_list :scope => 'type = \'#{self.class}\''
  translates :name,
             :default_value,
             :possible_values

  accepts_nested_attributes_for :translations,
                                :allow_destroy => true,
                                :reject_if =>  proc { |attributes| attributes['locale'].blank? ||
                                                                   (attributes.size == 1 && attributes.has_key?('locale')) }

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
  validates_uniqueness_of :name, :scope => [:type, :locale]
  validates_length_of :name, :maximum => 30
  validates_inclusion_of :field_format, :in => Redmine::CustomFieldFormat.available_formats

  def initialize(attributes = nil)
    super
    self.possible_values ||= []
  end

  def before_validation
    # make sure these fields are not searchable
    self.searchable = false if %w(int float date bool).include?(field_format)
    true
  end

  def validate
    if self.field_format == "list"
      errors.add(:possible_values, :blank) if self.possible_values.nil? || self.possible_values.empty?
      errors.add(:possible_values, :invalid) unless self.possible_values.is_a? Array
    end

    # validate default value in every translation available
    required_field = is_required
    is_required = false
    self.translated_locales.each do |locale|
      I18n.with_locale(locale) do
        v = CustomValue.new(:custom_field => self, :value => default_value, :customized => nil)
        errors.add(:default_value, :invalid) unless v.valid?
      end
    end
    is_required = required_field
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
      attribute = globalize.fetch(locale || self.class.locale || I18n.locale, :possible_values)
      attribute
    end
  end

  def possible_values(obj=nil)
    case field_format
    when 'user'
      possible_values_options(obj).collect(&:last)
    else
      globalize.fetch(obj || self.class.locale || I18n.locale, :possible_values)
    end
  end

  # Makes possible_values accept a multiline string
  def possible_values=(arg)
    if arg.is_a?(Array)
      value = arg.compact.collect(&:strip).select {|v| !v.blank?}

      globalize.write(self.class.locale || I18n.locale, :possible_values, value)
      self[:possible_values] = value
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
    case field_format
      when 'string', 'text', 'list', 'date', 'bool'
        # COALESCE is here to make sure that blank and NULL values are sorted equally
        "COALESCE((SELECT cv_sort.value FROM #{CustomValue.table_name} cv_sort" +
          " WHERE cv_sort.customized_type='#{self.class.customized_class.name}'" +
          " AND cv_sort.customized_id=#{self.class.customized_class.table_name}.id" +
          " AND cv_sort.custom_field_id=#{id} LIMIT 1), '')"
      when 'int', 'float'
        # Make the database cast values into numeric
        # Postgresql will raise an error if a value can not be casted!
        # CustomValue validations should ensure that it doesn't occur
        "(SELECT CAST(cv_sort.value AS decimal(60,3)) FROM #{CustomValue.table_name} cv_sort" +
          " WHERE cv_sort.customized_type='#{self.class.customized_class.name}'" +
          " AND cv_sort.customized_id=#{self.class.customized_class.table_name}.id" +
          " AND cv_sort.custom_field_id=#{id} AND cv_sort.value <> '' AND cv_sort.value IS NOT NULL LIMIT 1)"
      else
        nil
    end
  end

  def <=>(field)
    position <=> field.position
  end

  def self.customized_class
    self.name =~ /^(.+)CustomField$/
    begin; $1.constantize; rescue nil; end
  end

  # to move in project_custom_field
  def self.for_all
    find(:all, :conditions => ["is_for_all=?", true], :order => 'position')
  end

  def type_name
    nil
  end
end

# for the sake of nested attributes it is necessary to redefine possible_values
# the values get set directly on the translations association

class CustomField::Translation < ActiveRecord::Base
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

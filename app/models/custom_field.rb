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

module Globalize::ActiveRecord::UniquenessValidation
  def validates_uniqueness_of(*attr_names)
    configuration = { :case_sensitive => true }
    configuration.update(attr_names.extract_options!)

    validates_each(attr_names,configuration) do |record, attr_name, value|
      # The check for an existing value should be run from a class that
      # isn't abstract. This means working down from the current class
      # (self), to the first non-abstract class. Since classes don't know
      # their subclasses, we have to build the hierarchy between self and
      # the record's class.
      class_hierarchy = [record.class]
      while class_hierarchy.first != self
        class_hierarchy.insert(0, class_hierarchy.first.superclass)
      end

      # Now we can work our way down the tree to the first non-abstract
      # class (which has a database table to query from).
      finder_class = class_hierarchy.detect { |klass| !klass.abstract_class? }
      is_translated_attribute = finder_class.translated_attribute_names.include?(attr_name)
      translation_class = finder_class.translation_class if is_translated_attribute

      column = finder_class.columns_hash[attr_name.to_s] || translation_class.columns_hash[attr_name.to_s]

      if value.nil?
        comparison_operator = "IS ?"
      elsif column.text?
        comparison_operator = "#{connection.case_sensitive_equality_operator} ?"
        value = column.limit ? value.to_s.mb_chars[0, column.limit] : value.to_s
      else
        comparison_operator = "= ?"
      end

      sql_attribute = is_translated_attribute ?
        "#{translation_class.quoted_table_name}.#{connection.quote_column_name(attr_name)}" :
        "#{record.class.quoted_table_name}.#{connection.quote_column_name(attr_name)}"

      if value.nil? || (configuration[:case_sensitive] || !column.text?)
        condition_sql = "#{sql_attribute} #{comparison_operator}"
        condition_params = [value]
      else
        condition_sql = "LOWER(#{sql_attribute}) #{comparison_operator}"
        condition_params = [value.mb_chars.downcase]
      end

      if scope = configuration[:scope]
        Array(scope).map do |scope_item|
          scope_value, scope_class = if scope_item == :locale
            [ I18n.locale.to_s,
              record.class.translation_class ]
          elsif record.class.translated_attribute_names.include? scope_item.to_s
            translation = record.translations.detect{ |t| t.locale == I18n.locale }
            value = translation.send(scope_item) if translation.present?

            [ value,
              record.class.translation_class ]
          else
            [ record.send(scope_item),
              record.class ]
          end

          condition_sql << " AND " << attribute_condition("#{scope_class.quoted_table_name}.#{scope_item}", scope_value)
          condition_params << scope_value
        end
      end

      unless record.new_record?
        condition_sql << " AND #{record.class.quoted_table_name}.#{record.class.primary_key} <> ?"
        condition_params << record.send(:id)
      end

      finder_class.with_exclusive_scope do
        if finder_class.first(:conditions => [condition_sql, *condition_params], :include => :translations ).present?
          record.errors.add(attr_name, :taken, :default => configuration[:message], :value => value)
        end
      end
    end
  end
end

class CustomField < ActiveRecord::Base
  has_many :custom_values, :dependent => :delete_all
  acts_as_list :scope => 'type = \'#{self.class}\''
  serialize :possible_values
  translates :name,
             :default_value

  extend Globalize::ActiveRecord::UniquenessValidation
  accepts_nested_attributes_for :translations,
                                :allow_destroy => true,
                                :reject_if =>  proc { |attributes| attributes['locale'].blank? ||
                                                                   (attributes.size == 1 && attributes.has_key?('locale')) }

  def translations_attributes_with_globalized= attr
    ret = self.translations_attributes_without_globalized=(attr)

    # enable globalize to access newly set attributes
    translations.loaded
    # remove previously set translated attributes so that they do not override
    # the ones set here
    globalize.reset

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

    # validate default value
    v = CustomValue.new(:custom_field => self.clone, :value => default_value, :customized => nil)
    v.custom_field.is_required = false
    errors.add(:default_value, :invalid) unless v.valid?
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
      read_attribute :possible_values
    end
  end

  def possible_values(obj=nil)
    case field_format
    when 'user'
      possible_values_options(obj).collect(&:last)
    else
      read_attribute :possible_values
    end
  end

  # Makes possible_values accept a multiline string
  def possible_values=(arg)
    if arg.is_a?(Array)
      write_attribute(:possible_values, arg.compact.collect(&:strip).select {|v| !v.blank?})
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

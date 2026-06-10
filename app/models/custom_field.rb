# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

class CustomField < ApplicationRecord
  include CustomField::OrderStatements
  include CustomField::CalculatedValue

  normalizes :name, with: OpenProject::RemoveInvisibleCharacters

  has_many :custom_values, dependent: :delete_all
  # WARNING: the inverse_of option is also required in order
  # for the 'touch: true' option on the custom_field association in CustomOption
  # to work as desired.
  # Without it, the after_commit callbacks of acts_as_list will prevent the touch to happen.
  # https://github.com/rails/rails/issues/26726
  has_many :custom_options,
           -> { order(position: :asc) },
           dependent: :delete_all,
           inverse_of: "custom_field"
  accepts_nested_attributes_for :custom_options

  has_one :hierarchy_root,
          class_name: "CustomField::Hierarchy::Item",
          dependent: :destroy,
          inverse_of: "custom_field"

  attr_readonly :field_format

  has_many :calculated_value_errors, dependent: :delete_all, inverse_of: "custom_field"
  has_many :comments, class_name: "CustomComment", dependent: :delete_all, inverse_of: "custom_field"

  include Scopes::Scoped

  scope :hierarchy_root_and_children, -> { includes(hierarchy_root: { children: :children }) }
  scope :required, -> { where(is_required: true).where.not(field_format: "calculated_value") }

  scope :field_format_calculated_value, -> { where(field_format: "calculated_value") }

  scopes :visible

  acts_as_list scope: [:type]

  validates :field_format, presence: true
  validates :name,
            presence: true,
            length: { maximum: 256 },
            uniqueness: { case_sensitive: false, scope: :type }

  validate :validate_field_format_inclusion
  validate :validate_default_value
  validate :validate_regex

  validates :min_length, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_length,
            numericality: { less_than_or_equal_to: :max_length, message: :smaller_than_or_equal_to_max_length },
            unless: Proc.new { |cf| cf.max_length.blank? }

  validates :multi_value, absence: true, unless: :multi_value_possible?
  validates :allow_non_open_versions, absence: true, unless: :allow_non_open_versions_possible?
  validates :has_comment, absence: true, unless: :can_have_comment?

  before_validation :check_searchability

  after_destroy :destroy_help_text

  def visible?(usr = User.current, **)
    self.class.visible(usr).exists?(id: id)
  end

  # make sure int, float, date, and bool are not searchable
  def check_searchability
    self.searchable = false if %w(int float date bool user version).include?(field_format)
    true
  end

  def default_value # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    if list?
      # Use loaded association data when available to avoid N+1 queries.
      # .where().pluck() always hits the database, bypassing eager-loaded data.
      ids = if custom_options.loaded?
              custom_options.select(&:default_value).map { |o| o.id.to_s }
            else
              custom_options.where(default_value: true).pluck(:id).map(&:to_s)
            end

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

  def validate_field_format_inclusion
    # When creating a new custom field, only the available formats are allowed.
    # But you can edit and update existing custom fields, even if they have a field format that is disabled.
    allowed = if new_record?
                OpenProject::CustomFieldFormat.available_formats
              else
                OpenProject::CustomFieldFormat.registered_formats
              end

    unless allowed.include?(field_format)
      errors.add(:field_format, :inclusion)
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

  def possible_values_options(obj = nil, options: {})
    case field_format
    when "user"
      possible_user_values_options(obj)
    when "version"
      possible_version_values_options(obj, options:)
    when "list"
      possible_list_values_options
    else
      possible_values
    end
  end

  def value_of(value)
    if list?
      custom_options.where(value:).pick(:id)
    else
      CustomValue.new(custom_field: self, value:).valid? && value
    end
  end

  ##
  # Returns possible values for this custom field.
  # Options may be a customizable, or options suitable for ActiveRecord#read_attribute.
  # Notes: You SHOULD pass a customizable if this CF has a format of user or version.
  #        You MUST NOT pass a customizable if this CF has any other format
  def possible_values(obj = nil)
    case field_format
    when "user"
      possible_users(obj).pluck(:id).map(&:to_s)
    when "version"
      possible_versions(obj).pluck(:id).map(&:to_s)
    when "list"
      custom_options
    when "hierarchy", "weighted_item_list"
      custom_field_hierarchy_items
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
        custom_options.build position: i + 1, value:
      end

      max_position = i + 1
    end

    custom_options.where("position > ?", max_position).destroy_all
  end

  def custom_field_hierarchy_items
    return [] if hierarchy_root.nil?

    items = CustomFields::Hierarchy::HierarchicalItemService
              .new
              .get_descendants(item: hierarchy_root, include_self: false)
              .fmap { |items| items.map { |item| [item.ancestry_path(include_shorts_and_weights: true), item.id] } }

    items.value_or([])
  end

  def cast_value(value)
    return if value.blank?

    case field_format
    when "string", "text", "list", "link"
      value
    when "date"
      begin
        value.to_date
      rescue StandardError
        nil
      end
    when "bool"
      ActiveRecord::Type::Boolean.new.cast(value)
    when "int"
      value.to_i
    when "float", "calculated_value"
      value.to_f
    when "user"
      Principal.find_by(id: value.to_i)
    when "version"
      Version.find_by(id: value.to_i)
    when "hierarchy", "weighted_item_list"
      CustomField::Hierarchy::Item.find_by(id: value.to_i)
    end
  end

  def <=>(other)
    if type == "WorkPackageCustomField"
      name.downcase <=> other.name.downcase
    else
      position <=> other.position
    end
  end

  def self.customized_class
    name =~ /\A(.+)CustomField\z/
    begin
      $1.constantize
    rescue NameError
      nil
    end
  end

  def self.custom_field_attribute?(attribute_name)
    attribute_name.to_s =~ /custom_field_\d+/
  end

  # to move in project_custom_field
  def self.for_all
    where(is_for_all: true)
      .order("#{table_name}.position")
  end

  def self.filter
    where(is_filter: true)
  end

  def all_attribute_names
    if has_comment?
      [attribute_name, comment_attribute_name]
    else
      [attribute_name]
    end
  end

  def attribute_name(format = nil)
    return "customField#{id}" if format == :camel_case
    return "custom-field-#{id}" if format == :kebab_case

    "custom_field_#{id}"
  end

  def comment_attribute_name(format = nil)
    return "customComment#{id}" if format == :camel_case

    "custom_comment_#{id}"
  end

  def attribute_getter = attribute_name.to_sym

  def comment_attribute_getter = comment_attribute_name.to_sym

  def attribute_setter = :"#{attribute_name}="

  def comment_attribute_setter = :"#{comment_attribute_name}="

  def column_name = "cf_#{id}"

  def comment_column_name = "cfc_#{id}"

  def type_name
    nil
  end

  def name_locale
    name
  end

  def list?
    field_format == "list"
  end

  def user?
    field_format == "user"
  end

  def version?
    field_format == "version"
  end

  def formattable?
    field_format == "text"
  end

  def boolean?
    field_format == "bool"
  end

  def field_format_hierarchy?
    field_format == "hierarchy"
  end

  def field_format_weighted_item_list?
    field_format == "weighted_item_list"
  end

  def field_format_calculated_value?
    field_format == "calculated_value"
  end

  def calculated_value? = field_format_calculated_value?

  def hierarchical_list?
    field_format_hierarchy? || field_format_weighted_item_list?
  end

  def multi_value_possible?
    OpenProject::CustomFieldFormat.find_by(name: field_format)&.multi_value_possible?
  end

  def allow_non_open_versions_possible?
    version?
  end

  def self.can_have_comment? = customized_class&.can_have_custom_comments?

  delegate :can_have_comment?, to: :class

  ##
  # Overrides cache key so that a custom field's representation
  # is updated correctly when its multi_value attribute changes.
  def cache_key
    tag = multi_value? ? "mv" : "sv"

    "#{super}/#{tag}"
  end

  # If this custom field is a calculated value, return an existing calculation error.
  # For non-calculated value custom fields, always returns `nil`.
  #
  # When there is at least one calculation error, will return the first one - or `nil` if there are none.
  # Use this method when you want to present a calculation error to the user.
  def first_calculation_error(customized)
    return nil unless calculated_value?

    # Use a ruby finder to avoid hitting the database with N+1 queries on the project list page,
    # the errors are eager loaded via the Queries::Projects::CustomFieldContext.
    calculated_value_errors.find { it.customized == customized }
  end

  def comment_for(customized)
    # Use a ruby finder following same logic as in first_calculation_error
    comments.find { it.customized == customized }
  end

  private

  def possible_versions(obj, options: {})
    project = deduce_project(obj)
    deduce_versions(project, options:)
  end

  def possible_version_values_options(obj, options: {})
    possible_versions(obj, options:)
      .references(:project)
      .sort
      .map { |u| [u.name, u.id.to_s, u.project.name] }
  end

  def possible_users(obj)
    project = deduce_project(obj)
    deduce_principals(project)
  end

  def possible_user_values_options(obj)
    possible_users(obj).select(*user_format_columns, "id", "type")
                       .sort
                       .map { |u| [u.name, u.id.to_s] }
  end

  def possible_list_values_options
    possible_values.map { |option| [option.value, option.id.to_s] }
  end

  def possible_values_from_arg(arg)
    if arg.is_a?(Array)
      arg.compact.map(&:strip).compact_blank
    else
      arg.to_s.split(/[\n\r]+/).map(&:strip).compact_blank
    end
  end

  def deduce_project(candidate)
    if candidate.is_a?(Project)
      candidate
    elsif candidate.respond_to?(:project)
      candidate.project
    end
  end

  def deduce_principals(project)
    if user_field_with_role_assignment?
      Principal.visible
    elsif project&.persisted?
      project.principals
    else
      Principal.in_visible_project_or_me(User.current)
    end
  end

  def user_field_with_role_assignment?
    is_a?(ProjectCustomField) && user? && custom_fields_role.present?
  end

  def deduce_versions(project, options: {})
    if project&.persisted?
      project.shared_versions
    elsif options[:scope] == :visible
      Version.visible
    else
      Version.systemwide
    end
  end

  def user_format_columns
    user_format_columns = User::USER_FORMATS_STRUCTURE[Setting.user_format].map(&:to_s)
    # Always include lastname if not already included, as Groups always need a lastname (alias for name)
    user_format_columns << "lastname" unless user_format_columns.include?("lastname")
    user_format_columns
  end

  def destroy_help_text
    AttributeHelpText
      .where(attribute_name:)
      .destroy_all
  end
end

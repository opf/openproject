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

class Timeline < ActiveRecord::Base
  class Empty
    attr_accessor :id, :name

    def id
      @id ||= -1
    end

    def name
      @name ||= ::I18n.t('timelines.filter.noneElement')
    end
  end

  serialize :options, Hash

  self.table_name = 'timelines'

  default_scope { order('name ASC') }

  belongs_to :project, class_name: 'Project'

  validates_presence_of :name, :project
  validates_length_of :name, maximum: 255, unless: lambda { |e| e.name.blank? }
  validate :validate_option_dates
  validate :validate_option_numeric

  before_save :remove_empty_options_values
  before_save :split_joined_options_values

  @@allowed_option_keys = [
    'custom_fields',
    'columns',
    'compare_to_absolute',
    'compare_to_relative',
    'compare_to_relative_unit',
    'compare_to_historical_one',
    'compare_to_historical_two',
    'comparison',
    'exclude_empty',
    'exclude_own_planning_elements',
    'exclude_reporters',
    'exist',
    'grouping_one_enabled',
    'grouping_one_selection',
    'grouping_one_sort',
    'hide_chart',
    'hide_other_group',
    'initial_outline_expansion',
    'parents',
    'planning_element_responsibles',
    'planning_element_assignee',
    'planning_element_status',
    'planning_element_time',
    'planning_element_time_absolute_one',
    'planning_element_time_absolute_two',
    'planning_element_time_relative_one',
    'planning_element_time_relative_one_unit',
    'planning_element_time_relative_two',
    'planning_element_time_relative_two_unit',
    'planning_element_time_types',
    'planning_element_types',
    'project_responsibles',
    'project_sort',
    'project_status',
    'project_types',
    'timeframe_end',
    'timeframe_start',
    'vertical_planning_elements',
    'zoom_factor'
  ]

  @@available_columns = [
    'start_date',
    'due_date',
    'type',
    'status',
    'responsible',
    'assigned_to'
  ]

  @@available_zoom_factors = [
    'years',
    'quarters',
    'months',
    'weeks',
    'days'
  ]

  @@available_initial_outline_expansions = [
    'aggregation',
    'level1',
    'level2',
    'level3',
    'level4',
    'level5',
    'all'
  ]

  def filter_options
    @@allowed_option_keys
  end

  def validate_option_numeric
    numeric = ['compare_to_relative', 'planning_element_time_relative_one', 'planning_element_time_relative_two']
    numeric.each do |field|
      begin
        if options[field] && options[field] != '' && options[field].to_i.to_s != options[field]
          errors.add :options, l('timelines.filter.errors.' + field) + l('activerecord.errors.messages.not_a_number')
        end
      rescue ArgumentError

      end
    end
  end

  def validate_option_dates
    date_fields = ['timeframe_start', 'timeframe_end', 'compare_to_absolute', 'planning_element_time_absolute_one', 'planning_element_time_absolute_two']
    date_fields.each do |field|
      begin
        if options[field] && options[field] != ''
          Date.parse(options[field])
        end
      rescue ArgumentError
        errors.add :options, l('timelines.filter.errors.' + field) + l('activerecord.errors.messages.not_a_date')
      end
    end
  end

  def default_options
    {}
  end

  def options
    read_attribute(:options) || default_options
  end

  def options=(other)
    other.assert_valid_keys(*filter_options)
    write_attribute(:options, other)
  end

  def json_options
    json = with_escape_html_entities_in_json { options.to_json }
    json.html_safe
  end

  def custom_field_columns
    project.all_work_package_custom_fields.map { |a| { name: a.name, id: "cf_#{a.id}" } }
  end

  def available_columns
    @@available_columns
  end

  def available_initial_outline_expansions
    @@available_initial_outline_expansions
  end

  def selected_initial_outline_expansion
    if options['initial_outline_expansion'].present?
      options['initial_outline_expansion'].first.to_i
    else
      -1
    end
  end

  def available_zoom_factors
    @@available_zoom_factors
  end

  def selected_zoom_factor
    if options['zoom_factor'].present?
      options['zoom_factor'].first.to_i
    else
      -1
    end
  end

  def available_planning_element_types
    # TODO: this should not be all planning element types, but instead
    # all types that are available in the project the timeline is
    # referencing, and all planning element types available in projects
    # that are reporting into the project that this timeline is
    # referencing.

    ::Type.order(:name)
  end

  def available_planning_element_status
    types = Project.visible.includes(:types).map(&:types).flatten.uniq
    types.map(&:statuses).flatten.uniq
  end

  def selected_planning_element_status
    resolve_with_none_element(:planning_element_status) do |ary|
      Status.where(id: ary)
    end
  end

  def selected_planning_element_types
    resolve_with_none_element(:planning_element_types) do |ary|
      ::Type.where(id: ary)
    end
  end

  def selected_planning_element_time_types
    resolve_with_none_element(:planning_element_time_types) do |ary|
      ::Type.where(id: ary)
    end
  end

  def available_project_types
    ProjectType.all
  end

  def selected_project_types
    resolve_with_none_element(:project_types) do |ary|
      ProjectType.where(id: ary)
    end
  end

  def available_project_status
    ReportedProjectStatus.order(:name)
  end

  def selected_project_status
    resolve_with_none_element(:project_status) do |ary|
      ReportedProjectStatus.where(id: ary)
    end
  end

  def available_responsibles
    User.all.sort_by(&:name)
  end

  def selected_project_responsibles
    resolve_with_none_element(:project_responsibles) do |ary|
      User.where(id: ary)
    end
  end

  def selected_planning_element_responsibles
    resolve_with_none_element(:planning_element_responsibles) do |ary|
      User.where(id: ary)
    end
  end

  def custom_field_list_value(field_id)
    value = custom_fields_filter[field_id]
    if value
      value.join(',')
    else
      ''
    end
  end

  def custom_fields_filter
    options['custom_fields'] || {}
  end

  def get_custom_fields
    project.all_work_package_custom_fields.sort_by{ |n| n[:name].downcase }
  end

  def selected_planning_element_assignee
    resolve_with_none_element(:planning_element_assignee) do |ary|
      User.find(ary)
    end
  end

  def available_parents
    selectable_projects
  end

  def selected_parents
    resolve_with_none_element(:parents) do |ary|
      Project.where(id: ary)
    end
  end

  def selected_columns
    if options['columns'].present?
      available = available_columns + custom_field_column_ids

      options['columns'] & available
    else
      []
    end
  end

  def planning_element_time
    if options['planning_element_time'].present?
      options['planning_element_time']
    else
      'absolute'
    end
  end

  def comparison
    if options['comparison'].present?
      options['comparison']
    else
      'none'
    end
  end

  def selected_grouping_projects
    resolve_with_none_element(:grouping_one_selection) do |ary|
      projects = Project.where(id: ary)
      projectsHashMap = Hash[projects.map { |v| [v.id, v] }]

      ary.map { |a| projectsHashMap[a] }
    end
  end

  def available_grouping_projects
    selectable_projects
  end

  def selectable_projects
    Project.selectable_projects
  end

  def available_grouping_project_types
    ProjectType.available_grouping_project_types
  end

  protected

  def remove_empty_options_values
    unless self[:options].nil?
      self[:options].reject! do |_key, value|
        value.instance_of?(Array) && value.length == 1 && value.first.empty?
      end
    end
  end

  def split_joined_options_values
    unless self[:options].nil?
      self[:options].each_pair do |key, value|
        if value.instance_of?(Array) && value.length == 1
          self[:options][key] = value[0].split(',')
        end
      end

      unless self[:options][:custom_fields].nil?
        self[:options][:custom_fields].each_pair do |key, value|
          if value.instance_of?(Array) && value.length == 1
            self[:options][:custom_fields][key] = value[0].split(',')
          end
        end
      end
    end
  end

  def array_of_ids_or_empty_array(options_field)
    array_or_empty(options_field) { |ary| ary.delete_if(&:empty?).map(&:to_i) }
  end

  def array_or_empty(options_field)
    if options[options_field].present?
      if block_given?
        yield options[options_field]
      else
        return options[options_field]
      end
    else
      []
    end
  end

  def resolve_with_none_element(options_field, &block)
    collection = []
    collection += [Empty.new] if (ary = array_of_comma_separated(options_field)).delete(-1)
    begin
      collection += block.call(ary)
    rescue

    end
    collection
  end

  def array_of_comma_separated(options_field)
    array_or_empty(options_field) do |ary|
      ary.map(&:to_i).reject do |value|
        value < -1 || value == 0
      end
    end
  end

  # TODO: this should go somewhere else, once it is needed at multiple places
  def with_escape_html_entities_in_json
    oldvalue = ActiveSupport.escape_html_entities_in_json
    ActiveSupport.escape_html_entities_in_json = true

    yield
  ensure
    ActiveSupport.escape_html_entities_in_json = oldvalue
  end

  def custom_field_column_ids
    custom_field_columns.map { |cf| cf[:id] }
  end
end

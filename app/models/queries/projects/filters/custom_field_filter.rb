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

class Queries::Projects::Filters::CustomFieldFilter <
  Queries::Projects::Filters::ProjectFilter
  attr_accessor :custom_field

  validate :custom_field_valid

  def allowed_values
    case custom_field.field_format
    when 'bool'
      [[I18n.t(:general_text_yes), CustomValue::BoolStrategy::DB_VALUE_TRUE],
       [I18n.t(:general_text_no), CustomValue::BoolStrategy::DB_VALUE_FALSE]]
    when 'user', 'version', 'list'
      custom_field.possible_values_options(project)
    end
  end

  def type
    return nil unless custom_field

    case custom_field.field_format
    when 'int', 'float'
      :integer
    when 'text'
      :text
    when 'list', 'user', 'version'
      :list_optional
    when 'date'
      :date
    when 'bool'
      :list
    else
      :string
    end
  end

  def order
    20
  end

  def name
    # FIXME this can be nil
    :"cf_#{custom_field.id}"
  end

  def human_name
    custom_field ? custom_field.name : ''
  end

  def name=(field_name)
    cf_id = self.class.key.match(field_name)[1]

    self.custom_field = ProjectCustomField.find_by_id(cf_id.to_i)

    super
  end

  def self.key
    /cf_(\d+)/
  end

  def self.all_for(context = nil)

    project = context ? context.project : nil

    custom_fields(project).map do |cf|
      filter = new
      filter.custom_field = cf
      filter.context = context
      filter
    end
  end

  def self.custom_fields(project)
    if project
      project.all_work_package_custom_fields
    else
      ProjectCustomField.all
        # .filter
        # .for_all
        # .where.not(field_format: ['user', 'version'])
    end
  end

  def ar_object_filter?
    %w{user version list}.include? custom_field.field_format
  end

  def available?
    custom_field.present?
  end

  def value_objects
    case custom_field.field_format
    when 'user'
      User.where(id: values)
    when 'version'
      Version.where(id: values)
    when 'list'
      custom_field.custom_options.where(id: values)
    else
      super
    end
  end

  def where
    db_table = CustomValue.table_name
    project_db_table = Project.table_name

    <<-SQL
      #{project_db_table}.id IN
        (SELECT #{project_db_table}.id
         FROM #{project_db_table}
         #{where_joins(db_table, project_db_table)}
         WHERE #{operator_strategy.sql_for_field(values, db_table, 'value')})
    SQL
  end

  def error_messages
    messages = errors
               .full_messages
               .join(" #{I18n.t('support.array.sentence_connector')} ")

    human_name + I18n.t(default: ' %{message}', message: messages)
  end

  private

  def type_strategy
    @type_strategy ||= (strategies[type] || strategies[:inexistent]).new(self)
  end

  def custom_field_valid
    if custom_field.nil?
      errors.add(:base, I18n.t('activerecord.errors.models.query.filters.custom_fields.inexistent'))
    elsif invalid_custom_field_for_context?
      errors.add(:base, I18n.t('activerecord.errors.models.query.filters.custom_fields.invalid'))
    end
  end

  def validate_inclusion_of_operator
    super if custom_field
  end

  def invalid_custom_field_for_context?
    try(:project) && invalid_custom_field_for_project? ||
      try(:project) && invalid_custom_field_globally?
  end

  def invalid_custom_field_globally?
    !self.class.custom_fields(project)
         .exists?(custom_field.id)
  end

  def invalid_custom_field_for_project?
    !self.class.custom_fields(project)
         .map(&:id).include? custom_field.id
  end

  def strategies
    strategies = Queries::Filters::STRATEGIES.dup
    strategies[:list_optional] = Queries::Filters::Strategies::CfListOptional
    strategies[:integer] = Queries::Filters::Strategies::CfInteger
    # knowing that only bool have list type
    strategies[:list] = Queries::Filters::Strategies::BooleanList

    strategies
  end

  def where_joins(db_table, project_db_table)
    cf_types_db_table = 'custom_fields_types'
    cf_projects_db_table = 'custom_fields_projects'

    joins = "LEFT OUTER JOIN #{db_table}
               ON #{db_table}.customized_type='Project'
               AND #{db_table}.customized_id=#{project_db_table}.id
               AND #{db_table}.custom_field_id=#{custom_field.id}"

    joins
  end
end

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

module Api::Experimental::Concerns::ColumnData
  def get_columns_for_json(columns)
    columns.map do |column|
      { name: column.name,
        title: column.caption,
        sortable: column.sortable?,
        groupable: column.groupable?,
        custom_field: column.is_a?(QueryCustomFieldColumn) &&
          column.custom_field.as_json(only: [:id, :field_format]),
        meta_data: get_column_meta(column)
      }
    end
  end

  private

  def get_column_meta(column)
    # This is where we want to add column specific behaviour to instruct the
    # front end how to deal with it. Needs to be things like user link, project
    # link, datetime
    {
      data_type: column_data_type(column),
      link: link_meta(column)
    }
  end

  def link_meta(column)
    link_meta = static_link_meta[column.name]

    if link_meta
      link_meta
    elsif column.respond_to?(:custom_field)
      linked_custom_field_meta(column)
    else
      { display: false }
    end
  end

  def static_link_meta
    {
      id: { display: true, model_type: 'work_package' },
      subject: { display: true, model_type: 'work_package' },
      type: { display: false },
      status: { display: false },
      priority: { display: false },
      parent: { display: true, model_type: 'work_package' },
      assigned_to: { display: true, model_type: 'user' },
      responsible: { display: true, model_type: 'user' },
      author: { display: true, model_type: 'user' },
      project: { display: true, model_type: 'project' }
    }
  end

  def linked_custom_field_meta(column)
    case column.custom_field.field_format
    when 'user', 'version'
      { display: true, model_type: column.custom_field.field_format }
    else
      { display: false }
    end
  end

  def column_data_type(column)
    if column.is_a?(QueryCustomFieldColumn)
      column.custom_field.field_format
    elsif column.class.to_s =~ /CurrencyQueryColumn/
      'currency'
    elsif c = WorkPackage.columns_hash[column.name.to_s]
      c.type.to_s
    elsif WorkPackage.columns_hash[column.name.to_s + '_id']
      'object'
    else
      'default'
    end
  end

  def valid_columns(columns)
    column_names, custom_field_ids = separate_columns_by_custom_fields(columns)

    valid_column_names = Query.available_columns.map { |c| c.name.to_s } & column_names

    existing_cf_ids = existing_custom_field_ids(custom_field_ids)

    valid_cf_column_names = columns.select do |name|
      id = custom_field_id_in(name)
      existing_cf_ids.include?(id)
    end

    # keep order of provided columns
    columns & (valid_column_names + valid_cf_column_names)
  end

  def separate_columns_by_custom_fields(columns)
    cf_columns, non_cf_columns = columns.partition { |name| custom_field_id_in(name) }

    cf_columns_id = cf_columns.map { |name| custom_field_id_in(name) }

    [non_cf_columns, cf_columns_id]
  end

  def existing_custom_field_ids(ids)
    if ids.empty?
      []
    else
      WorkPackageCustomField.where(id: ids).pluck(:id).map(&:to_s)
    end
  end

  def columns_total_sums(column_names, work_packages)
    column_names.map do |column_name|
      column_sum(column_name, work_packages)
    end
  end

  def column_sum(column_name, work_packages)
    if column_should_be_summed_up?(column_name)
      column_data = fetch_column_data(column_name, work_packages, false)

      column_data.map { |c| c.nil? ? 0 : c }
        .compact
        .sum
    end
  end

  def columns_group_sums(column_names, work_packages, group_by)
    # NOTE RS: This is basically the grouped_sums method from sums.rb but we
    # have no query to play with here
    return unless group_by

    if custom_field_id_in(group_by)
      sum_columns(column_names, work_packages) do |wp|
        wp.custom_values.detect { |cv| cv.custom_field_id == custom_field_id_in(group_by).to_i }
      end
    else
      sum_columns(column_names, work_packages) do |wp|
        wp.send(group_by)
      end
    end
  end

  def sum_columns(column_names, work_packages)
    column_names.map do |column_name|
      work_packages.map { |wp| yield wp }
        .uniq
        .inject({}) do |group_sums, current_group|
          work_packages_in_current_group = work_packages.select do |wp|
            (yield wp) == current_group
          end

          group_sums.merge current_group => column_sum(column_name, work_packages_in_current_group)
        end
    end
  end

  def includes_for_columns(column_names)
    column_names = Array(column_names)
    includes = (WorkPackage.reflections.keys & column_names.map(&:to_sym))

    if column_names.any? { |c| custom_field_id_in(c) }
      includes << { custom_values: :custom_field }
    end

    includes
  end

  def fetch_columns_data(column_names, work_packages)
    column_names, custom_field_column_ids = separate_columns_by_custom_fields(column_names)

    columns = column_names.map do |column_name|
      fetch_non_custom_field_column_data(column_name, work_packages)
    end

    columns += custom_field_column_ids.map do |cf_id|
      fetch_custom_field_column_data(cf_id, work_packages)
    end

    columns
  end

  def fetch_column_data(column_name, work_packages, display = true)
    if custom_field_id = custom_field_id_in(column_name)
      fetch_custom_field_column_data(custom_field_id, work_packages, display)
    else
      fetch_non_custom_field_column_data(column_name, work_packages)
    end
  end

  def fetch_custom_field_column_data(custom_field_id, work_packages, display = true)
    custom_field_data = work_packages.map do |wp|
      wp.custom_values_display_data(custom_field_id)
    end

    if display
      custom_field_data.flatten
    else
      custom_field_data.flatten.map { |d| d.nil? ? nil : d[:value] }
    end
  end

  def fetch_non_custom_field_column_data(column_name, work_packages)
    work_packages.map do |work_package|
      # Note: Doing as_json here because if we just take the
      # value.attributes then we can't get any methods later.  Name and
      # subject are the default properties that the front end currently
      # looks for to summarize an object.
      value = work_package.send(column_name)

      if value.is_a?(ActiveRecord::Base)
        value.as_json(only: 'id', methods: [:name, :subject])
      else
        value
      end
    end
  end

  def column_should_be_summed_up?(column_name)
    # see ::Query::Sums mix in
    column_is_numeric?(column_name) &&
      Setting.work_package_list_summable_columns.include?(column_name.to_s)
  end

  def column_is_numeric?(column_name)
    # TODO RS: We want to leave out ids even though they are numeric
    [:int, :integer, :float].include? column_type(column_name)
  end

  def custom_field_id_in(name)
    groups = name.to_s.scan(/cf_(\d+)/).flatten

    if groups
      groups[0]
    else
      nil
    end
  end

  def column_type(column_name)
    if id = custom_field_id_in(column_name)
      CustomField.find(id).field_format.to_sym
    else
      column = WorkPackage.columns_hash[column_name]
      column.nil? ? :none : column.type
    end
  end
end

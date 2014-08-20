#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
        sortable: column.sortable,
        groupable: column.groupable,
        custom_field: column.is_a?(QueryCustomFieldColumn) &&
                      column.custom_field.as_json(only: [:id, :field_format]),
        meta_data: get_column_meta(column)
      }
    end
  end

  private

  def get_column_meta(column)
    # This is where we want to add column specific behaviour to instruct the front end how to deal with it
    # Needs to be things like user link,project link, datetime
    {
      data_type: column_data_type(column),
      link: !!(link_meta()[column.name]) ? link_meta()[column.name] : { display: false }
    }
  end

  def link_meta
    {
      subject: { display: true, model_type: "work_package" },
      type: { display: false },
      status: { display: false },
      priority: { display: false },
      parent: { display: true, model_type: "work_package" },
      assigned_to: { display: true, model_type: "user" },
      responsible: { display: true, model_type: "user" },
      author: { display: true, model_type: "user" },
      project: { display: true, model_type: "project" }
    }
  end

  def column_data_type(column)
    if column.is_a?(QueryCustomFieldColumn)
      return column.custom_field.field_format
    elsif column.class.to_s =~ /CurrencyQueryColumn/
      return 'currency'
    elsif (c = WorkPackage.columns_hash[column.name.to_s] and !c.nil?)
      return c.type.to_s
    elsif (c = WorkPackage.columns_hash[column.name.to_s + "_id"] and !c.nil?)
      return "object"
    else
      return "default"
    end
  end
end

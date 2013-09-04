#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackageCustomField < CustomField
  has_and_belongs_to_many :projects, :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}", :foreign_key => "custom_field_id"
  has_and_belongs_to_many :types, :join_table => "#{table_name_prefix}custom_fields_types#{table_name_suffix}", :foreign_key => "custom_field_id"
  has_many :work_packages, :through => :work_package_custom_values

  def type_name
    # TODO
    # this needs to be renamed to label_work_package_plural
    :label_work_package_plural
  end
end


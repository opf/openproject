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

class IssuePriority < Enumeration
  has_many :work_packages, :foreign_key => 'priority_id'

  OptionName = :enumeration_work_package_priorities

  def option_name
    OptionName
  end

  def objects_count
    work_packages.count
  end

  def transfer_relations(to)
    work_packages.update_all("priority_id = #{to.id}")
  end
end

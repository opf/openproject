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

class IssuePriority < Enumeration
  has_many :issues, :foreign_key => 'priority_id'

  OptionName = :enumeration_issue_priorities

  def option_name
    OptionName
  end

  def objects_count
    issues.count
  end

  def transfer_relations(to)
    issues.update_all("priority_id = #{to.id}")
  end
end

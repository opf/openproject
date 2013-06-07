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

module IssueRelationsHelper
  def collection_for_relation_type_select
    values = IssueRelation::TYPES
    values.keys.sort{|x,y| values[x][:order] <=> values[y][:order]}.collect{|k| [l(values[k][:name]), k]}
  end
end

#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class QueryCustomFieldColumn < QueryColumn

  def initialize(custom_field)
    self.name = "cf_#{custom_field.id}".to_sym
    self.sortable = custom_field.order_statement || false
    if %w(list date bool int).include?(custom_field.field_format)
      self.groupable = custom_field.order_statement
    end
    self.groupable ||= false
    @cf = custom_field
  end

  def caption
    @cf.name
  end

  def custom_field
    @cf
  end

  def value(issue)
    cv = issue.custom_values.detect {|v| v.custom_field_id == @cf.id}
    cv && @cf.cast_value(cv.value)
  end
end


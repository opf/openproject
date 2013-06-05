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

#-- encoding: UTF-8
class JournalDetail
  attr_reader :prop_key, :value, :old_value

  def initialize(prop_key, old_value, value)
    @prop_key = prop_key
    @old_value = old_value
    @value = value
  end
end

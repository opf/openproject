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

module TimestampsCompatibility
  def updated_on
    self.updated_at
  end

  def updated_on=(other)
    self.updated_at = other
  end

  def created_on
    self.created_at
  end

  def created_on=(other)
    self.created_at = other
  end
end

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

class ActiveRecord::Base
  # call this to force mass assignment even of protected attributes
  def force_attributes=(new_attributes)
    self.send(:assign_attributes, new_attributes, :without_protection => true)
  end
end

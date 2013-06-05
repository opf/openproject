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

class JournalFormatter::Fraction < JournalFormatter::Attribute
  # unloadable

  def format_values(values)
    values.map do |v|
      v.nil? ?
        nil :
        "%0.02f" % v.to_f
    end
  end
end

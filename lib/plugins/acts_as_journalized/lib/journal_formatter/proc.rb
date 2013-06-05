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

class JournalFormatter::Proc < JournalFormatter::Attribute
  # unloadable

  class << self
    attr_accessor :proc
  end

  private

  def format_details(key, values)
    label = label(key)

    old_value, value = *format_values(values, key)

    [label, old_value, value]
  end

  def format_values(values, key)
    field = key.to_s.gsub(/\_id$/, "")

    values.map do |value|
      self.class.proc.call value, @journal.journaled, field
    end
  end
end

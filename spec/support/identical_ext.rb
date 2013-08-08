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

Journal.class_eval do
  def identical?(o)
    return false unless self.class === o

    original = self.attributes
    recreated = o.attributes

    original.except!("created_at")
    self.changed_data.except!("created_on")
    recreated.except!("created_at")
    o.changed_data.except!("created_on")

    original.identical?(recreated)
  end
end

Hash.class_eval do
  def identical?(o)
    return false unless self.class === o
    (o.keys + keys).uniq.all? do |key|
      (o[key].identical?(self[key]))
    end
  end
end

Array.class_eval do
  def identical?(o)
    return false unless self.class === o
    all? do |ea|
      (o.any? {|other_each| other_each.identical?(ea) })
    end
  end
end

Object.class_eval do
  def identical?(o)
    self == o
  end
end

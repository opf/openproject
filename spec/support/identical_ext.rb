#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Journal.class_eval do
  def identical?(o)
    return false unless self.class === o

    original = attributes
    recreated = o.attributes

    original.except!('created_at')
    changed_data.except!('created_on')
    recreated.except!('created_at')
    o.changed_data.except!('created_on')

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
      (o.any? { |other_each| other_each.identical?(ea) })
    end
  end
end

Object.class_eval do
  def identical?(o)
    self == o
  end
end

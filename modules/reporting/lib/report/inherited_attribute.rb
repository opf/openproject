#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Report::InheritedAttribute
  include Report::QueryUtils

  def inherited_attribute(*attributes)
    options = attributes.extract_options!
    list    = options[:list]
    merge   = options.include?(:merge) ? options[:merge] : options[:list]
    default = options[:default]
    uniq    = options[:uniq]
    map     = options[:map] || proc { |e| e }
    default ||= [] if list
    attributes.each do |name|
      define_singleton_method(name) do |*values|
        # FIXME: I'm ugly
        return get_inherited_attribute(name, default, list, uniq) if values.empty?

        if list
          old = instance_variable_get(:"@#{name}") if merge
          old ||= []
          return set_inherited_attribute(name, values.map(&map) + old)
        end
        raise ArgumentError, "wrong number of arguments (#{values.size} for 1)" if values.size > 1

        set_inherited_attribute name, map.call(values.first)
      end
      define_method(name) { |*values| self.class.send(name, *values) }
    end
  end

  def define_singleton_method(name, &)
    singleton_class.send :attr_writer, name
    singleton_class.class_eval { define_method(name, &) }
    define_method(name) { instance_variable_get(:"@#{name}") or singleton_class.send(name) }
  end

  def get_inherited_attribute(name, default = nil, list = false, uniq = false)
    return get_inherited_attribute(name, default, list, false).uniq if list and uniq

    result = instance_variable_get(:"@#{name}")
    super_result = superclass.get_inherited_attribute(name, default, list) if inherit? name
    if result.nil?
      super_result || default
    else
      list && super_result ? result + super_result : result
    end
  end

  def inherit?(name)
    superclass.respond_to? :get_inherited_attribute and not not_inherited.include? name
  end

  def not_inherited
    @not_inherited ||= Set.new
  end

  def dont_inherit(*attributes)
    not_inherited.merge attributes
  end

  def set_inherited_attribute(name, value)
    instance_variable_set :"@#{name}", value
  end
end

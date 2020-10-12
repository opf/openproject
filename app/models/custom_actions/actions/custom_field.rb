#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CustomActions::Actions::CustomField < CustomActions::Actions::Base
  def self.key
    :"custom_field_#{custom_field.id}"
  end

  def self.custom_field
    raise NotImplementedError
  end

  def custom_field
    self.class.custom_field
  end

  def human_name
    custom_field.name
  end

  def apply(work_package)
    work_package.send(:"#{custom_field.accessor_name}=", values) if work_package.respond_to?(:"#{custom_field.accessor_name}=")
  end

  def self.all
    WorkPackageCustomField
      .order(:name)
      .map do |cf|
        create_subclass(cf)
      end
  end

  def self.for(key)
    match_result = key.match /custom_field_(\d+)/

    if match_result && (cf = WorkPackageCustomField.find_by(id: match_result[1]))
      create_subclass(cf)
    end
  end

  def self.create_subclass(custom_field)
    klass = Class.new(CustomActions::Actions::CustomField)
    klass.define_singleton_method(:custom_field) do
      custom_field
    end

    klass.include(strategy(custom_field))
    klass
  end
  private_class_method :create_subclass

  def self.strategy(custom_field)
    case custom_field.field_format
    when 'string'
      CustomActions::Actions::Strategies::String
    when 'text'
      CustomActions::Actions::Strategies::Text
    when 'int'
      CustomActions::Actions::Strategies::Integer
    when 'float'
      CustomActions::Actions::Strategies::Float
    when 'date'
      CustomActions::Actions::Strategies::Date
    when 'bool'
      CustomActions::Actions::Strategies::Boolean
    when 'list', 'version', 'user'
      CustomActions::Actions::Strategies::AssociatedCustomField
    end
  end

  private_class_method :strategy
end

#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Queries::AvailableFilters
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def registered_filters
      Queries::Register.filters[self]
    end

    def find_registered_filter(key)
      registered_filters.detect do |f|
        f.key === key.to_sym
      end
    end
  end

  def available_filters
    uninitialized = registered_filters - already_initialized_filters

    uninitialized.each do |filter|
      initialize_filter(filter)
    end

    initialized_filters.select(&:available?)
  end

  def filter_for(key, no_memoization = false)
    filter_instance = get_initialized_filter(key, no_memoization) || Queries::NotExistingFilter.new
    filter_instance.name = key

    filter_instance
  end

  private

  def get_initialized_filter(key, no_memoization)
    filter = find_registered_filter(key)

    return unless filter

    if no_memoization
      filter.new
    else
      initialize_filter(filter)

      find_initialized_filter(key)
    end
  end

  def initialize_filter(filter)
    return if already_initialized_filters.include?(filter)
    already_initialized_filters << filter

    new_filters = filter.all_for(context)

    initialized_filters.push(*Array(new_filters))
  end

  def find_registered_filter(key)
    self.class.find_registered_filter(key)
  end

  def find_initialized_filter(key)
    initialized_filters.detect do |f|
      f.name == key.to_sym
    end
  end

  def already_initialized_filters
    @already_initialized_filters ||= []
  end

  def initialized_filters
    @initialized_filters ||= []
  end

  def registered_filters
    self.class.registered_filters
  end
end

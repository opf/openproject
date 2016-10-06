#-- encoding: UTF-8
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

module Queries::WorkPackages::AvailableFilterOptions
  def available_work_package_filters
    uninitialized = registered_work_package_filters - already_initialized_work_package_filters

    uninitialized.each do |filter|
      initialize_work_package_filter(filter)
    end

    initialized_available_work_package_filters
  end

  def work_package_filter_available?(key)
    filter = find_registered_filter(key)

    return unless filter

    initialize_work_package_filter(filter)

    initialized_available_work_package_filters[key]
  end

  private

  def initialize_work_package_filter(filter)
    return if already_initialized_work_package_filters.include?(filter)
    already_initialized_work_package_filters << filter

    new_filters = filter.create(project)

    available_filters = new_filters.reject { |_, f| !f.available? }

    initialized_available_work_package_filters.merge! available_filters
  end

  def find_registered_filter(key)
    registered_work_package_filters.detect do |f|
      f.key === key.to_sym
    end
  end

  def already_initialized_work_package_filters
    @already_initialized_work_package_filters ||= []
  end

  def registered_work_package_filters
    @registered_work_package_filters ||= filter_register.filters
  end

  def initialized_available_work_package_filters
    @initialized_available_work_package_filters ||= {}.with_indifferent_access
  end

  def filter_register
    Queries::WorkPackages::FilterRegister
  end
end

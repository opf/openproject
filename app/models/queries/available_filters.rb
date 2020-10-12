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

require_dependency 'queries/filters'

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
    filter = get_initialized_filter(key, no_memoization)

    raise ::Queries::Filters::MissingError if filter.nil?

    filter
  rescue ::Queries::Filters::InvalidError => e
    Rails.logger.error "Failed to register filter for #{key}: #{e} \n" \
                       "Falling back to non-existing filter."
    non_existing_filter(key)
  rescue ::Queries::Filters::MissingError => e
    Rails.logger.error "Failed to find filter for #{key}: #{e} \n" \
                       "Falling back to non-existing filter."
    non_existing_filter(key)
  end

  private

  def non_existing_filter(key)
    Queries::NotExistingFilter.create!(name: key)
  end

  def get_initialized_filter(key, no_memoization)
    filter = find_registered_filter(key)

    return unless filter

    if no_memoization
      filter.create!(name: key)
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

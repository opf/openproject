#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Queries::WorkPackages::Filter::OrFilterForWpMixin
  extend ActiveSupport::Concern

  included do
    validate :minimum_one_filter_valid
  end

  def filters
    if @filters
      update_instances
    else
      @filters = create_instances
    end

    @filters.keep_if(&:validate)
  end

  def where
    filters.map(&:where).join(' OR ')
  end

  def filter_configurations
    raise NotImplementedError
  end

  def create_instances
    filter_configurations.map do |conf|
      conf.filter_class.create!(name: conf.filter_name,
                                context:,
                                operator: conf.operator,
                                values:)
    end
  end

  def update_instances
    configurations = filter_configurations

    @filters.each_with_index do |filter, index|
      filter.operator = configurations[index].operator
      filter.values = values
    end
  end

  def ar_object_filter?
    false
  end

  def minimum_one_filter_valid
    if filters.empty?
      errors.add(:values, :invalid)
    end
  end
end

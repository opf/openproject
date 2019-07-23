#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class Queries::WorkPackages::Columns::WorkPackageColumn < Queries::Columns::Base
  attr_accessor :highlightable
  alias_method :highlightable?, :highlightable

  def initialize(name, options = {})
    super(name, options)
    self.highlightable = !!options.fetch(:highlightable, false)
  end

  def caption
    WorkPackage.human_attribute_name(name)
  end

  def sum_of(work_packages)
    wps = filter_for_sum work_packages

    if wps.is_a?(Array)
      # TODO: Sums::grouped_sums might call through here without an AR::Relation
      # Ensure that this also calls using a Relation and drop this (slow!) implementation
      wps.map { |wp| value(wp) }.compact.reduce(:+)
    else
      wps.sum(name)
    end
  end

  ##
  # Sometimes we don't want to consider all work packages when calculating
  # the sum for a certain column.
  #
  # Specifically we don't want to consider child work packages when summing up
  # the estimated hours for work packages since the estimated hours of
  # parent work packages already include those of their children.
  #
  # Right now we cover only this one case here explicilty.
  # As soon as there are more cases to be considered this shall be
  # refactored into something more generic and outside of this class.
  def filter_for_sum(work_packages)
    if name == :estimated_hours
      filter_for_sum_of_estimated_hours work_packages
    else
      work_packages
    end
  end

  def filter_for_sum_of_estimated_hours(work_packages)
    # Why an array? See TODO above in #sum_of.
    if work_packages.is_a? Array
      work_packages.reject { |wp| !wp.children.empty? && work_packages.any? { |x| x.parent_id == wp.id } }
    else
      # @TODO Replace with CTE once we dropped MySQL support (MySQL only supports CTEs from version 8 onwards).
      #       With a CTE (common table expression) we only need to query the work packages once and can then
      #       drill the results down to the desired subset. Right now we run the work packages query a second
      #       time in a sub query.
      work_packages.without_children in: work_packages
    end
  end
end

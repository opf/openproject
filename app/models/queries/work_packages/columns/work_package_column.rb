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
    if work_packages.is_a?(Array)
      # TODO: Sums::grouped_sums might call through here without an AR::Relation
      # Ensure that this also calls using a Relation and drop this (slow!) implementation
      work_packages.map { |wp| value(wp) }.compact.reduce(:+)
    else
      work_packages.sum(name)
    end
  end
end

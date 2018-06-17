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

class Queries::WorkPackages::Filter::BlockedByPredecessorsFilter <
    Queries::WorkPackages::Filter::WorkPackageFilter

  def allowed_values
    [
      [I18n.t(:general_text_yes), OpenProject::Database::DB_VALUE_TRUE],
      [I18n.t(:general_text_no), OpenProject::Database::DB_VALUE_FALSE]
    ]
  end

  def type
    :boolean
  end

  def order
    2
  end

  def available?
    true
  end

  def ar_object_filter?
    false
  end

  def self.key
    :blocked_by_predecessors
  end

  def type_strategy
    @type_strategy ||= ::Queries::Filters::Strategies::BooleanList.new(self)
  end
end

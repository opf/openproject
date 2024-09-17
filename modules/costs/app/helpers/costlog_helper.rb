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

module CostlogHelper
  def cost_types_collection_for_select_options(selected_type = nil)
    cost_types = CostType.active.sort

    if selected_type && !cost_types.include?(selected_type)
      cost_types << selected_type
      cost_types.sort
    end
    cost_types.map { |t| [t.name, t.id] }
  end

  def user_collection_for_select_options(_options = {})
    Principal
      .possible_assignee(@project)
      .where(type: "User")
      .map { |t| [t.name, t.id] }
  end

  def extended_progress_bar(pcts, options = {})
    return progress_bar(pcts, options) unless pcts.is_a?(Numeric) && pcts > 100

    closed = ((100.0 / pcts) * 100).round
    done = 100.0 - ((100.0 / pcts) * 100).round
    progress_bar([closed, done], options)
  end
end

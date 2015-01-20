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

module VersionsHelper
  include WorkPackagesFilterHelper

  STATUS_BY_CRITERIAS = %w(category type status priority author assigned_to)

  def render_status_by(version, criteria)
    criteria = 'category' unless STATUS_BY_CRITERIAS.include?(criteria)

    h = Hash.new { |k, v| k[v] = [0, 0] }
    begin
      # Total issue count
      WorkPackage.count(group: criteria,
                        conditions: ["#{WorkPackage.table_name}.fixed_version_id = ?", version.id]).each { |c, s| h[c][0] = s }
      # Open issues count
      WorkPackage.count(group: criteria,
                        include: :status,
                        conditions: ["#{WorkPackage.table_name}.fixed_version_id = ? AND #{Status.table_name}.is_closed = ?", version.id, false]).each { |c, s| h[c][1] = s }
    rescue ActiveRecord::RecordNotFound
      # When grouping by an association, Rails throws this exception if there's no result (bug)
    end
    counts = h.keys.compact.sort.map { |k| { group: k, total: h[k][0], open: h[k][1], closed: (h[k][0] - h[k][1]) } }
    max = counts.map { |c| c[:total] }.max

    render partial: 'work_package_counts', locals: { version: version, criteria: criteria, counts: counts, max: max }
  end

  def status_by_options_for_select(value)
    options_for_select(STATUS_BY_CRITERIAS.map { |criteria| [WorkPackage.human_attribute_name(criteria.to_sym), criteria] }, value)
  end
end

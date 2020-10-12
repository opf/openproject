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

class CostQuery::Filter::PermissionFilter < Report::Filter::Base
  dont_display!
  not_selectable!
  db_field ''
  singleton

  initialize_query_with { |query| query.filter to_s.demodulize.to_sym }

  def permission_statement(permission)
    User.current.allowed_to_condition_with_project_id(permission).gsub(/(user|project)s?\.id/, '\1_id')
  end

  def permission_for(type)
    "((#{permission_statement :"view_own_#{type}_entries"} AND user_id = #{User.current.id}) " \
    "OR #{permission_statement :"view_#{type}_entries"})"
  end

  def display_costs
    "(#{permission_statement :view_hourly_rates} " \
    "AND #{permission_statement :view_cost_rates}) " \
    'OR ' \
    "(#{permission_statement :view_own_hourly_rate} " \
    "AND type = 'TimeEntry' AND user_id = #{User.current.id}) " \
    'OR ' \
    "(#{permission_statement :view_cost_rates} " \
    "AND type = 'CostEntry' AND user_id = #{User.current.id})"
  end

  def sql_statement
    super.tap do |query|
      query.from.each_subselect do |sub|
        sub.where permission_for(sub == query.from.first ? 'time' : 'cost')
        sub.select.delete_if { |f| f.end_with? 'display_costs' }
        sub.select display_costs: switch(display_costs => '1', else: 0)
      end
    end
  end
end

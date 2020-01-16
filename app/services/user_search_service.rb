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

class UserSearchService
  attr_accessor :params
  attr_reader :users_only, :project

  SEARCH_SCOPES = [
    'project_id',
    'ids',
    'group_id',
    'status',
    'name'
  ]

  def initialize(params, users_only: false)
    self.params = params

    @users_only = users_only
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def scope
    if users_only
      project.nil? ? User : project.users
    else
      project.nil? ? Principal : project.principals
    end
  end

  def search
    params[:ids].present? ? ids_search(scope) : query_search(scope)
  end

  def ids_search(scope)
    ids = params[:ids].split(',')

    scope.not_builtin.where(id: ids)
  end

  def query_search(scope)
    scope = scope.in_group(params[:group_id].to_i) if params[:group_id].present?
    c = ARCondition.new

    if params[:status] == 'blocked'
      @status = :blocked
      scope = scope.blocked
    elsif params[:status] == 'all'
      @status = :all
      scope = scope.not_builtin
    else
      @status = params[:status] ? params[:status].to_i : User::STATUSES[:active]
      scope = scope.not_blocked if users_only && @status == User::STATUSES[:active]
      c << ['status = ?', @status]
    end

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ['LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?', name, name, name, name]
    end

    scope.where(c.conditions)
    # currently, the sort/paging-helpers are highly dependent on being included in a controller
    # and having access to things like the session or the params: this makes it harder
    # to test outside a controller and especially hard to re-use this functionality
    # .page(page_param)
    # .per_page(per_page_param)
    # .order(sort_clause)
  end
end

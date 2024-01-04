#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class UserFilterComponent < IndividualPrincipalBaseFilterComponent
  options :groups, :status, :roles, :clear_url, :project

  class << self
    ##
    # Returns the selected status from the parameters
    # or the default status to be filtered by (all)
    # if no status is given.
    def status_param(params)
      params[:status].presence || 'all'
    end

    def filter_status(query, status)
      return unless status && status != 'all'

      case status
      when 'blocked'
        query.where(:blocked, '=', :blocked)
      when 'active'
        query.where(:status, '=', status.to_sym)
        query.where(:blocked, '!', :blocked)
      else
        query.where(:status, '=', status.to_sym)
      end
    end

    def base_query
      Queries::Users::UserQuery
    end

    protected

    def apply_filters(params, query)
      super(params, query)
      filter_status query, status_param(params)

      query
    end
  end

  # INSTANCE METHODS:

  def filter_path
    users_path
  end

  def user_status_options
    helpers.users_status_options_for_select status, extra: extra_user_status_options
  end

  def extra_user_status_options
    {}
  end
end

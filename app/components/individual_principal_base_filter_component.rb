# frozen_string_literal: true

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

class IndividualPrincipalBaseFilterComponent < ApplicationComponent
  class << self
    def query(params)
      q = base_query.new

      apply_filters(params, q)

      q
    end

    def filter(params)
      query(params).results
    end

    def filter_param_keys
      %i(name status group_id role_id)
    end

    def filtered?(params)
      filter_param_keys.any? { |name| params[name].present? }
    end

    def filter_name(query, name)
      if name.present?
        query.where(:any_name_attribute, "~", name)
      end
    end

    def filter_group(query, group_id)
      if group_id.present?
        query.where(:group, "=", group_id)
      end
    end

    def filter_role(query, role_id)
      if role_id.present?
        query.where(:role_id, "=", role_id)
      end
    end

    def filter_project(query, project_id)
      if project_id.present?
        query.where(:project_id, "=", project_id)
      end
    end

    def base_query
      raise NotImplementedError
    end

    protected

    def apply_filters(params, query)
      filter_project query, params[:project_id]
      filter_name query, params[:name]
      filter_group query, params[:group_id]
      filter_role query, params[:role_id]

      query
    end
  end

  # INSTANCE METHODS:

  def filter_path
    raise NotImplementedError
  end

  def initially_visible?
    true
  end

  def has_close_icon?
    false
  end

  def has_statuses?
    defined?(status)
  end

  def has_groups?
    defined?(groups) && groups.present?
  end

  def has_shares?
    false
  end

  def params
    model
  end
end

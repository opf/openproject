# frozen_string_literal: true

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

module Members
  class TableComponent < ::TableComponent
    options :authorize_update, :available_roles, :is_filtered, :project
    columns :name, :mail, :roles, :groups, :shared, :status
    sortable_columns :name, :mail, :status

    def apply_sort(model)
      apply_member_scopes super(model)
    end

    def apply_member_scopes(model)
      model
        .with_shared_work_packages_count(only_role_id:)
        # This additional select is necessary for removing "duplicate" memberships in the members table
        # In reality, we want to show distinct principals in the members page, but are filtering on the members
        # table which now has multiplpe entries per user if they are the recipient of multiple shares,
        # or are a project member on top of that.
        .where(id: subselected_member_ids(model))
    end

    def subselected_member_ids(model)
      Member
        .where(
          id: model
            .reselect('DISTINCT ON (members.user_id) members.id')
            .reorder('members.user_id, members.entity_type NULLS FIRST')
        )
    end

    def only_role_id
      case params[:shared_role_id]
      when 'all', nil
        nil
      else
        params[:shared_role_id]
      end
    end

    def initial_sort
      %i[name asc]
    end

    def headers
      columns.map do |name|
        [name.to_s, header_options(name)]
      end
    end

    def header_options(name)
      caption =
        case name
        when :shared
          I18n.t('members.columns.shared')
        else
          User.human_attribute_name(name)
        end

      { caption: }
    end

    ##
    # Adjusts the order so that users are joined to support
    # sorting by their attributes
    def sort_collection(query, sort_clause, sort_columns)
      super(join_users(query), sort_clause, sort_columns)
    end

    def join_users(query)
      query.joins(:principal)
    end

    def empty_row_message
      if is_filtered
        I18n.t :notice_no_principals_found
      else
        I18n.t :'members.index.no_results_title_text'
      end
    end
  end
end

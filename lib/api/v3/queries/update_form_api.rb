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

require 'api/v3/queries/query_representer'

module API
  module V3
    module Queries
      class UpdateFormAPI < ::API::OpenProjectAPI
        resource :form do
          helpers ::API::V3::Queries::QueryHelper

          post do
            # We try to ignore invalid aspects of the query as the user
            # might not even be able to fix them (public  query)
            # and because they might only be invalid in his context
            # but not for somebody having more permissions, e.g. subproject
            # filter for admin vs for anonymous.
            # Permissions are enforced nevertheless.
            @query.valid_subset!

            create_or_update_query_form @query, ::Queries::UpdateFormContract, UpdateFormRepresenter
          end
        end
      end
    end
  end
end

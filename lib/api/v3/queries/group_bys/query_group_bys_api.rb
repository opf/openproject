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

module API
  module V3
    module Queries
      module GroupBys
        class QueryGroupBysAPI < ::API::OpenProjectAPI
          resource :group_bys do
            helpers do
              def convert_to_ar(attribute)
                ::API::Utilities::WpPropertyNameConverter.to_ar_name(attribute)
              end
            end

            after_validation do
              authorize(:view_work_packages, global: true, user: current_user)
            end

            route_param :id, type: String, regexp: /\A\w+\z/, desc: 'Group by ID' do
              get do
                ar_id = convert_to_ar(params[:id]).to_sym
                column = Query.groupable_columns.detect { |candidate| candidate.name == ar_id }

                if column
                  ::API::V3::Queries::GroupBys::QueryGroupByRepresenter.new(column)
                else
                  raise API::Errors::NotFound
                end
              end
            end
          end
        end
      end
    end
  end
end

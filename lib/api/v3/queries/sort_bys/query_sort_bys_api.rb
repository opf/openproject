#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Queries
      module SortBys
        class QuerySortBysAPI < ::API::OpenProjectAPI
          resource :sort_bys do
            helpers do
              def convert_to_ar(attribute)
                ::API::Utilities::WpPropertyNameConverter.to_ar_name(attribute)
              end

              def find_column(attribute)
                ar_id = convert_to_ar(attribute).to_sym

                Query
                  .sortable_columns
                  .detect { |candidate| candidate.name == ar_id }
              end
            end

            params do
              requires :id, desc: 'Group by id'
              requires :direction, desc: 'Direction of sorting'
            end

            before do
              authorize(:view_work_packages, global: true, user: current_user)
            end

            namespace ':id-:direction' do
              get do
                column = find_column(params[:id])

                begin
                  decorator = ::API::V3::Queries::SortBys::SortByDecorator.new(column,
                                                                               params[:direction])
                  ::API::V3::Queries::SortBys::QuerySortByRepresenter.new(decorator)
                rescue ArgumentError
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

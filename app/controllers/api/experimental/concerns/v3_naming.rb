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

module Api::Experimental::Concerns::V3Naming
  def v3_to_internal_name(string, append_id: true)
    if append_id
      API::Utilities::QueryFiltersNameConverter.to_ar_name(string,
                                                           refer_to_ids: append_id)
    else
      API::Utilities::WpPropertyNameConverter.to_ar_name(string,
                                                         refer_to_ids: append_id)
    end
  end

  def internal_to_v3_name(string)
    API::Utilities::PropertyNameConverter.from_ar_name(string)
  end

  def v3_params_as_internal
    params[:c] = params[:c].map { |column|
      v3_to_internal_name(column, append_id: false)
    } if params[:c]
    params[:f] = params[:f].map { |column|
      v3_to_internal_name(column)
    } if params[:f]
    params[:op] = params[:op].each_with_object({}) { |(column, operator), hash|
      hash[v3_to_internal_name(column)] = operator
    } if params[:op]
    params[:v] = params[:v].each_with_object({}) { |(column, value), hash|
      hash[v3_to_internal_name(column)] = value
    } if params[:v]
    params[:sort] = begin
                      (params[:sort] || '').split(',').map { |sort|
                        criteria = sort.split(':')

                        "#{v3_to_internal_name(criteria.first, append_id: false)}:#{criteria.last}"
                      }.join(',')
                    end if params[:sort]
    params[:group_by] = params.delete(:groupBy) || params[:group_by]
    params[:project_id] = params.delete(:projectId) || params[:project_id]
    params[:display_sums] = params.delete(:displaySums) || params[:display_sums]
    params[:is_public] = params.delete(:isPublic) || params[:is_public]
    params[:user_id] = params.delete(:userId) || params[:user_id]
    params[:query_id] = params.delete(:queryId) || params[:query_id]
  end

  def json_query_as_v3(json_query)
    json_query['columnNames'] = (json_query.delete('column_names') || [] ).map { |column|
      internal_to_v3_name(column)
    }

    json_query['sortCriteria'] = (json_query.delete('sort_criteria') || [] ).map { |criteria|
      [internal_to_v3_name(criteria.first), criteria.last]
    }

    json_query['groupBy'] = internal_to_v3_name(json_query.delete('group_by'))
    json_query['projectId'] = json_query.delete('project_id')
    json_query['displaySums'] = json_query.delete('display_sums')
    json_query['isPublic'] = json_query.delete('is_public')
    json_query['userId'] = json_query.delete('user_id')

    json_query['filters'].each do |filter|
      filter[:name] = internal_to_v3_name(filter[:name])
    end

    json_query
  end
end

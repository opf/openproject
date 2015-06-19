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

# This is an alternative to retrieve_query in the old queryies helper.
# Differences being that it's not looking to the session and also existing
# queries will be augmented with the params data passed with them.
module Api::Experimental::Concerns::QueryLoading
  private

  def init_query
    if !params[:query_id].blank?
      @query = Query.find(params[:query_id])
      @query.project = @project if @query.project.nil?
      unless QueryPolicy.new(User.current).allowed?(@query, :show)
        raise ActiveRecord::RecordNotFound.new
      end
    else
      @query = Query.new({ name: '_', project: @project },
                         initialize_with_default_filter: no_query_params_provided?)
    end
    prepare_query
    @query
  end

  def prepare_query
    # Set the query properties only if a query property string exists in the
    # URL. This assumes that if 'accept_empty_query_fields' or 'is_public'
    # are available also a query string exists
    #
    # This prevents a requested query from being overriden even if no query
    # parameters were given in the query string. Example: Assume you request
    # query 42 with URL?query_id=42. Although no further properties are given,
    # the code within the if would happiliy overwrite the requested query (in
    # this particular case 'group by').
    #
    # But if we guard 'group by' from being overwritten, we have no chance to
    # remove the grouping.
    if params[:accept_empty_query_fields] || params[:is_public]
      if User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
        @query.is_public = params[:is_public] if params[:is_public]
      else
        @query.is_public = false
      end

      if params[:fields] || params[:f] || params[:accept_empty_query_fields]
        view_context.add_filter_from_params
      end

      @query.group_by = params[:group_by]
      @query.sort_criteria = prepare_sort_criteria if params[:sort]
      @query.display_sums = params[:display_sums] if params[:display_sums].present?
      @query.column_names = params[:c] if params[:c]
      @query.column_names = nil if params[:default_columns]
      @query.name = params[:name] if params[:name]
    end
  end

  def prepare_sort_criteria
    # Note: There was a convention to have sortation strings in the form "type:desc,status:asc".
    # For the sake of not breaking from convention we encoding/decoding the sortation.
    params[:sort].split(',').map { |p| [p.split(':')[0], p.split(':')[1] || 'asc'] }
  end

  def no_query_params_provided?
    (params.keys & %w(group_by c fields f sort is_public name display_sums)).empty?
  end

  def allowed_links_on_query(query, user)
    links = {}
    QueryPolicy.new(user).tap do |auth|
      new_query = Query.new(project: @project)
      links[:create]      = api_experimental_queries_path      if auth.allowed?(new_query,
                                                                                :create)
      links[:update]      = api_experimental_query_path(query) if auth.allowed?(query,
                                                                                :update)
      links[:delete]      = api_experimental_query_path(query) if auth.allowed?(query,
                                                                                :destroy)
      links[:publicize]   = api_experimental_query_path(query) if auth.allowed?(query,
                                                                                :publicize)
      links[:depublicize] = api_experimental_query_path(query) if auth.allowed?(query,
                                                                                :depublicize)
      links[:star]        = query_route_from_grape('star', query) if auth.allowed?(query,
                                                                                   :star)
      links[:unstar]      = query_route_from_grape('unstar', query) if auth.allowed?(query,
                                                                                     :unstar)
    end

    links
  end
end

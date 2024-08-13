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

class SearchController < ApplicationController
  include Layout

  before_action :load_and_authorize_in_optional_project,
                :prepare_tokens

  LIMIT = 10

  def index
    if @tokens.any?
      @results, @results_count = search_results(@tokens)

      if search_params[:previous].nil?
        limit_results_first_page
      else
        limit_results_subsequent_page
      end
    end

    provision_gon

    render layout: layout_non_or_no_menu
  end

  private

  def prepare_tokens
    @question = search_params[:q] || ""
    @question.strip!
    @tokens = scan_query_tokens(@question).uniq

    unless @tokens.any?
      @question = ""
    end
  end

  def limit_results_first_page
    @pagination_previous_date = @results[0].event_datetime if offset && @results[0]

    if @results.size > LIMIT
      @pagination_next_date = @results[LIMIT - 1].event_datetime
      @results = @results[0, LIMIT]
    end
  end

  def limit_results_subsequent_page
    @pagination_next_date = @results[-1].event_datetime if offset && @results[-1]

    if @results.size > LIMIT
      @pagination_previous_date = @results[-LIMIT].event_datetime
      @results = @results[-LIMIT, LIMIT]
    end
  end

  # extract tokens from the question
  # eg. hello "bye bye" => ["hello", "bye bye"]
  def scan_query_tokens(query)
    tokens = query.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).map { |m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, "") }

    # no more than 5 tokens to search for
    tokens.slice! 5..-1 if tokens.size > 5

    tokens
  end

  def search_params
    @search_params ||= permitted_params.search
  end

  def offset
    value = Rational(search_params[:offset], exception: false)
    Time.zone.at(value) if value
  end

  def projects_to_search
    case search_params[:scope]
    when "all"
      nil
    when "current_project"
      @project
    else
      @project ? @project.self_and_descendants.active : nil
    end
  end

  def search_results(tokens)
    results = []
    results_count = Hash.new(0)

    search_classes.each do |scope, klass|
      r, c = klass.search(tokens,
                          projects_to_search,
                          limit: (LIMIT + 1),
                          offset:,
                          before: search_params[:previous].nil?)

      results += r
      results_count[scope] += c
    end

    results = sort_by_event_datetime(results)

    [results, results_count]
  end

  def sort_by_event_datetime(results)
    results.sort { |a, b| b.event_datetime <=> a.event_datetime }
  end

  def search_types
    types = Redmine::Search.available_search_types.dup

    if projects_to_search.is_a? Project
      # don't search projects
      types.delete("projects")
      # only show what the user is allowed to view
      types = types.select { |o| User.current.allowed_in_project?(:"view_#{o}", projects_to_search) }
    end

    types
  end

  def search_classes
    scope = search_types & search_params.keys

    scope = if scope.empty?
              search_types
            elsif scope & ["work_packages"] == scope
              []
            else
              scope
            end

    scope.index_with { |s| scope_class(s) }
  end

  def scope_class(scope)
    scope.singularize.camelcase.constantize
  end

  def provision_gon
    available_search_types = search_types.dup.push("all")

    gon.global_search = {
      search_term: @question,
      project_scope: search_params[:scope].to_s,
      available_search_types: available_search_types.map do |search_type|
        {
          id: search_type,
          name: OpenProject::GlobalSearch.tab_name(search_type)
        }
      end,
      current_tab: available_search_types.detect { |search_type| search_params[search_type] } || "all"
    }
  end
end

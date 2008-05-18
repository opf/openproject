# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class SearchController < ApplicationController
  layout 'base'
  
  before_filter :find_optional_project

  helper :messages
  include MessagesHelper

  def index
    @question = params[:q] || ""
    @question.strip!
    @all_words = params[:all_words] || (params[:submit] ? false : true)
    @titles_only = !params[:titles_only].nil?
    
    projects_to_search =
      case params[:projects]
      when 'all'
        nil
      when 'my_projects'
        User.current.memberships.collect(&:project)
      else
        @project
      end
          
    offset = nil
    begin; offset = params[:offset].to_time if params[:offset]; rescue; end
    
    # quick jump to an issue
    if @question.match(/^#?(\d+)$/) && Issue.find_by_id($1, :include => :project, :conditions => Project.visible_by(User.current))
      redirect_to :controller => "issues", :action => "show", :id => $1
      return
    end
    
    @object_types = %w(issues news documents changesets wiki_pages messages projects)
    if projects_to_search.is_a? Project
      # don't search projects
      @object_types.delete('projects')
      # only show what the user is allowed to view
      @object_types = @object_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, projects_to_search)}
    end
      
    @scope = @object_types.select {|t| params[t]}
    @scope = @object_types if @scope.empty?
    
    # extract tokens from the question
    # eg. hello "bye bye" => ["hello", "bye bye"]
    @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
    # tokens must be at least 3 character long
    @tokens = @tokens.uniq.select {|w| w.length > 2 }
    
    if !@tokens.empty?
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5
      # strings used in sql like statement
      like_tokens = @tokens.collect {|w| "%#{w.downcase}%"}      
      @results = []
      limit = 10
      @scope.each do |s|
        @results += s.singularize.camelcase.constantize.search(like_tokens, projects_to_search,
          :all_words => @all_words,
          :titles_only => @titles_only,
          :limit => (limit+1),
          :offset => offset,
          :before => params[:previous].nil?)
      end
      @results = @results.sort {|a,b| b.event_datetime <=> a.event_datetime}
      if params[:previous].nil?
        @pagination_previous_date = @results[0].event_datetime if offset && @results[0]
        if @results.size > limit
          @pagination_next_date = @results[limit-1].event_datetime 
          @results = @results[0, limit]
        end
      else
        @pagination_next_date = @results[-1].event_datetime if offset && @results[-1]
        if @results.size > limit
          @pagination_previous_date = @results[-(limit)].event_datetime 
          @results = @results[-(limit), limit]
        end
      end
    else
      @question = ""
    end
    render :layout => false if request.xhr?
  end

private  
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

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

  helper :messages
  include MessagesHelper

  def index
    @question = params[:q] || ""
    @question.strip!
    @all_words = params[:all_words] || (params[:submit] ? false : true)
    @titles_only = !params[:titles_only].nil?
    
    offset = nil
    begin; offset = params[:offset].to_time if params[:offset]; rescue; end
    
    # quick jump to an issue
    if @question.match(/^#?(\d+)$/) && Issue.find_by_id($1, :include => :project, :conditions => Project.visible_by(User.current))
      redirect_to :controller => "issues", :action => "show", :id => $1
      return
    end
    
    if params[:id]
      find_project
      return unless check_project_privacy
    end
    
    if @project
      # only show what the user is allowed to view
      @object_types = %w(issues news documents changesets wiki_pages messages)
      @object_types = @object_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, @project)}
      
      @scope = @object_types.select {|t| params[t]}
      @scope = @object_types if @scope.empty?
    else
      @object_types = @scope = %w(projects)
    end
    
    # tokens must be at least 3 character long
    @tokens = @question.split.uniq.select {|w| w.length > 2 }
    
    if !@tokens.empty?
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5
      # strings used in sql like statement
      like_tokens = @tokens.collect {|w| "%#{w.downcase}%"}      
      @results = []
      limit = 10
      if @project        
        @scope.each do |s|
          @results += s.singularize.camelcase.constantize.search(like_tokens, @project,
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
        operator = @all_words ? ' AND ' : ' OR '
        Project.with_scope(:find => {:conditions => Project.visible_by(User.current)}) do
          @results += Project.find(:all, :limit => limit, :conditions => [ (["(LOWER(name) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @scope.include? 'projects'
        end
        # if only one project is found, user is redirected to its overview
        redirect_to :controller => 'projects', :action => 'show', :id => @results.first and return if @results.size == 1
      end
      @question = @tokens.join(" ")
    else
      @question = ""
    end
    render :layout => false if request.xhr?
  end

private  
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

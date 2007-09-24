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
    
    # quick jump to an issue
    if @question.match(/^#?(\d+)$/) && Issue.find_by_id($1, :include => :project, :conditions => Project.visible_by(logged_in_user))
      redirect_to :controller => "issues", :action => "show", :id => $1
      return
    end
    
    if params[:id]
      find_project
      return unless check_project_privacy
    end
    
    if @project
      @object_types = %w(projects issues changesets news documents wiki_pages messages)
      @object_types.delete('wiki_pages') unless @project.wiki
      @object_types.delete('changesets') unless @project.repository
      # only show what the user is allowed to view
      @object_types = @object_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, @project)}
      
      @scope = @object_types.select {|t| params[t]}
      # default objects to search if none is specified in parameters
      @scope = @object_types if @scope.empty?
    else
      @scope = %w(projects)
    end
    
    # tokens must be at least 3 character long
    @tokens = @question.split.uniq.select {|w| w.length > 2 }
    
    if !@tokens.empty?
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5
      # strings used in sql like statement
      like_tokens = @tokens.collect {|w| "%#{w.downcase}%"}
      operator = @all_words ? " AND " : " OR "
      limit = 10
      @results = []
      if @project        
        @results += @project.issues.find(:all, :limit => limit, :include => :author, :conditions => [ (["(LOWER(subject) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @scope.include? 'issues'
        Journal.with_scope :find => {:conditions => ["#{Issue.table_name}.project_id = ?", @project.id]} do
          @results += Journal.find(:all, :include => :issue, :limit => limit, :conditions => [ (["(LOWER(notes) like ? OR LOWER(notes) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ).collect(&:issue) if @scope.include? 'issues'
        end
        @results.uniq!
        @results += @project.news.find(:all, :limit => limit, :conditions => [ (["(LOWER(title) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort], :include => :author ) if @scope.include? 'news'
        @results += @project.documents.find(:all, :limit => limit, :conditions => [ (["(LOWER(title) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @scope.include? 'documents'
        @results += @project.wiki.pages.find(:all, :limit => limit, :include => :content, :conditions => [ (["(LOWER(title) like ? OR LOWER(text) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @project.wiki && @scope.include?('wiki_pages')
        @results += @project.repository.changesets.find(:all, :limit => limit, :conditions => [ (["(LOWER(comments) like ?)"] * like_tokens.size).join(operator), * (like_tokens).sort] ) if @project.repository && @scope.include?('changesets')
        Message.with_scope :find => {:conditions => ["#{Board.table_name}.project_id = ?", @project.id]} do
          @results += Message.find(:all, :include => :board, :limit => limit, :conditions => [ (["(LOWER(subject) like ? OR LOWER(content) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @scope.include? 'messages'
        end
      else
        Project.with_scope(:find => {:conditions => Project.visible_by(logged_in_user)}) do
          @results += Project.find(:all, :limit => limit, :conditions => [ (["(LOWER(name) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @scope.include? 'projects'
        end
        # if only one project is found, user is redirected to its overview
        redirect_to :controller => 'projects', :action => 'show', :id => @results.first and return if @results.size == 1
      end
      @question = @tokens.join(" ")
    else
      @question = ""
    end
  end

private  
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

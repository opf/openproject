#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class JournalsController < ApplicationController
  before_filter :find_journal, :only => [:edit, :diff]
  before_filter :find_issue, :only => [:new]
  before_filter :find_optional_project, :only => [:index]
  before_filter :authorize, :only => [:new, :edit, :diff]
  accept_key_auth :index
  menu_item :issues

  include QueriesHelper
  include SortHelper

  def index
    retrieve_query
    sort_init 'id', 'desc'
    sort_update(@query.sortable_columns)

    if @query.valid?
      @journals = @query.issue_journals(:order => "#{Journal.table_name}.created_at DESC",
                                        :limit => 25)
    end
    @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
    render :layout => false, :content_type => 'application/atom+xml'
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Used when replying to an issue or journal
  def new
    journal = Journal.find(params[:journal_id]) if params[:journal_id]
    if journal
      user = journal.user
      text = journal.notes
    else
      user = @issue.author
      text = @issue.description
    end
    # Replaces pre blocks with [...]
    text = text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]')
    content = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
    content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"

    render(:update) { |page|
      page.<< "$('notes').value = \"#{escape_javascript content}\";"
      page.show 'update'
      page << "Form.Element.focus('notes');"
      page << "Element.scrollTo('update');"
      page << "$('notes').scrollTop = $('notes').scrollHeight - $('notes').clientHeight;"
    }
  end

  def edit
    (render_403; return false) unless @journal.editable_by?(User.current)
    if request.post?
      @journal.update_attribute(:notes, params[:notes]) if params[:notes]
      @journal.destroy if @journal.details.empty? && @journal.notes.blank?
      call_hook(:controller_journals_edit_post, { :journal => @journal, :params => params})
      respond_to do |format|
        format.html { redirect_to :controller => @journal.journaled.class.name.pluralize.downcase,
          :action => 'show', :id => @journal.journaled_id }
        format.js { render :action => 'update' }
      end
    else
      respond_to do |format|
        format.html {
          # TODO: implement non-JS journal update
          render :nothing => true
        }
        format.js
      end
    end
  end

  private

  def find_journal
    @journal = Journal.find(params[:id])
    @project = @journal.journalized.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # TODO: duplicated in IssuesController
  def find_issue
    @issue = Issue.find(params[:id], :include => [:project, :tracker, :status, :author, :priority, :category])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

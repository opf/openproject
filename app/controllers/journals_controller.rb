#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'diff'

class JournalsController < ApplicationController
  before_filter :find_journal, :only => [:edit, :update, :diff]
  before_filter :find_optional_project, :only => [:index]
  before_filter :authorize, :only => [:edit, :update]
  accept_key_auth :index
  menu_item :issues

  include QueriesHelper
  include SortHelper

  def index
    retrieve_query
    sort_init 'id', 'desc'
    sort_update(@query.sortable_columns)

    if @query.valid?
      @journals = @query.work_package_journals(:order => "#{Journal.table_name}.created_at DESC",
                                            :limit => 25)
    end
    @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
    respond_to do |format|
      format.atom { render :layout => false, :content_type => 'application/atom+xml' }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def edit
    (render_403; return false) unless @journal.editable_by?(User.current)
    respond_to do |format|
      format.html {
        # TODO: implement non-JS journal update
        render :nothing => true
      }
      format.js
    end
  end

  def update
    @journal.update_attribute(:notes, params[:notes]) if params[:notes]
    @journal.destroy if @journal.details.empty? && @journal.notes.blank?
    call_hook(:controller_journals_edit_post, { :journal => @journal, :params => params})
    respond_to do |format|
      format.html { redirect_to :controller => "/#{@journal.journable.class.name.pluralize.downcase}",
        :action => 'show', :id => @journal.journable_id }
      format.js { render :action => 'update' }
    end
  end

  def diff
    if valid_field?(params[:field])
      field = params[:field].parameterize.underscore.to_sym
      from = @journal.changed_data[field][0]
      to = @journal.changed_data[field][1]

      @diff = Redmine::Helpers::Diff.new(to, from)
      @journable = @journal.journable
      respond_to do |format|
        format.html { }
        format.js { render :partial => 'diff', :locals => { :diff => @diff } }
      end
    else
      render_404
    end
  end

  private

  def find_journal
    @journal = Journal.find(params[:id])
    @project = @journal.journable.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Is this a valid field for diff'ing?
  def valid_field?(field)
    field.to_s.strip == "description"
  end

  def default_breadcrumb
    I18n.t(:label_journal_diff)
  end
end

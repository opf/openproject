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

class DocumentsController < ApplicationController
  default_search_scope :documents
  model_object Document
  before_filter :find_project_by_project_id, :only => [:index, :new, :create]
  before_filter :find_model_object, :except => [:index, :new, :create]
  before_filter :find_project_from_association, :except => [:index, :new, :create]
  before_filter :authorize


  def index
    @sort_by = %w(category date title author).include?(params[:sort_by]) ? params[:sort_by] : 'category'
    documents = @project.documents
    case @sort_by
    when 'date'
      @grouped = documents.group_by {|d| d.updated_on.to_date }
    when 'title'
      @grouped = documents.group_by {|d| d.title.first.upcase}
    when 'author'
      @grouped = documents.with_attachments.group_by {|d| d.attachments.last.author}
    else
      @grouped = documents.includes(:category).group_by(&:category)
    end
    render :layout => false if request.xhr?
  end

  def show
    @attachments = @document.attachments.find(:all, :order => "created_on DESC")
  end

  def new
    @document = @project.documents.build
    @document.safe_attributes = params[:document]
  end

  def create
    @document = @project.documents.build
    @document.safe_attributes = params[:document]
    if @document.save
      attachments = Attachment.attach_files(@document, params[:attachments])
      render_attachment_warning_if_needed(@document)
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_documents_path(@project)
    else
      render :action => 'new'
    end
  end

  def edit
    @categories = DocumentCategory.all
  end

  def update
    @document.safe_attributes = params[:document]
    if @document.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @document
    end
  end

  def destroy
    @document.destroy
    redirect_to :controller => '/documents', :action => 'index', :project_id => @project
  end

  def add_attachment
    attachments = Attachment.attach_files(@document, params[:attachments])
    render_attachment_warning_if_needed(@document)

    # TODO: refactor
    if attachments.present? && attachments[:files].present? && Setting.notified_events.include?('document_added')
      users = User.find_all_by_mails(attachments[:files].first.container.recipients)
      users.each do |user|
        UserMailer.attachments_added(user, attachments[:files]).deliver
      end
    end
    redirect_to :action => 'show', :id => @document
  end
end

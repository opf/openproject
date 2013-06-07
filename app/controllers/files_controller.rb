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

class FilesController < ApplicationController
  menu_item :files

  before_filter :find_project_by_project_id
  before_filter :authorize

  include SortHelper

  def index
    sort_init 'filename', 'asc'
    sort_update 'filename' => "#{Attachment.table_name}.filename",
                'created_on' => "#{Attachment.table_name}.created_on",
                'size' => "#{Attachment.table_name}.filesize",
                'downloads' => "#{Attachment.table_name}.downloads"

    @containers = [ Project.find(@project.id, :include => :attachments, :order => sort_clause)]
    @containers += @project.versions.find(:all, :include => :attachments, :order => sort_clause).sort.reverse
    render :layout => !request.xhr?
  end

  def new
    @versions = @project.versions.sort
  end

  def create
    container = (params[:version_id].blank? ? @project : @project.versions.find_by_id(params[:version_id]))
    attachments = Attachment.attach_files(container, params[:attachments])
    render_attachment_warning_if_needed(container)

    if !attachments.empty? && !attachments[:files].blank? && Setting.notified_events.include?('file_added')
      # TODO: refactor
      recipients = attachments[:files].first.container.project.notified_users.select {|user| user.allowed_to?(:view_files, container.project)}.collect  {|u| u.mail}
      users = User.find_all_by_mails(recipients)
      users.each do |user|
        UserMailer.attachments_added(user, attachments[:files]).deliver
      end
    end
    redirect_to project_files_path(@project)
  end
end

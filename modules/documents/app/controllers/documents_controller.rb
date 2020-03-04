#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class DocumentsController < ApplicationController
  default_search_scope :documents
  model_object Document
  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_model_object, except: [:index, :new, :create]
  before_action :find_project_from_association, except: [:index, :new, :create]
  before_action :authorize

  def index
    @group_by = %w(category date title author).include?(params[:group_by]) ? params[:group_by] : 'category'
    documents = @project.documents
    @grouped =
      case @group_by
      when 'date'
        documents.group_by {|d| d.updated_on.to_date }
      when 'title'
        documents.group_by {|d| d.title.first.upcase}
      when 'author'
        documents.with_attachments.group_by {|d| d.attachments.last.author}
      else
        documents.includes(:category).group_by(&:category)
      end

    render layout: false if request.xhr?
  end

  def show
    @attachments = @document.attachments.order(Arel.sql('created_at DESC'))
  end

  def new
    @document = @project.documents.build
    @document.attributes = document_params
  end

  def create
    @document = @project.documents.build
    @document.attributes = document_params
    @document.attach_files(permitted_params.attachments.to_h)

    if @document.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_documents_path(@project)
    else
      render action: 'new'
    end
  end

  def edit
    @categories = DocumentCategory.all
  end

  def update
    @document.attributes = document_params
    @document.attach_files(permitted_params.attachments.to_h)

    if @document.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'show', id: @document
    else
      render action: 'edit'
    end
  end

  def destroy
    @document.destroy
    redirect_to controller: '/documents', action: 'index', project_id: @project
  end

  def add_attachment
    @document.attach_files(permitted_params.attachments.to_h)
    attachments = @document.attachments.select(&:new_record?)

    @document.save
    saved_attachments = attachments.select(&:persisted?)

    if saved_attachments.present? && Setting.notified_events.include?('document_added')
      users = saved_attachments.first.container.recipients
      users.each do |user|
        UserMailer.attachments_added(user, saved_attachments).deliver_later
      end
    end
    redirect_to action: 'show', id: @document
  end

  private

  def document_params
    params.fetch(:document, {}).permit('category_id', 'title', 'description')
  end
end

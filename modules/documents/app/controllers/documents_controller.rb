# frozen_string_literal: true

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

class DocumentsController < ApplicationController
  include AttachableServiceCall
  include FlashMessagesOutputSafetyHelper
  include PaginationHelper
  include OpTurbo::ComponentStream

  default_search_scope :documents

  before_action :find_project_by_project_id, only: %i[index search new create]
  before_action :find_document, except: %i[index search new create]
  before_action :authorize

  def index
    @documents = list_documents_query
      .includes(:type)
      .paginate(page: page_param, per_page: per_page_param)
  end

  def search
    index
    replace_via_turbo_stream component: Documents::ListComponent.new(@documents, project: @project)
    current_url = url_for(params.permit(:controller, :filters, :sortBy).merge(action: "index"))
    turbo_streams << turbo_stream.push_state(current_url)

    respond_with_turbo_streams
  end

  def show
    @attachments = @document.attachments.order(Arel.sql("created_at DESC"))

    load_version_journal if params[:version].present?

    if @document.collaborative? && Setting.real_time_text_collaboration_enabled?
      setup_collaboration_context unless @version_journal
      derive_show_edit_state_from_params
    end
  end

  def restore_version
    journal = find_version_journal_for_manage
    return unless journal

    call = Documents::RestoreVersionService
      .new(user: current_user, document: @document)
      .call(journal:)

    if call.success?
      flash[:notice] = I18n.t("documents.versions.restore_success")
      redirect_to document_path(@document)
    else
      flash[:error] = call.errors.full_messages.join(", ")
      redirect_back_or_to document_path(@document)
    end
  end

  def save_copy
    journal = find_version_journal_for_manage
    return unless journal

    call = Documents::SaveCopyService
      .new(user: current_user, document: @document)
      .call(journal:)

    if call.success?
      flash[:notice] = I18n.t("documents.versions.save_copy_success")
      redirect_to document_path(call.result)
    else
      flash[:error] = call.errors.full_messages.join(", ")
      redirect_back_or_to document_path(@document)
    end
  end

  def render_avatars
    user_ids = params[:user_ids]
    @users = User.visible.where(id: user_ids)
    update_via_turbo_stream(component: Documents::ShowEditView::PageHeader::LiveUsersComponent.new(users: @users))

    respond_with_turbo_streams
  end

  def render_last_saved_at
    update_via_turbo_stream(component: Documents::ShowEditView::PageHeader::LiveSavedAtComponent.new(@document))

    respond_with_turbo_streams
  end

  def new
    @document = @project.documents.build
    @document.attributes = document_params
  end

  def edit
    render_400 unless @document.classic?
  end

  def edit_title
    update_header_component_via_turbo_stream(state: :edit)

    respond_with_turbo_streams
  end

  def create
    if document_params[:kind] == "classic"
      create_classic_document
    else
      create_collaborative_document
    end
  end

  def cancel_title_edit
    update_header_component_via_turbo_stream(state: :show)

    respond_with_turbo_streams
  end

  def update
    call = attachable_update_call ::Documents::UpdateService,
                                  model: @document,
                                  args: document_params

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "show", id: @document
    else
      @document = call.result
      render action: :edit, status: :unprocessable_entity
    end
  end

  def update_title
    call = Documents::UpdateService
      .new(user: current_user, model: @document)
      .call(document_params.slice(:title))

    state = call.success? ? :show : :edit
    update_header_component_via_turbo_stream(state:)

    respond_with_turbo_streams
  end

  def update_type
    service_call = Documents::UpdateService
      .new(user: current_user, model: @document)
      .call(type_id: params[:type_id])

    if service_call.success?
      update_via_turbo_stream(
        component: Documents::ShowEditView::PageHeader::InfoLineComponent.new(@document)
      )
    else
      render_error_flash_message_via_turbo_stream(
        message: service_call.errors.full_messages
      )
      @turbo_status = :unprocessable_entity
    end

    respond_with_turbo_streams
  end

  def delete_dialog
    respond_with_dialog Documents::DeleteDialogComponent.new(@document)
  end

  def destroy
    service_call = Documents::DeleteService
      .new(user: current_user, model: @document)
      .call

    if service_call.success?
      flash[:notice] = I18n.t(:notice_successful_delete)
    else
      flash[:error] = join_flash_messages(service_call.errors.full_messages)
    end

    redirect_to project_documents_path(@project), status: :see_other
  end

  private

  def find_document
    @document = Document.visible.find(params[:id])
    @project = @document.project
  end

  def document_params
    params.fetch(:document, {}).permit("type_id", "title", "description", "content_binary", "kind")
  end

  def list_documents_query
    @query = ParamsToQueryService.new(Document, current_user).call(params)
    @query.where(:project_id, "=", [@project.id])
    @query.order(updated_at: :desc) unless params[:sortBy]

    @query.results
  end

  def create_classic_document
    call = attachable_create_call ::Documents::CreateService,
                                  args: document_params.merge(project: @project)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to project_documents_path(@project)
    else
      @document = call.result
      render action: :new, status: :unprocessable_entity
    end
  end

  def create_collaborative_document
    call = ::Documents::CreateService
        .new(user: current_user)
        .call(title: I18n.t(:label_document_new), project: @project, type_id: DocumentType.default.id)

    redirect_to document_path(call.result, state: :edit)
  end

  def setup_collaboration_context # rubocop:disable Metrics/AbcSize
    return unless current_user.allowed_in_project?(:view_documents, @project)

    token_result = Documents::OAuth::TokenWithMetadataService
      .new(user: current_user, document: @document, project: @project)
      .call

    if token_result.failure?
      Rails.logger.error("Failed to generate token payload for document #{@document.id}: #{token_result.errors}")
      return
    end

    @token_payload = token_result.result[:encrypted_token]
    @resource_url = token_result.result[:resource_url]
    @readonly = token_result.result[:readonly]
    @token_expires_in_seconds = token_result.result[:expires_in_seconds]
  end

  def update_header_component_via_turbo_stream(state: :show)
    update_via_turbo_stream(
      component: Documents::ShowEditView::PageHeaderComponent.new(@document, project: @project, state:)
    )
  end

  def derive_show_edit_state_from_params
    @state = params[:state] == "edit" ? :edit : :show
  end

  def load_version_journal
    journal = @document.journals.find_by(id: params[:version])
    return unless journal

    @version_journal = journal
    @document.description = journal.data.description
    if @document.collaborative?
      @version_content_binary = journal.data.content_binary
      @document.content_binary = @version_content_binary
    end
    @readonly = true
  end

  def find_version_journal_for_manage
    unless current_user.allowed_in_project?(:manage_documents, @project)
      render_403
      return nil
    end

    journal = @document.journals.find_by(id: params[:version_id])
    unless journal
      render_404
      return nil
    end

    journal
  end
end

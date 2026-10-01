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

class MessagesController < ApplicationController
  menu_item :forums
  default_search_scope :messages
  before_action :find_project_and_forum
  before_action :find_message, only: %i[show edit update destroy reply quote]
  before_action :authorize, except: %i[edit update destroy]
  # Checked inside the method.
  no_authorization_required! :edit, :update, :destroy

  include AttachmentsHelper
  include PaginationHelper

  REPLIES_PER_PAGE = 100 unless const_defined?(:REPLIES_PER_PAGE)

  # Show a topic and its replies
  def show # rubocop:disable Metrics/AbcSize
    @topic = @message.root

    @offset = params[:page]
    # Find the page of the requested reply
    if params[:r] && @offset.nil?
      offset = @topic.children.where(["#{Message.table_name}.id < ?", params[:r].to_i]).count
      @offset = 1 + (offset / REPLIES_PER_PAGE)
    end

    @replies = @topic
               .children
               .includes(:author, :attachments, :project, forum: :project)
               .order(created_at: :asc)
               .page(@offset)
               .per_page(per_page_param)

    @reply = Message.new(subject: "RE: #{@message.subject}", parent: @topic, forum: @topic.forum)
    render action: "show", layout: !request.xhr?
  end

  # new topic
  def new
    @message = Messages::SetAttributesService
      .new(user: current_user,
           model: Message.new,
           contract_class: EmptyContract)
      .call(forum: @forum)
      .result
  end

  # Edit a message
  def edit
    return render_403 unless @message.editable_by?(User.current)

    @message.attributes = permitted_params.message(@message.project)
  end

  # Create a new topic
  def create
    call = create_message(@forum)
    @message = call.result

    if call.success?
      call_hook(:controller_messages_new_after_save, params:, message: @message)

      redirect_to project_forum_topic_path(@project, @forum, @message)
    else
      render action: :new, status: :unprocessable_entity
    end
  end

  # Reply to a topic
  def reply
    @topic = @message.root

    call = create_reply(@forum, @topic)
    @reply = call.result

    if call.success?
      call_hook(:controller_messages_reply_after_save, params:, message: @reply)
    end
    redirect_to project_forum_topic_path(@project, @forum, @topic, r: @reply)
  end

  # Edit a message
  def update
    # TODO: move into contract
    return render_403 unless @message.editable_by?(User.current)

    call = update_message(@message)

    if call.success?
      flash[:notice] = t(:notice_successful_update)
      @message.reload
      redirect_to project_forum_topic_path(@project, @forum, @message.root, r: @message.parent_id && @message.id)
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  # Delete a messages
  def destroy
    # TODO: move into contract
    return render_403 unless @message.destroyable_by?(User.current)

    @message.destroy
    flash[:notice] = t(:notice_successful_delete)
    redirect_target = if @message.parent.nil?
                        project_forum_path(@project, @forum)
                      else
                        project_forum_topic_path(@project, @forum, @message.parent, r: @message)
                      end

    redirect_to redirect_target, status: :see_other
  end

  def quote
    subject = @message.subject
    subject = "RE: #{subject}" unless subject.starts_with?("RE:")
    content = build_quote(author: @message.author, text: @message.content)

    respond_to do |format|
      format.json { render json: { subject:, content: }, escape: true }
      format.any { head :not_acceptable }
    end
  end

  private

  def find_project_and_forum
    @project = Project.visible.find(params[:project_id])
    @forum = @project.forums.find(params[:forum_id])
  end

  def find_message
    @message = @forum.messages.find(params[:id])
  end

  def update_message(message)
    Messages::UpdateService
      .new(user: current_user,
           model: message)
      .call(permitted_params.message(@project)
            .merge(attachment_params))
  end

  def create_message(forum, message_params = permitted_params.message(forum.project))
    params = message_params
               .merge(forum:)
               .merge(attachment_params)

    Messages::CreateService
      .new(user: current_user)
      .call(params)
  end

  def create_reply(forum, parent)
    create_message(forum, permitted_params.reply.merge(parent:))
  end

  def build_quote(author:, text:)
    attribution = I18n.t(:text_user_wrote, value: ERB::Util.html_escape(author), locale: Setting.default_language)
    sanitized = text.to_s.strip
                    .gsub(%r{<pre>(.+?)</pre>}m, "[...]")
    quoted_text = sanitized.gsub(/(\r?\n|\r\n?)/, "\n> ")

    "#{attribution}\n> #{quoted_text}\n\n"
  end

  def attachment_params
    attachment_params = permitted_params.attachments.to_h

    if attachment_params.any?
      { attachment_ids: attachment_params.values.map(&:values).flatten }
    else
      {}
    end
  end
end

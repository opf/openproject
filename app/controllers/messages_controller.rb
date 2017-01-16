#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class MessagesController < ApplicationController
  include OpenProject::Concerns::Preview
  menu_item :boards
  default_search_scope :messages
  model_object Message, scope: Board
  before_action :find_object_and_scope, except: [:preview]
  before_action :authorize, except: [:preview, :edit, :update, :destroy]

  include AttachmentsHelper
  include PaginationHelper

  REPLIES_PER_PAGE = 100 unless const_defined?(:REPLIES_PER_PAGE)

  # Show a topic and its replies
  def show
    @topic = @message.root

    page = params[:page]
    # Find the page of the requested reply
    if params[:r] && page.nil?
      offset = @topic.children.where(["#{Message.table_name}.id < ?", params[:r].to_i]).count
      page = 1 + offset / REPLIES_PER_PAGE
    end

    @replies = @topic.children.includes(:author, :attachments, board: :project)
               .order("#{Message.table_name}.created_on ASC")
               .page(page)
               .per_page(per_page_param)

    @reply = Message.new(subject: "RE: #{@message.subject}")
    render action: 'show', layout: !request.xhr?
  end

  # new topic
  def new
    @message = Message.new.tap do |m|
      m.author = User.current
      m.board = @board
    end
  end

  # Create a new topic
  def create
    @message = Message.new.tap do |m|
      m.author = User.current
      m.board = @board
    end

    @message.attributes = permitted_params.message(@message)

    @message.attach_files(permitted_params.attachments.to_h)

    if @message.save
      call_hook(:controller_messages_new_after_save,  params: params, message: @message)

      redirect_to topic_path(@message)
    else
      render action: 'new'
    end
  end

  # Reply to a topic
  def reply
    @topic = @message.root

    @reply = Message.new
    @reply.author = User.current
    @reply.board = @board
    @reply.attributes = permitted_params.reply

    @topic.children << @reply
    if !@reply.new_record?
      call_hook(:controller_messages_reply_after_save,  params: params, message: @reply)
      attachments = Attachment.attach_files(@reply, permitted_params.attachments)
      render_attachment_warning_if_needed(@reply)
    end
    redirect_to topic_path(@topic, r: @reply)
  end

  # Edit a message
  def edit
    (render_403; return false) unless @message.editable_by?(User.current)
    @message.attributes = permitted_params.message(@message)
  end

  # Edit a message
  def update
    (render_403; return false) unless @message.editable_by?(User.current)

    @message.attributes = permitted_params.message(@message)

    @message.attach_files(permitted_params.attachments.to_h)

    if @message.save
      flash[:notice] = l(:notice_successful_update)
      @message.reload
      redirect_to topic_path(@message.root, r: (@message.parent_id && @message.id))
    else
      render action: 'edit'
    end
  end

  # Delete a messages
  def destroy
    (render_403; return false) unless @message.destroyable_by?(User.current)
    @message.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to @message.parent.nil? ?
      { controller: '/boards', action: 'show', project_id: @project, id: @board } :
      { action: 'show', id: @message.parent, r: @message }
  end

  def quote
    user = @message.author
    text = @message.content
    subject = @message.subject.gsub('"', '\"')
    subject = "RE: #{subject}" unless subject.starts_with?('RE:')
    content = "#{ll(Setting.default_language, :text_user_wrote, user)}\\n> "
    content << text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]').gsub('"', '\"').gsub(/(\r?\n|\r\n?)/, '\\n> ') + '\\n\\n'

    respond_to do |format|
      format.js do
        render locals: { subject: subject, content: content }
      end
    end
  end

  protected

  def parse_preview_data
    if params.has_key?(:message)
      parse_preview_data_helper :message, :content
    else
      parse_preview_data_helper :reply, :content, Message
    end
  end
end

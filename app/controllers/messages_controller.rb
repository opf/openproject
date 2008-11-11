# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class MessagesController < ApplicationController
  menu_item :boards
  before_filter :find_board, :only => [:new, :preview]
  before_filter :find_message, :except => [:new, :preview]
  before_filter :authorize, :except => [:preview, :edit, :destroy]

  verify :method => :post, :only => [ :reply, :destroy ], :redirect_to => { :action => :show }
  verify :xhr => true, :only => :quote

  helper :watchers
  helper :attachments
  include AttachmentsHelper   

  # Show a topic and its replies
  def show
    @replies = @topic.children.find(:all, :include => [:author, :attachments, {:board => :project}])
    @replies.reverse! if User.current.wants_comments_in_reverse_order?
    @reply = Message.new(:subject => "RE: #{@message.subject}")
    render :action => "show", :layout => false if request.xhr?
  end
  
  # Create a new topic
  def new
    @message = Message.new(params[:message])
    @message.author = User.current
    @message.board = @board
    if params[:message] && User.current.allowed_to?(:edit_messages, @project)
      @message.locked = params[:message]['locked']
      @message.sticky = params[:message]['sticky']
    end
    if request.post? && @message.save
      attach_files(@message, params[:attachments])
      redirect_to :action => 'show', :id => @message
    end
  end

  # Reply to a topic
  def reply
    @reply = Message.new(params[:reply])
    @reply.author = User.current
    @reply.board = @board
    @topic.children << @reply
    if !@reply.new_record?
      attach_files(@reply, params[:attachments])
    end
    redirect_to :action => 'show', :id => @topic
  end

  # Edit a message
  def edit
    render_403 and return false unless @message.editable_by?(User.current)
    if params[:message]
      @message.locked = params[:message]['locked']
      @message.sticky = params[:message]['sticky']
    end
    if request.post? && @message.update_attributes(params[:message])
      attach_files(@message, params[:attachments])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @topic
    end
  end
  
  # Delete a messages
  def destroy
    render_403 and return false unless @message.destroyable_by?(User.current)
    @message.destroy
    redirect_to @message.parent.nil? ?
      { :controller => 'boards', :action => 'show', :project_id => @project, :id => @board } :
      { :action => 'show', :id => @message.parent }
  end
  
  def quote
    user = @message.author
    text = @message.content
    content = "#{ll(Setting.default_language, :text_user_wrote, user)}\\n> "
    content << text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]').gsub('"', '\"').gsub(/(\r?\n|\r\n?)/, "\\n> ") + "\\n\\n"
    render(:update) { |page|
      page.<< "$('message_content').value = \"#{content}\";"
      page.show 'reply'
      page << "Form.Element.focus('message_content');"
      page << "Element.scrollTo('reply');"
      page << "$('message_content').scrollTop = $('message_content').scrollHeight - $('message_content').clientHeight;"
    }
  end
  
  def preview
    message = @board.messages.find_by_id(params[:id])
    @attachements = message.attachments if message
    @text = (params[:message] || params[:reply])[:content]
    render :partial => 'common/preview'
  end
  
private
  def find_message
    find_board
    @message = @board.messages.find(params[:id], :include => :parent)
    @topic = @message.root
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_board
    @board = Board.find(params[:board_id], :include => :project)
    @project = @board.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

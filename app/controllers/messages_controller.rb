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
  layout 'base'
  before_filter :find_project, :authorize

  verify :method => :post, :only => [ :reply, :destroy ], :redirect_to => { :action => :show }

  helper :attachments
  include AttachmentsHelper   

  def show
    @reply = Message.new(:subject => "RE: #{@message.subject}")
    render :action => "show", :layout => false if request.xhr?
  end
  
  def new
    @message = Message.new(params[:message])
    @message.author = User.current
    @message.board = @board 
    if request.post? && @message.save
      params[:attachments].each { |file|
        next unless file.size > 0
        Attachment.create(:container => @message, :file => file, :author => User.current)
      } if params[:attachments] and params[:attachments].is_a? Array    
      redirect_to :action => 'show', :id => @message
    end
  end

  def reply
    @reply = Message.new(params[:reply])
    @reply.author = User.current
    @reply.board = @board
    @message.children << @reply
    redirect_to :action => 'show', :id => @message
  end
  
private
  def find_project
    @board = Board.find(params[:board_id], :include => :project)
    @project = @board.project
    @message = @board.topics.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

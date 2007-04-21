# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class MyController < ApplicationController
  layout 'base'
  before_filter :require_login

  BLOCKS = { 'issuesassignedtome' => :label_assigned_to_me_issues,
             'issuesreportedbyme' => :label_reported_issues,
             'issueswatched' => :label_watched_issues,
             'news' => :label_news_latest,
             'calendar' => :label_calendar,
             'documents' => :label_document_plural
           }.freeze

  DEFAULT_LAYOUT = {  'left' => ['issuesassignedtome'], 
                      'right' => ['issuesreportedbyme'] 
                   }.freeze

  verify :xhr => true,
         :session => :page_layout,
         :only => [:add_block, :remove_block, :order_blocks]

  def index
    page
    render :action => 'page'
  end

  # Show user's page
  def page
    @user = self.logged_in_user
    @blocks = @user.pref[:my_page_layout] || DEFAULT_LAYOUT
  end

  # Edit user's account
  def account
    @user = self.logged_in_user
    @pref = @user.pref
    @user.attributes = params[:user]
    @user.pref.attributes = params[:pref]
    if request.post? and @user.save and @user.pref.save
      set_localization
      flash.now[:notice] = l(:notice_account_updated)
      self.logged_in_user.reload
    end
  end

  # Change user's password
  def change_password
    @user = self.logged_in_user
    flash[:notice] = l(:notice_can_t_change_password) and redirect_to :action => 'account' and return if @user.auth_source_id
    if @user.check_password?(params[:password])
      @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
      if @user.save
        flash[:notice] = l(:notice_account_password_updated)
      else
        render :action => 'account'
        return
      end
    else
      flash[:notice] = l(:notice_account_wrong_password)
    end
    redirect_to :action => 'account'
  end

  # User's page layout configuration
  def page_layout
    @user = self.logged_in_user
    @blocks = @user.pref[:my_page_layout] || DEFAULT_LAYOUT.dup
    session[:page_layout] = @blocks
    %w(top left right).each {|f| session[:page_layout][f] ||= [] }
    @block_options = []
    BLOCKS.each {|k, v| @block_options << [l(v), k]}
  end
  
  # Add a block to user's page
  # The block is added on top of the page
  # params[:block] : id of the block to add
  def add_block
    block = params[:block]
    render(:nothing => true) and return unless block && (BLOCKS.keys.include? block)
    @user = self.logged_in_user
    # remove if already present in a group
    %w(top left right).each {|f| (session[:page_layout][f] ||= []).delete block }
    # add it on top
    session[:page_layout]['top'].unshift block
    render :partial => "block", :locals => {:user => @user, :block_name => block}
  end
  
  # Remove a block to user's page
  # params[:block] : id of the block to remove
  def remove_block
    block = params[:block]
    # remove block in all groups
    %w(top left right).each {|f| (session[:page_layout][f] ||= []).delete block }
    render :nothing => true
  end

  # Change blocks order on user's page
  # params[:group] : group to order (top, left or right)
  # params[:list-(top|left|right)] : array of block ids of the group
  def order_blocks
    group = params[:group]
    group_items = params["list-#{group}"]
    if group_items and group_items.is_a? Array
      # remove group blocks if they are presents in other groups
      %w(top left right).each {|f|
        session[:page_layout][f] = (session[:page_layout][f] || []) - group_items
      }
      session[:page_layout][group] = group_items    
    end
    render :nothing => true
  end
  
  # Save user's page layout  
  def page_layout_save
    @user = self.logged_in_user
    @user.pref[:my_page_layout] = session[:page_layout] if session[:page_layout]
    @user.pref.save
    session[:page_layout] = nil
    redirect_to :action => 'page'
  end
end

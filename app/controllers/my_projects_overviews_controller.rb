#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 Finn GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See LICENSE for more details.
#++

class MyProjectsOverviewsController < ApplicationController

  menu_item :overview

  unloadable

  before_filter :find_project, :find_user, :find_my_project_overview
  before_filter :find_page_blocks, :find_project_details
  before_filter :find_attachments

  BLOCKS = { 'issuesassignedtome' => :label_assigned_to_me_issues,
    'issuesreportedbyme' => :label_reported_issues,
    'issueswatched' => :label_watched_issues,
    'news' => :label_news_latest,
    'calendar' => :label_calendar,
    'documents' => :label_document_plural,
    'timelog' => :label_spent_time,
    'members' => :label_member_plural,
    'issuetracking' => :label_issue_tracking,
    'projectdetails' => :label_project_details,
    'wiki' => :label_wiki
  }

  verify :xhr => true,
         :only => [:add_block, :remove_block, :order_blocks]

  def index
    render
  end

  # User's page layout configuration
  def page_layout
    @block_options = []
    BLOCKS.each {|k, v| @block_options << [l("my.blocks.#{v}", :default => [v, v.to_s.humanize]), k.dasherize]}
    @block_options << [l(:label_custom_element), :custom_element]
  end

  def update_custom_element
    block_name = params["block_name"]
    block_title = params["block_title_#{block_name}"]
    textile = params["textile_#{block_name}"]

    if params["attachments"]
      # Attach files and save them
      attachments = Attachment.attach_files(@overview, params["attachments"])
      unless attachments[:unsaved].blank?
        flash[:error] = l(:warning_attachments_not_saved, attachments[:unsaved].size)
      end
    end

    @overview.save_custom_element(block_name, block_title, textile)

    redirect_to :back
  end

  # Add a block to user's page
  # The block is added on top of the page
  # params[:block] : id of the block to add
  def add_block
    block = params[:block].to_s.underscore
    if (BLOCKS.keys.include? block)
      # remove if already present in a group
      %w(top left right hidden).each {|f| @overview.send(f).delete block }
      # add it hidden
      @overview.hidden.unshift block
      @overview.save!
      render(:partial => "block",
             :locals => { :user => @user,
               :project => @project,
               :block_name => block})
    elsif block == "custom_element"
      @overview.hidden.unshift @overview.new_custom_element
      @overview.save!
      render(:partial => "block_textilizable",
             :locals => { :user => @user,
               :project => @project,
               :block_title => l(:label_custom_element),
               :block_name => @overview.hidden.first.first,
               :textile => @overview.hidden.first.last})
    else
      render :nothing => true
    end
  end

  # Remove a block to user's page
  # params[:block] : id of the block to remove
  def remove_block
    block = param_to_block(params[:block])
    %w(top left right hidden).each {|f| @overview.send(f).delete block }
    @overview.save!
    render :nothing => true
  end

  # Change blocks order on user's page
  # params[:group] : group to order (top, left or right)
  # params[:list-(top|left|right)] : array of block ids of the group
  def order_blocks
    group = params[:group]
    if group.is_a?(String)
      group_items = (params["list-#{group}"] || []).collect {|x| param_to_block(x) }
      unless group_items.size < @overview.send(group).size
        # We are adding or re-ordering, not removing
        # Remove group blocks if they are presents in other groups
        @overview.update_attributes('top' => (@overview.top - group_items),
                                    'left' => (@overview.left - group_items),
                                    'right' => (@overview.right - group_items),
                                    'hidden' => (@overview.hidden - group_items))
        @overview.update_attribute(group, group_items)
      end
    end
    render :nothing => true
  end

  def param_to_block(param)
    block = param.to_s.underscore
    unless (BLOCKS.keys.include? block)
      block = @overview.custom_elements.detect {|ary| ary.first == block}
    end
    block
  end

  def destroy_attachment
    if @user.allowed_to?(:edit_project, @project)
      begin
        att = Attachment.find(params[:attachment_id].to_i)
        @overview.attachments.delete(att)
        @overview.save
      rescue ActiveRecord::RecordNotFound
      end
    end
    @attachments -= [att]
    render :partial => 'page_layout_attachments'
  end

  def find_my_project_overview
    @overview = MyProjectsOverview.find(:first, :conditions => "project_id = #{@project.id}")
    # Auto-create missing overviews
    @overview ||= MyProjectsOverview.create!(:project_id => @project.id)
  end

  def find_user
    @user = User.current
  end

  def find_page_blocks
    @blocks = {
      'top' => @overview.top,
      'left' => @overview.left,
      'right' => @overview.right,
      'hidden' => @overview.hidden
    }
  end

  def find_project_details
    @users_by_role = @project.users_by_role
    @subprojects = @project.children.visible.all
    @news = @project.news.find(:all, :limit => 5,
                               :include => [ :author, :project ],
                               :order => "#{News.table_name}.created_on DESC")
    @trackers = @project.rolled_up_trackers

    cond = @project.project_condition(Setting.display_subprojects_issues?)

    @open_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?", false])
    @total_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => cond)

    if User.current.allowed_to?(:view_time_entries, @project)
      @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
    end
  end

  def find_attachments
    @attachments = @overview.attachments || []
  end
end

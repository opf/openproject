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

class MyProjectsOverviewsController < ApplicationController

  menu_item :overview

  unloadable

  before_filter :find_project, :find_user
  before_filter :authorize
  before_filter :jump_to_project_menu_item, :only => :index

  BLOCKS = { 'issuesassignedtome' => :label_assigned_to_me_issues,
    'issuesreportedbyme' => :label_reported_issues,
    'issueswatched' => :label_watched_issues,
    'news' => :label_news_latest,
    'calendar' => :label_calendar,
    'timelog' => :label_spent_time,
    'members' => :label_member_plural,
    'issuetracking' => :label_issue_tracking,
    'projectdetails' => :label_project_details,
    'projectdescription' => :label_project_description,
    'subprojects' => :label_subproject_plural
  }.merge(OpenProject::MyProjectPage.plugin_blocks).freeze

  verify :xhr => true,
         :only => [:add_block, :remove_block, :order_blocks]

  def index
    render
  end

  # User's page layout configuration
  def page_layout
  end

  def update_custom_element
    block_name = params["block_name"]
    block_title = params["block_title_#{block_name}"]
    textile = params["textile_#{block_name}"]

    if params["attachments"]
      # Attach files and save them
      attachments = Attachment.attach_files(overview, params["attachments"])
      unless attachments[:unsaved].blank?
        flash[:error] = l(:warning_attachments_not_saved, attachments[:unsaved].size)
      end
    end

    overview.save_custom_element(block_name, block_title, textile)

    redirect_to :back
  end

  # Add a block to user's page
  # The block is added on top of the page
  # params[:block] : id of the block to add
  def add_block
    block = params[:block].to_s.underscore
    if (BLOCKS.keys.include? block)
      # remove if already present in a group
      %w(top left right hidden).each {|f| overview.send(f).delete block }
      # add it hidden
      overview.hidden.unshift block
      overview.save!
      render :partial => "block",
             :locals => { :block_name => block }
    elsif block == "custom_element"
      overview.hidden.unshift overview.new_custom_element
      overview.save!
      render(:partial => "block_textilizable",
             :locals => { :user => user,
                          :project => project,
                          :block_title => l(:label_custom_element),
                          :block_name => overview.hidden.first.first,
                          :textile => overview.hidden.first.last})
    else
      render :nothing => true
    end
  end

  # Remove a block to user's page
  # params[:block] : id of the block to remove
  def remove_block
    block = param_to_block(params[:block])
    %w(top left right hidden).each {|f| overview.send(f).delete block }
    overview.save!
    render :nothing => true
  end

  # Change blocks order on user's page
  # params[:group] : group to order (top, left or right)
  # params[:list-(top|left|right)] : array of block ids of the group
  def order_blocks
    group = params[:group]
    if group.is_a?(String)
      group_items = (params["list-#{group}"] || []).collect {|x| param_to_block(x) }
      unless group_items.size < overview.send(group).size
        # We are adding or re-ordering, not removing
        # Remove group blocks if they are presents in other groups
        overview.update_attributes('top' => (overview.top - group_items),
                                   'left' => (overview.left - group_items),
                                   'right' => (overview.right - group_items),
                                   'hidden' => (overview.hidden - group_items))
        overview.update_attribute(group, group_items)
      end
    end
    render :nothing => true
  end

  def param_to_block(param)
    block = param.to_s.underscore
    unless (BLOCKS.keys.include? block)
      block = overview.custom_elements.detect {|ary| ary.first == block}
    end
    block
  end

  def destroy_attachment
    if user.allowed_to?(:edit_project, project)
      begin
        att = Attachment.find(params[:attachment_id].to_i)
        overview.attachments.delete(att)
        overview.save
      rescue ActiveRecord::RecordNotFound
      end
    end

    render :partial => 'page_layout_attachments'
  end

  def show_all_members
    respond_to do |format|
      format.js { render :partial => "members",
                         :locals => { :users_by_role => users_by_role(0),
                                      :count_users_by_role => count_users_by_role } }
    end
  end

  helper_method :users_by_role,
                :count_users_by_role,
                :childprojects,
                :recent_news,
                :trackers,
                :open_issues_by_tracker,
                :total_issues_by_tracker,
                :assigned_issues,
                :total_hours,
                :project,
                :user,
                :blocks,
                :block_options,
                :overview,
                :attachments,
                :render_block,
                :object_callback

  def childprojects
    @childprojects ||= project.children.visible.all
  end

  def recent_news
    @news ||= project.news.all :limit => 5,
                               :include => [ :author, :project ],
                               :order => "#{News.table_name}.created_on DESC"

  end

  def trackers
    @trackers ||= project.rolled_up_trackers
  end

  def open_issues_by_tracker
    @open_issues_by_tracker ||= Issue.visible.count(:group => :tracker,
                                                    :include => [:project, :status, :tracker],
                                                    :conditions => ["(#{subproject_condition}) AND #{IssueStatus.table_name}.is_closed=?", false])
  end

  def total_issues_by_tracker
    @total_issues_by_tracker ||= Issue.visible.count(:group => :tracker,
                                                     :include => [:project, :status, :tracker],
                                                     :conditions => subproject_condition)

  end

  def assigned_issues
    @assigned_issues ||= Issue.visible.open.find(:all,
                                                 :conditions => { :assigned_to_id => User.current.id },
                                                 :limit => 10,
                                                 :include => [ :status, :project, :tracker, :priority ],
                                                 :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.updated_on DESC")
  end

  def users_by_role(limit = 100)
    @users_by_role = Hash.new do |h, size|
      h[size] = if size > 0
                  sql_string = all_roles.map do |r|
                    %Q{ (Select users.*, member_roles.role_id from users
                        JOIN members on users.id = members.user_id
                        JOIN member_roles on member_roles.member_id = members.id
                        WHERE members.project_id = #{ project.id } AND member_roles.role_id = #{ r.id }
                        LIMIT #{ size } ) }
                  end.join(" UNION ALL ")

                  User.find_by_sql(sql_string).group_by(&:role_id).inject({}) do |hash, (role_id, users)|
                    hash[all_roles.detect{ |r| r.id == role_id.to_i }] = users
                    hash
                  end
                else
                  project.users_by_role
                end

    end

    @users_by_role[limit]
  end

  def count_users_by_role
    @count_users_per_role ||= begin
                                sql_string = all_roles.map do |r|
                                  %Q{ (Select COUNT(users.id) AS count, member_roles.role_id AS role_id from users
                                      JOIN members on users.id = members.user_id
                                      JOIN member_roles on member_roles.member_id = members.id
                                      WHERE members.project_id = #{ project.id } AND member_roles.role_id = #{ r.id }
                                      GROUP BY (member_roles.role_id)) }
                                end.join(" UNION ALL ")

                                role_count = {}

                                ActiveRecord::Base.connection.execute(sql_string).each do |entry|
                                  if entry.is_a?(Hash)
                                    # MySql
                                    count = entry['count'].to_i
                                    role_id = entry['role_id'].to_i
                                  else
                                    # Postgresql
                                    count = entry.first.to_i
                                    role_id = entry.last.to_i
                                  end

                                  role_count[all_roles.detect{ |r| r.id == role_id }] = count if count > 0
                                end

                                role_count
                              end
  end

  def all_roles
    @all_roles = Role.all
  end

  def total_hours
    if User.current.allowed_to?(:view_time_entries, project) ||
       # granted, this is a dirty hack
       Redmine::Plugin.installed?(:redmine_costs) && User.current.allowed_to?(:view_own_time_entries, project)

      @total_hours ||= TimeEntry.visible.sum(:hours, :include => :project, :conditions => subproject_condition).to_f
    end
  end

  def project
    @project
  end

  def user
    @user
  end

  def blocks
    @blocks ||= {
      'top' => overview.top,
      'left' => overview.left,
      'right' => overview.right,
      'hidden' => overview.hidden
    }
  end

  def block_options
    @block_options = []
    BLOCKS.each {|k, v| @block_options << [l("my.blocks.#{v}", :default => [v, v.to_s.humanize]), k.dasherize]}
    @block_options << [l(:label_custom_element), :custom_element]
  end

  def overview
    @overview ||= MyProjectsOverview.find_or_create_by_project_id(project.id)
  end

  def attachments
    @attachments = overview.attachments || []
  end

  private

  def subproject_condition
    @subproject_condition ||= project.project_condition(Setting.display_subprojects_issues?)
  end

  def find_user
    @user = User.current
  end

  def default_breadcrumb
    l(:label_overview)
  end

  def jump_to_project_menu_item
    if params[:jump]
      # try to redirect to the requested menu item
      redirect_to_project_menu_item(project, params[:jump]) && return
    end
  end
end

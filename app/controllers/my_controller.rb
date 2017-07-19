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

class MyController < ApplicationController
  include Concerns::PasswordConfirmation
  layout 'my'

  before_action :require_login
  before_action :check_password_confirmation,
                only: [:account],
                if: ->() { request.patch? }

  menu_item :account,             only: [:account]
  menu_item :settings,            only: [:settings]
  menu_item :password,            only: [:password]
  menu_item :access_token,        only: [:access_token]
  menu_item :mail_notifications,  only: [:mail_notifications]

  DEFAULT_BLOCKS = { 'issuesassignedtome'         => :label_assigned_to_me_work_packages,
                     'workpackagesresponsiblefor' => :label_responsible_for_work_packages,
                     'issuesreportedbyme'         => :label_reported_work_packages,
                     'issueswatched'              => :label_watched_work_packages,
                     'news'                       => :label_news_latest,
                     'calendar'                   => :label_calendar,
                     'timelog'                    => :label_spent_time
           }.freeze

  DEFAULT_LAYOUT = {  'left' => ['issuesassignedtome'],
                      'right' => ['issuesreportedbyme']
                   }.freeze

  DRAG_AND_DROP_CONTAINERS = ['top', 'left', 'right']

  verify xhr: true,
         only: [:add_block, :remove_block, :order_blocks]

  def self.available_blocks
    @available_blocks ||= DEFAULT_BLOCKS.merge(Redmine::Views::MyPage::Block.additional_blocks)
  end

  # Show user's page
  def index
    @user = User.current
    @blocks = get_current_layout
    render action: 'page', layout: 'base'
  end
  alias :page :index

  # Edit user's account
  def account
    @user = User.current
    @pref = @user.pref
    write_settings(redirect_to: :account)
  end

  # Edit user's settings
  def settings
    @user = User.current
    write_settings(redirect_to: :settings)
  end

  # Manage user's password
  def password
    @user = User.current  # required by "my" layout
    @username = @user.login
    redirect_if_password_change_not_allowed_for(@user)
  end

  # When making changes here, also check AccountController.change_password
  def change_password
    return render_404 if OpenProject::Configuration.disable_password_login?

    @user = User.current  # required by "my" layout
    @username = @user.login
    return if redirect_if_password_change_not_allowed_for(@user)
    if @user.check_password?(params[:password], update_legacy: false)
      @user.password = params[:new_password]
      @user.password_confirmation = params[:new_password_confirmation]
      @user.force_password_change = false
      if @user.save
        flash[:notice] = l(:notice_account_password_updated)
        redirect_to action: 'password'
        return
      end
    else
      flash.now[:error] = l(:notice_account_wrong_password)
    end
    # Render the username to hint to a user in case of a forced password change
    render 'my/password', locals: { show_user_name: @user.force_password_change }
  end

  # Administer access tokens
  def access_token
    @user = User.current
  end

  # Configure user's mail notifications
  def mail_notifications
    @user = User.current
    write_email_settings(redirect_to: :mail_notifications) if request.patch?
  end

  # Create a new feeds key
  def reset_rss_key
    if request.post?
      if User.current.rss_token
        User.current.rss_token.destroy
        User.current.reload
      end
      User.current.rss_key
      flash[:notice] = l(:notice_feeds_access_key_reseted)
    end
    redirect_to action: 'access_token'
  end

  def generate_rss_key
    if request.post?
      User.current.rss_key
      flash[:notice] = l(:notice_feeds_access_key_generated)
    end
    redirect_to action: 'access_token'
  end

  # Create a new API key
  def reset_api_key
    if request.post?
      if User.current.api_token
        User.current.api_token.destroy
        User.current.reload
      end
      User.current.api_key
      flash[:notice] = l(:notice_api_access_key_reseted)
    end
    redirect_to action: 'access_token'
  end

  def generate_api_key
    if request.post?
      User.current.api_key
      flash[:notice] = l(:notice_api_access_key_generated)
    end
    redirect_to action: 'access_token'
  end

  # User's page layout configuration
  def page_layout
    @user           = User.current
    @blocks         = get_current_layout
    @block_options  = []

    # We track blocks that will show up on the page. This is in order to have
    # them disabled in the blocks-to-add-to-page dropdown.
    blocks_on_page = get_current_layout.values.flatten

    MyController.available_blocks.each do |block, value|
      if blocks_on_page.include?(block)
        @block_options << [l("my.blocks.#{value}", default: [value, value.to_s.humanize]), block.dasherize, disabled: true]
      else
        @block_options << [l("my.blocks.#{value}", default: [value, value.to_s.humanize]), block.dasherize]
      end
    end
  end

  # Add a block to the user's page at the top.
  # params[:block] : id of the block to add
  #
  # Responds with a JS layout.
  def add_block
    @block = params[:block].to_s.underscore

    unless MyController.available_blocks.keys.include? @block
      render nothing: true
      return
    end

    @user  = User.current
    layout = get_current_layout

    # Remove if already present in a group.
    DRAG_AND_DROP_CONTAINERS.each { |f| (layout[f] ||= []).delete @block }

    # Add it on top.
    layout['top'].unshift @block

    # Save user preference.
    @user.pref[:my_page_layout] = layout
    @user.pref.save
  end

  # Remove a block from the user's `my` page.
  # params[:block] : id of the block to remove
  #
  # Responds with a JS layout.
  def remove_block
    @block = params[:block].to_s.underscore
    @user  = User.current

    # Remove block in all groups.
    layout = get_current_layout
    DRAG_AND_DROP_CONTAINERS.each { |f| (layout[f] ||= []).delete @block }

    # Save user preference.
    @user.pref[:my_page_layout] = layout
    @user.pref.save
  end

  def order_blocks
    @user = User.current

    layout = get_current_layout

    # A nil +params[source_ordered_children]+ means all elements within
    # +params['source']+ were dragged out elsewhere.
    layout[params['source']] = params['source_ordered_children'] || []

    layout[params['target']] = params['target_ordered_children']

    @user.pref[:my_page_layout] = layout
    @user.pref.save

    head :ok
  end

  def default_breadcrumb
    l(:label_my_account)
  end

  def show_local_breadcrumb
    true
  end

  private

  def redirect_if_password_change_not_allowed_for(user)
    unless user.change_password_allowed?
      flash[:error] = l(:notice_can_t_change_password)
      redirect_to action: 'account'
      return true
    end
    false
  end

  def write_email_settings(redirect_to:)
    update_service = UpdateUserEmailSettingsService.new(@user)
    if update_service.call(mail_notification: permitted_params.user[:mail_notification],
                           self_notified: params[:self_notified] == '1',
                           notified_project_ids: params[:notified_project_ids])
      flash[:notice] = l(:notice_account_updated)
      redirect_to(action: redirect_to)
    end
  end

  def write_settings(redirect_to:)
    if request.patch?
      @user.attributes = permitted_params.user
      @user.pref.attributes = if params[:pref].present?
                                permitted_params.pref
                              else
                                {}
                              end
      if @user.save
        @user.pref.save
        flash[:notice] = l(:notice_account_updated)
        redirect_to(action: redirect_to)
      end
    end
  end

  helper_method :has_tokens?

  def has_tokens?
    Setting.feeds_enabled? || Setting.rest_api_enabled?
  end

  def get_current_layout
    @user.pref[:my_page_layout] || DEFAULT_LAYOUT.dup
  end
end

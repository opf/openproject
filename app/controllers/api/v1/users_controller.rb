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

module Api
  module V1

    class UsersController < UsersController

      include ::Api::V1::ApiController

      def index
        sort_init 'login', 'asc'
        sort_update %w(login firstname lastname mail admin created_on last_login_on)

        scope = User
        scope = scope.in_group(params[:group_id].to_i) if params[:group_id].present?

        @status = params[:status] ? params[:status].to_i : 1
        c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])

        unless params[:name].blank?
          name = "%#{params[:name].strip.downcase}%"
          c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
        end

        @users =  scope.order(sort_clause)
                       .where(c.conditions)
                       .page(page_param)
                       .per_page(per_page_param)

        respond_to do |format|
          format.api
        end
      end

      def show
        # show projects based on current user visibility
        @memberships = @user.memberships.all(:conditions => Project.visible_by(User.current))

        events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
        @events_by_day = events.map(&:data).group_by(&:event_date)

        unless User.current.admin?
          if !(@user.active? || @user.registered?) || (@user != User.current  && @memberships.empty? && events.empty?)
            render_404
            return
          end
        end

        respond_to do |format|
          format.api
        end
      end

      def create
        @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
        @user.safe_attributes = params[:user]
        @user.admin = params[:user][:admin] || false
        @user.login = params[:user][:login]
        @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] if @user.change_password_allowed?

        if @user.save
          # TODO: Similar to My#account
          @user.pref.attributes = params[:pref]
          @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')
          @user.pref.save

          @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

          UserMailer.account_information(@user, params[:user][:password]).deliver if params[:send_information]

          respond_to do |format|
            format.api  { render :action => 'show', :status => :created, :location => user_url(@user) }
          end
        else
          @auth_sources = AuthSource.find(:all)
          # Clear password input
          @user.password = @user.password_confirmation = nil

          respond_to do |format|
            format.api  { render_validation_errors(@user) }
          end
        end
      end

      def update
        @user.admin = params[:user][:admin] if params[:user][:admin]
        @user.login = params[:user][:login] if params[:user][:login]
        @user.safe_attributes = params[:user].except(:login) # :login is protected
        if params[:user][:password].present? && @user.change_password_allowed?
          @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
        end
        # Was the account actived ? (do it before User#save clears the change)
        was_activated = (@user.status_change == [User::STATUSES[:registered], User::STATUSES[:active]])
        if @user.save
          # TODO: Similar to My#account
          @user.pref.attributes = params[:pref]
          @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')
          @user.pref.save

          @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

          if was_activated
            UserMailer.account_activated(@user).deliver
          elsif @user.active? && params[:send_information] && !params[:user][:password].blank? && @user.change_password_allowed?
            UserMailer.account_information(@user, params[:user][:password]).deliver
          end

          respond_to do |format|
            format.api  { head :ok }
          end
        else
          @auth_sources = AuthSource.find(:all)
          @membership ||= Member.new
          # Clear password input
          @user.password = @user.password_confirmation = nil

          respond_to do |format|
            format.api  { render_validation_errors(@user) }
          end
        end
      rescue ::ActionController::RedirectBackError
        redirect_to :controller => '/users', :action => 'edit', :id => @user
      end

      def destroy
        # as destroying users is a lengthy process we handle it in the background
        # and lock the account now so that no action can be performed with it
        @user.status = User::STATUSES[:locked]
        @user.save

        # TODO: use Delayed::Worker.delay_jobs = false in test environment as soon as
        # delayed job allows for it
        Rails.env.test? ?
          @user.destroy :
          @user.delay.destroy

        flash[:notice] = l('account.deleted')

        respond_to do |format|
          format.api  do
            head :ok
          end
        end
      end

    end
  end
end

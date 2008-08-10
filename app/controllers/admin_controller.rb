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

class AdminController < ApplicationController
  before_filter :require_admin

  helper :sort
  include SortHelper	

  def index
    @no_configuration_data = Redmine::DefaultData::Loader::no_data?
  end
	
  def projects
    sort_init 'name', 'asc'
    sort_update
    
    @status = params[:status] ? params[:status].to_i : 0
    conditions = nil
    conditions = ["status=?", @status] unless @status == 0
    
    @project_count = Project.count(:conditions => conditions)
    @project_pages = Paginator.new self, @project_count,
								per_page_option,
								params['page']								
    @projects = Project.find :all, :order => sort_clause,
                        :conditions => conditions,
						:limit  =>  @project_pages.items_per_page,
						:offset =>  @project_pages.current.offset

    render :action => "projects", :layout => false if request.xhr?
  end
  
  # Loads the default configuration
  # (roles, trackers, statuses, workflow, enumerations)
  def default_configuration
    if request.post?
      begin
        Redmine::DefaultData::Loader::load(params[:lang])
        flash[:notice] = l(:notice_default_data_loaded)
      rescue Exception => e
        flash[:error] = l(:error_can_t_load_default_data, e.message)
      end
    end
    redirect_to :action => 'index'
  end
  
  def test_email
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      @test = Mailer.deliver_test(User.current)
      flash[:notice] = l(:notice_email_sent, User.current.mail)
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to :controller => 'settings', :action => 'edit', :tab => 'notifications'
  end
  
  def info
    @db_adapter_name = ActiveRecord::Base.connection.adapter_name
    @flags = {
      :default_admin_changed => User.find(:first, :conditions => ["login=? and hashed_password=?", 'admin', User.hash_password('admin')]).nil?,
      :file_repository_writable => File.writable?(Attachment.storage_path),
      :rmagick_available => Object.const_defined?(:Magick)
    }
    @plugins = Redmine::Plugin.registered_plugins
  end  
end

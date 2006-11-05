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

class IssuesController < ApplicationController
  layout 'base', :except => :export_pdf
  before_filter :find_project, :authorize

  helper :custom_fields
  include CustomFieldsHelper
  helper :ifpdf
  include IfpdfHelper

  def show
    @status_options = @issue.status.workflows.find(:all, :include => :new_status, :conditions => ["role_id=? and tracker_id=?", self.logged_in_user.role_for_project(@project.id), @issue.tracker.id]).collect{ |w| w.new_status } if self.logged_in_user
    @custom_values = @issue.custom_values.find(:all, :include => :custom_field)
  end
  
  def export_pdf
    @custom_values = @issue.custom_values.find(:all, :include => :custom_field)
    @options_for_rfpdf ||= {}
    @options_for_rfpdf[:file_name] = "#{@project.name}_#{@issue.long_id}.pdf"
  end

  def edit
    @priorities = Enumeration::get_values('IPRI')
    if request.get?
      @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| @issue.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x, :customized => @issue) }
    else
      begin
        # Retrieve custom fields and values
        @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue, :value => params["custom_fields"][x.id.to_s]) }
        @issue.custom_values = @custom_values
        @issue.attributes = params[:issue]
        if @issue.save
          flash[:notice] = l(:notice_successful_update)
          redirect_to :action => 'show', :id => @issue
        end
      rescue ActiveRecord::StaleObjectError
        # Optimistic locking exception
        flash[:notice] = l(:notice_locking_conflict)
      end
    end		
  end
  
  def add_note
    unless params[:history][:notes].empty?
      @history = @issue.histories.build(params[:history])
      @history.author_id = self.logged_in_user.id if self.logged_in_user
      @history.status = @issue.status
      if @history.save
        flash[:notice] = l(:notice_successful_update)
        Mailer.deliver_issue_add_note(@history) if Permission.find_by_controller_and_action(@params[:controller], @params[:action]).mail_enabled?
        redirect_to :action => 'show', :id => @issue
        return
      end
    end
    show
    render :action => 'show'
  end

  def change_status
    @history = @issue.histories.build(params[:history])	
    @status_options = @issue.status.workflows.find(:all, :conditions => ["role_id=? and tracker_id=?", self.logged_in_user.role_for_project(@project.id), @issue.tracker.id]).collect{ |w| w.new_status } if self.logged_in_user
    if params[:confirm]
      begin
        @history.author_id = self.logged_in_user.id if self.logged_in_user
        @issue.status = @history.status
        @issue.fixed_version_id = (params[:issue][:fixed_version_id])
        @issue.assigned_to_id = (params[:issue][:assigned_to_id])
        @issue.lock_version = (params[:issue][:lock_version])
        if @issue.save
          flash[:notice] = l(:notice_successful_update)
          Mailer.deliver_issue_change_status(@issue) if Permission.find_by_controller_and_action(@params[:controller], @params[:action]).mail_enabled?
          redirect_to :action => 'show', :id => @issue
        end
      rescue ActiveRecord::StaleObjectError
        # Optimistic locking exception
        flash[:notice] = l(:notice_locking_conflict)
      end
    end    
    @assignable_to = @project.members.find(:all, :include => :user).collect{ |m| m.user }
  end

  def destroy
    @issue.destroy
    redirect_to :controller => 'projects', :action => 'list_issues', :id => @project
  end

  def add_attachment
    # Save the attachment
    if params[:attachment][:file].size > 0
      @attachment = @issue.attachments.build(params[:attachment])      
      @attachment.author_id = self.logged_in_user.id if self.logged_in_user
      @attachment.save
    end
    redirect_to :action => 'show', :id => @issue
  end

  def destroy_attachment
    @issue.attachments.find(params[:attachment_id]).destroy
    redirect_to :action => 'show', :id => @issue
  end

  # Send the file in stream mode
  def download
    @attachment = @issue.attachments.find(params[:attachment_id])
    send_file @attachment.diskfile, :filename => @attachment.filename
  end

private
  def find_project
    @issue = Issue.find(params[:id], :include => [:project, :tracker, :status, :author, :priority, :category])
    @project = @issue.project
  end  
end

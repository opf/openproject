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

class IssuesController < ApplicationController
  layout 'base', :except => :export_pdf
  before_filter :find_project, :authorize

  helper :custom_fields
  include CustomFieldsHelper
  helper :ifpdf
  include IfpdfHelper
  helper :issue_relations
  include IssueRelationsHelper

  def show
    @status_options = @issue.status.find_new_statuses_allowed_to(logged_in_user.role_for_project(@project), @issue.tracker) if logged_in_user
    @custom_values = @issue.custom_values.find(:all, :include => :custom_field)
    @journals_count = @issue.journals.count
    @journals = @issue.journals.find(:all, :include => [:user, :details], :limit => 15, :order => "#{Journal.table_name}.created_on desc")
  end
  
  def history
    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on desc")
    @journals_count = @journals.length  
  end
  
  def export_pdf
    @custom_values = @issue.custom_values.find(:all, :include => :custom_field)
    @options_for_rfpdf ||= {}
    @options_for_rfpdf[:file_name] = "#{@project.name}_#{@issue.id}.pdf"
  end

  def edit
    @priorities = Enumeration::get_values('IPRI')
    if request.get?
      @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| @issue.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x, :customized => @issue) }
    else
      begin
        @issue.init_journal(self.logged_in_user)
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
    unless params[:notes].empty?
      journal = @issue.init_journal(self.logged_in_user, params[:notes])
      if @issue.save
        flash[:notice] = l(:notice_successful_update)
        Mailer.deliver_issue_edit(journal) if Permission.find_by_controller_and_action(params[:controller], params[:action]).mail_enabled?
        redirect_to :action => 'show', :id => @issue
        return
      end
    end
    show
    render :action => 'show'
  end

  def change_status
    @status_options = @issue.status.find_new_statuses_allowed_to(logged_in_user.role_for_project(@project), @issue.tracker) if logged_in_user
    @new_status = IssueStatus.find(params[:new_status_id])
    if params[:confirm]
      begin
        journal = @issue.init_journal(self.logged_in_user, params[:notes])
        @issue.status = @new_status
        if @issue.update_attributes(params[:issue])
          # Save attachments
          params[:attachments].each { |file|
            next unless file.size > 0
            a = Attachment.create(:container => @issue, :file => file, :author => logged_in_user)            
            journal.details << JournalDetail.new(:property => 'attachment',
                                                 :prop_key => a.id,
                                                 :value => a.filename) unless a.new_record?
          } if params[:attachments] and params[:attachments].is_a? Array
        
          flash[:notice] = l(:notice_successful_update)
          Mailer.deliver_issue_edit(journal) if Permission.find_by_controller_and_action(params[:controller], params[:action]).mail_enabled?
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
    # Save the attachments
    @attachments = []
    journal = @issue.init_journal(self.logged_in_user)
    params[:attachments].each { |file|
      next unless file.size > 0
      a = Attachment.create(:container => @issue, :file => file, :author => logged_in_user)
      @attachments << a unless a.new_record?
      journal.details << JournalDetail.new(:property => 'attachment',
                                           :prop_key => a.id,
                                           :value => a.filename) unless a.new_record?
    } if params[:attachments] and params[:attachments].is_a? Array
    journal.save if journal.details.any?
    Mailer.deliver_attachments_add(@attachments) if !@attachments.empty? and Permission.find_by_controller_and_action(params[:controller], params[:action]).mail_enabled?
    redirect_to :action => 'show', :id => @issue
  end

  def destroy_attachment
    a = @issue.attachments.find(params[:attachment_id])
    a.destroy
    journal = @issue.init_journal(self.logged_in_user)
    journal.details << JournalDetail.new(:property => 'attachment',
                                         :prop_key => a.id,
                                         :old_value => a.filename)
    journal.save
    redirect_to :action => 'show', :id => @issue
  end

  # Send the file in stream mode
  def download
    @attachment = @issue.attachments.find(params[:attachment_id])
    send_file @attachment.diskfile, :filename => @attachment.filename
  rescue
    render_404
  end

private
  def find_project
    @issue = Issue.find(params[:id], :include => [:project, :tracker, :status, :author, :priority, :category])
    @project = @issue.project
    @html_title = "#{@project.name} - #{@issue.tracker.name} ##{@issue.id}"
  rescue ActiveRecord::RecordNotFound
    render_404
  end  
end

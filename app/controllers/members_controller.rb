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

class MembersController < ApplicationController
  before_filter :find_member, :except => [:new, :autocomplete_for_member]
  before_filter :find_project, :only => [:new, :autocomplete_for_member]
  before_filter :authorize

  def new
    members = []
    if params[:member] && request.post?
      attrs = params[:member].dup
      if (user_ids = attrs.delete(:user_ids))
        user_ids.each do |user_id|
          members << Member.new(attrs.merge(:user_id => user_id))
        end
      else
        members << Member.new(attrs)
      end
      @project.members << members
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }
      format.js { 
        render(:update) {|page| 
          page.replace_html "tab-content-members", :partial => 'projects/settings/members'
          members.each {|member| page.visual_effect(:highlight, "member-#{member.id}") }
        }
      }
    end
  end
  
  def edit
    if request.post? and @member.update_attributes(params[:member])
  	 respond_to do |format|
        format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }
        format.js { 
          render(:update) {|page| 
            page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            page.visual_effect(:highlight, "member-#{@member.id}")
          }
        }
      end
    end
  end

  def destroy
    if request.post? && @member.deletable?
      @member.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }
      format.js { render(:update) {|page| page.replace_html "tab-content-members", :partial => 'projects/settings/members'} }
    end
  end
  
  def autocomplete_for_member
    @principals = Principal.active.like(params[:q]).find(:all, :limit => 100) - @project.principals
    render :layout => false
  end

private
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_member
    @member = Member.find(params[:id]) 
    @project = @member.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

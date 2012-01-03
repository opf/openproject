#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class MembersController < ApplicationController
  model_object Member
  before_filter :find_model_object, :except => [:new, :autocomplete_for_member]
  before_filter :find_project_from_association, :except => [:new, :autocomplete_for_member]
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
      if members.present? && members.all? {|m| m.valid? }

        format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }

        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            page << 'hideOnLoad()'
            members.each {|member| page.visual_effect(:highlight, "member-#{member.id}") }
          }
        }
      else

        format.js {
          render(:update) {|page|
            errors = members.collect {|m|
              m.errors.full_messages
            }.flatten.uniq

            page.alert(l(:notice_failed_to_save_members, :errors => errors.join(', ')))
          }
        }

      end
    end
  end

  def edit
    if request.post? and @member.update_attributes(params[:member])
  	 respond_to do |format|
        format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            page << 'hideOnLoad()'
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
      format.js { render(:update) {|page|
          page.replace_html "tab-content-members", :partial => 'projects/settings/members'
          page << 'hideOnLoad()'
        }
      }
    end
  end

  def autocomplete_for_member
    @principals = Principal.active.like(params[:q]).find(:all, :limit => 100) - @project.principals
    render :layout => false
  end

end

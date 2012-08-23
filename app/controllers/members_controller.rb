#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
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
    if params[:member]
      members = new_members_from_params
      @project.members << members
    end

    respond_to do |format|
      if members.present? && members.all? {|m| m.valid? }

        format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }

        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            page.insert_html :top, "tab-content-members", content_tag(:div, l(:notice_successful_create),
                                                                      :class => "flash notice")
            page << 'hideOnLoad()'
          }
        }
      else
        format.js {
          render(:update) {|page|
            if params[:member]
              page.insert_html :top, "tab-content-members", :partial => "members/member_errors", :locals => {:member => members.first}
            else
              page.insert_html :top, "tab-content-members", content_tag(:div,
                                                                          content_tag(:ul,
                                                                          content_tag(:li,
                                                                          content_tag(:a, l(:error_check_user_and_role)))),
                                                                        :class => "errorExplanation", :id => "errorExplanation")
            end
            }
        }
      end
    end
  end

  def edit
    if request.post? and
      member = update_member_from_params and
      member.save

  	 respond_to do |format|
        format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project, :page => params[:page] }
        format.js {
          render(:update) { |page|
            if params[:membership]
              @user = member.user
              page.replace_html "tab-content-memberships", :partial => 'users/memberships'
            else
              page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            end
            page << 'hideOnLoad()'
            page.visual_effect(:highlight, "member-#{@member.id}") unless Member.find_by_id(@member.id).nil?
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
    roles = Role.find_all_givable
    available_principals = @project.possible_members(params[:q], 100)

    render :partial => 'members/autocomplete_for_member', :locals => { :available_principals => available_principals, :roles => roles }
  end

  private

  def new_members_from_params
    members = []

    attrs = params[:member].dup
    user_ids = if attrs[:user_ids].present?
                 attrs.delete(:user_ids)
               elsif attrs[:user_id].present?
                 [attrs.delete(:user_id)]
               else
                 []
               end
    roles = Role.find_all_by_id(attrs.delete(:role_ids))

    user_ids.each do |user_id|
      member = Member.new attrs
      member.roles = roles
      member.user_id = user_id
      members << member
    end

    members
  end

  def update_member_from_params
    # this way, mass assignment is considered and all updates happen in one transaction (autosave)
    attrs = params[:member].dup
    attrs.merge! params[:membership].dup if params[:membership].present?
    attrs.delete(:id)

    role_ids = attrs.delete(:role_ids).map(&:to_i).select{ |i| i > 0 }
    roles = Role.find_all_by_id(role_ids)

    # Keep inherited roles
    role_ids += @member.member_roles.select { |mr| !mr.inherited_from.nil? }.collect(&:role_id)

    new_role_ids = role_ids - @member.role_ids
    # Add new roles
    new_role_ids.each { |id| @member.member_roles.build.tap { |r| r.role_id = id } }
    # Remove roles (Rails' #role_ids= will not trigger MemberRole#on_destroy)
    member_roles_to_destroy = @member.member_roles.select { |mr| !role_ids.include?(mr.role_id) }
    if member_roles_to_destroy.any?
      member_roles_to_destroy.each(&:mark_for_destruction)
      Watcher.prune(:user => @member.principal, :project => @member.project)
    end

    @member.attributes = attrs
    @member
  end
end

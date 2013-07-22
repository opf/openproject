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

class MembersController < ApplicationController
  model_object Member
  before_filter :find_model_object_and_project, :except => [:autocomplete_for_member]
  before_filter :find_project, :only => [:autocomplete_for_member]
  before_filter :authorize

  TAB_SCRIPTS = <<JS
    hideOnLoad();
    init_members_cb();
JS

  def create
    if params[:member]
      members = new_members_from_params
      @project.members << members
    end
    respond_to do |format|
      if members.present? && members.all? {|m| m.valid? }
        flash.now.notice = l(:notice_successful_create)

        format.html { redirect_to settings_project_path(@project, :tab => 'members') }

        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            page.insert_html :top, "tab-content-members", render_flash_messages

            page << TAB_SCRIPTS
          }
        }
      else
        format.js {
          render(:update) {|page|
            if params[:member]
              page.insert_html :top, "tab-content-members", :partial => "members/member_errors", :locals => {:member => members.first}
            else
              page.insert_html :top, "tab-content-members", :partial => "members/common_error", :locals => {:message => l(:error_check_user_and_role)}
            end
            }
        }
      end
    end
  end

  def update
    if member = update_member_from_params and
      member.save

  	 respond_to do |format|
        format.html { redirect_to :controller => '/projects', :action => 'settings', :tab => 'members', :id => @project, :page => params[:page] }
        format.js {
          render(:update) { |page|
            if params[:membership]
              @user = member.user
              page.replace_html "tab-content-memberships", :partial => 'users/memberships'
            else
              page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            end
            page << TAB_SCRIPTS
            page.visual_effect(:highlight, "member-#{@member.id}") unless Member.find_by_id(@member.id).nil?
          }
        }
      end
    end
  end

  def destroy
    if @member.deletable?
      @member.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => '/projects', :action => 'settings', :tab => 'members', :id => @project }
      format.js { render(:update) {|page|
          page.replace_html "tab-content-members", :partial => 'projects/settings/members'
          page << TAB_SCRIPTS
        }
      }
    end
  end

  def autocomplete_for_member
    size = params[:page_limit].to_i || 10
    page = params[:page]

    if page
      page = page.to_i
      @principals = Principal.paginate_scope!(Principal.search_scope_without_project(@project, params[:q]),
                        { :page => page, :page_limit => size })
      # we always get all the items on a page, so just check if we just got the last
      @more = @principals.total_pages > page
      @total = @principals.total_entries
    else
      @principals = Principal.possible_members(params[:q], 100) - @project.principals
    end

    respond_to do |format|
      format.json
      format.html {
        if request.xhr?
          partial = "members/autocomplete_for_member"
        else
          partial = "members/member_form"
        end
        render :partial => partial,
               :locals => { :project => @project,
                            :principals => @principals,
                            :roles => Role.find_all_givable }
      }
    end
  end

  private

  def new_members_from_params
    members = []

    attrs = params[:member].dup
    user_ids = possibly_seperated_ids_for_entity(attrs, :user)
    roles = Role.find_all_by_id(possibly_seperated_ids_for_entity(attrs, :role))

    user_ids.each do |user_id|
      member = Member.new attrs
      # workaround due to mass-assignment protected member_roles.role_id
      member.member_roles << roles.collect {|r| MemberRole.new :role => r }
      member.user_id = user_id
      members << member
    end
    # most likely wrong user input, use a dummy member for error handling
    if !members.present? && roles.present?
      members = [Member.new(attrs.merge({ :member_roles => roles.collect {|r| MemberRole.new :role => r } }))]
    end
    members
  end

  def each_comma_seperated(array, &block)
    array.each do |elem|
      if elem.to_s.match /\d(,\d)*/
        array += block.call(array.delete(elem))
      end
    end
    return array
  end

  def transform_array_of_comma_seperated_ids(array)
    return array unless array.present?
    each_comma_seperated(array) do |elem|
      elem.to_s.split(",").map(&:to_i)
    end
  end

  def possibly_seperated_ids_for_entity(array, entity = :user)
    if !array[:"#{entity}_ids"].nil?
      transform_array_of_comma_seperated_ids(array.delete(:"#{entity}_ids"))
    elsif (!array[:"#{entity}_id"].nil?) && ((id = array.delete(:"#{entity}_id")).present?)
      [id]
    else
      []
    end
  end


  def update_member_from_params
    # this way, mass assignment is considered and all updates happen in one transaction (autosave)
    attrs = params[:member].except(:user_id)
    attrs.merge! params[:membership].dup if params[:membership].present?
    attrs.delete(:project_id)

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

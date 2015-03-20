#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

class MembersController < ApplicationController
  model_object Member
  before_filter :find_model_object_and_project, except: [:autocomplete_for_member, :paginate_users]
  before_filter :find_project, only: [:autocomplete_for_member, :paginate_users]
  before_filter :authorize

  include Pagination::Controller
  paginate_model User
  search_for User, :search_in_project
  search_options_for User, lambda { |_| { project: @project } }

  @@scripts = ['hideOnLoad', 'init_members_cb']

  def self.add_tab_script(script)
    @@scripts.unshift(script)
  end

  def create
    if params[:member]
      members = new_members_from_params
      @project.members << members
    end
    respond_to do |format|
      if members.present? && members.all?(&:valid?)
        flash.now.notice = l(:notice_successful_create)

        format.html { redirect_to settings_project_path(@project, tab: 'members') }

        format.js do
          @pagination_url_options = { controller: 'projects', action: 'settings', id: @project }
          render(:update) do |page|
            page.replace_html 'tab-content-members', partial: 'projects/settings/members'
            page.insert_html :top, 'tab-content-members', render_flash_messages

            page << MembersController.tab_scripts
          end
        end
      else
        format.js do
          @pagination_url_options = { controller: 'projects', action: 'settings', id: @project }
          render(:update) do |page|
            if params[:member]
              page.insert_html :top, 'tab-content-members', partial: 'members/member_errors', locals: { member: members.first }
            else
              page.insert_html :top, 'tab-content-members', partial: 'members/common_error', locals: { message: l(:error_check_user_and_role) }
            end
          end
        end
      end
    end
  end

  def update
    member = update_member_from_params
    if member.save
      flash.now.notice = l(:notice_successful_update)
    end

    respond_to do |format|
      format.html { redirect_to controller: '/projects', action: 'settings', tab: 'members', id: @project, page: params[:page] }
      format.js do
        @pagination_url_options = { controller: 'projects', action: 'settings', id: @project }

        render(:update) do |page|
          if params[:membership]
            @user = member.user
            page.replace_html 'tab-content-memberships', partial: 'users/memberships'
          else
            page.replace_html 'tab-content-members', partial: 'projects/settings/members'
          end
          page.insert_html :top, 'tab-content-members', render_flash_messages
          page << MembersController.tab_scripts
          page.visual_effect(:highlight, "member-#{@member.id}") unless Member.find_by_id(@member.id).nil?
        end
      end
    end
  end

  def destroy
    if @member.deletable?
      @member.destroy
      flash.now.notice = l(:notice_successful_delete)
    end
    respond_to do |format|
      format.html { redirect_to controller: '/projects', action: 'settings', tab: 'members', id: @project }
      format.js do
        @pagination_url_options = { controller: 'projects', action: 'settings', id: @project }
        render(:update) do |page|
          page.replace_html 'tab-content-members', partial: 'projects/settings/members'
          page.insert_html :top, 'tab-content-members', render_flash_messages
          page << MembersController.tab_scripts
        end
      end
    end
  end

  def autocomplete_for_member
    size = params[:page_limit].to_i || 10
    page = params[:page]

    if page
      page = page.to_i
      @principals = Principal.paginate_scope!(Principal.search_scope_without_project(@project, params[:q]),
                                              page: page, page_limit: size)
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
          partial = 'members/autocomplete_for_member'
        else
          partial = 'members/member_form'
        end
        render partial: partial,
               locals: { project: @project,
                         principals: @principals,
                         roles: Role.find_all_givable }
      }
    end
  end

  private

  def self.tab_scripts
    @@scripts.join('(); ') + '();'
  end

  def new_members_from_params
    user_ids = possibly_seperated_ids_for_entity(params[:member], :user)
    roles = Role.find_all_by_id(possibly_seperated_ids_for_entity(params[:member], :role))

    new_member = lambda do |user_id|
      Member.new(permitted_params.member).tap do |member|
        member.user_id = user_id if user_id
      end
    end

    members = user_ids.map do |user_id|
      new_member.call(user_id)
    end
    # most likely wrong user input, use a dummy member for error handling
    if !members.present? && roles.present?
      members << new_member.call(nil)
    end
    members
  end

  def each_comma_seperated(array, &block)
    array.map do |e|
      if e.to_s.match /\d(,\d)*/
        block.call(e)
      else
        e
      end
    end.flatten
  end

  def transform_array_of_comma_seperated_ids(array)
    return array unless array.present?
    each_comma_seperated(array) do |elem|
      elem.to_s.split(',').map(&:to_i)
    end
  end

  def possibly_seperated_ids_for_entity(array, entity = :user)
    if !array[:"#{entity}_ids"].nil?
      transform_array_of_comma_seperated_ids(array[:"#{entity}_ids"])
    elsif !array[:"#{entity}_id"].nil? && (id = array[:"#{entity}_id"]).present?
      [id]
    else
      []
    end
  end

  def update_member_from_params
    # this way, mass assignment is considered and all updates happen in one transaction (autosave)
    attrs = permitted_params.member.dup
    attrs.merge! permitted_params.membership.dup if params[:membership].present?

    if attrs.include? :role_ids
      role_ids = attrs.delete(:role_ids).map(&:to_i).select { |i| i > 0 }
      @member.assign_roles(role_ids)
    end
    @member.assign_attributes(attrs)
    @member
  end
end

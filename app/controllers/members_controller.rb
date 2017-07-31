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

class MembersController < ApplicationController
  model_object Member
  before_action :find_model_object_and_project, except: [:autocomplete_for_member, :paginate_users]
  before_action :find_project_by_project_id, only: [:autocomplete_for_member, :paginate_users]
  before_action :authorize

  include Pagination::Controller
  paginate_model User
  search_for User, :search_in_project
  search_options_for User, lambda { |*| { project: @project } }

  include CellsHelper

  @@scripts = ['hideOnLoad', 'init_members_cb']

  def self.add_tab_script(script)
    @@scripts.unshift(script)
  end

  def index
    set_index_data!
  end

  def create
    if params[:member]
      members = new_members_from_params
      @project.members << members
    end

    if members.present? && members.all?(&:valid?)
      flash[:notice] = members_added_notice members

      redirect_to project_members_path(project_id: @project, status: 'all')
    else
      if members.present? && params[:member]
        @member = members.first
      else
        flash[:error] = t(:error_check_user_and_role)
      end

      set_index_data!

      respond_to do |format|
        format.html { render 'index' }
      end
    end
  end

  def update
    member = update_member_from_params

    if member.save
      flash[:notice] = l(:notice_successful_update)
    else
      # only possible message is about choosing at least one role
      flash[:error] = member.errors.full_messages.first
    end

    redirect_to project_members_path(project_id: @project,
                                     page: params[:page],
                                     per_page: params[:per_page])
  end

  def destroy
    if @member.deletable?
      if @member.disposable?
        flash.notice = I18n.t(:notice_member_deleted, user: @member.principal.name)

        @member.user.destroy
      else
        flash.notice = I18n.t(:notice_member_removed, user: @member.principal.name)

        @member.destroy
      end
    end

    redirect_to project_members_path(project_id: @project)
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

    @email = suggest_invite_via_email? current_user,
                                       params[:q],
                                       (@principals | @project.principals)

    respond_to do |format|
      format.json
      format.html do
        render partial: 'members/autocomplete_for_member',
               locals: { project: @project,
                         principals: @principals,
                         roles: Role.find_all_givable }
      end
    end
  end

  private

  def authorize_for(controller, action)
    current_user.allowed_to?({ controller: controller, action: action }, @project)
  end

  def members_table_options(roles)
    {
      project: @project,
      available_roles: roles,
      authorize_update: authorize_for('members', 'update')
    }
  end

  def members_filter_options(roles)
    groups = Group.all.sort
    status = Members::UserFilterCell.status_param(params)

    {
      groups: groups,
      roles: roles,
      status: status,
      clear_url: project_members_path(@project),
      project: @project
    }
  end

  def suggest_invite_via_email?(user, query, principals)
    user.admin? && # only admins may add new users via email
      query =~ mail_regex &&
      principals.none? { |p| p.mail == query || p.login == query } &&
      query # finally return email
  end

  def mail_regex
    /\A\S+@\S+\.\S+\z/
  end

  def self.tab_scripts
    @@scripts.join('(); ') + '();'
  end

  def set_index_data!
    set_roles_and_principles!

    @is_filtered = Members::UserFilterCell.filtered? params
    @members = index_members
    @members_table_options = members_table_options @roles
    @members_filter_options = members_filter_options @roles
  end

  def set_roles_and_principles!
    @roles = Role.find_all_givable
    # Check if there is at least one principal that can be added to the project
    @principals_available = @project.possible_members('', 1)
  end

  def index_members
    filters = params.slice(:name, :group_id, :role_id, :status)
    filters[:project_id] = @project.id.to_s

    @members = Member
               .where(id: Members::UserFilterCell.filter(filters))
               .includes(:roles, :principal, :member_roles)
  end

  def new_members_from_params
    roles = Role.where(id: possibly_seperated_ids_for_entity(params[:member], :role))

    if roles.present?
      user_ids = invite_new_users possibly_seperated_ids_for_entity(params[:member], :user)
      members = user_ids.map { |user_id| new_member user_id }

      # most likely wrong user input, use a dummy member for error handling
      if !members.present? && roles.present?
        members << new_member(nil)
      end

      members
    else
      # Pick a user that exists but can't be chosen.
      # We only want the missing role error message.
      dummy = new_member User.anonymous.id

      [dummy]
    end
  end

  def new_member(user_id)
    Member.new(permitted_params.member).tap do |member|
      member.user_id = user_id if user_id
    end
  end

  def invite_new_users(user_ids)
    user_ids.map do |id|
      if id.to_i == 0 && id.present? # we've got an email - invite that user
        # only admins can invite new users
        if current_user.admin?
          # The invitation can pretty much only fail due to the user already
          # having been invited. So look them up if it does.
          user = UserInvitation.invite_new_user(email: id) ||
            User.find_by_mail(id)

          user.id if user
        end
      else
        id
      end
    end.compact
  end

  def each_comma_seperated(array, &block)
    array.map { |e|
      if e.to_s.match /\d(,\d)*/
        block.call(e)
      else
        e
      end
    }.flatten
  end

  def transform_array_of_comma_seperated_ids(array)
    return array unless array.present?
    each_comma_seperated(array) do |elem|
      elem.to_s.split(',')
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

  def members_added_notice(members)
    if members.size == 1
      l(:notice_member_added, name: members.first.name)
    else
      l(:notice_members_added, number: members.size)
    end
  end
end

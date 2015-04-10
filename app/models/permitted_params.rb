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

class PermittedParams < Struct.new(:params, :current_user)
  # This class intends to provide a method for all params hashes coming from the
  # client and that are used for mass assignment.
  #
  # As such, please make it a deliberate decision to whitelist attributes.
  #
  # This implementation depends on the strong_parameters gem. For further
  # information see here: https://github.com/rails/strong_parameters
  #
  #
  # A method should look like the following:
  #
  # def name_of_the_params_key_referenced
  #   params.require(:name_of_the_params_key_referenced).permit(list_of_whitelisted_params)
  # end
  #
  #
  # A controller could use a permitted_params method like this
  #
  # model_instance.attributes = permitted_params.name_of_the_params_key_referenced
  #
  # instead of doing something like this which will not work anymore once the
  # model is protected:
  #
  # model_instance.attributes = params[:name_of_the_params_key_referenced]
  #
  #
  # A model will need the following module included in order to be protected by
  # strong_params
  #
  # include ActiveModel::ForbiddenAttributesProtection

  def self.permit(key, *params)
    raise(ArgumentError, "no permitted params are configured for #{key}") unless permitted_attributes.has_key?(key)

    permitted_attributes[key].concat(params)
  end

  def auth_source
    params.require(:auth_source).permit(*self.class.permitted_attributes[:auth_source])
  end

  def board
    params.require(:board).permit(*self.class.permitted_attributes[:board])
  end

  def board?
    params[:board] ? board : nil
  end

  def board_move
    params.require(:board).permit(*self.class.permitted_attributes[:move_to])
  end

  def color
    params.require(:color).permit(*self.class.permitted_attributes[:color])
  end

  def color_move
    params.require(:color).permit(*self.class.permitted_attributes[:move_to])
  end

  def custom_field
    params.require(:custom_field).permit(*self.class.permitted_attributes[:custom_field])
  end

  def custom_field_type
    params.require(:type)
  end

  def enumeration_type
    params.require(:type)
  end

  def enumeration
    permitted_params = params.require(:enumeration).permit(*self.class.permitted_attributes[:enumeration])

    permitted_params.merge!(custom_field_values(:enumeration))

    permitted_params
  end

  def group
    params.require(:group).permit(*self.class.permitted_attributes[:group])
  end

  def group_membership
    params.permit(*self.class.permitted_attributes[:group_membership])
  end

  def new_work_package(args = {})
    permitted = permitted_attributes(:new_work_package, args)

    permitted_params = params.require(:work_package).permit(*permitted)

    permitted_params.merge!(custom_field_values(:work_package))

    permitted_params
  end

  def member
    params.require(:member).permit(*self.class.permitted_attributes[:member])
  end

  def planning_element_type
    params.require(:planning_element_type).permit(*self.class.permitted_attributes[:planning_element_type])
  end

  def planning_element_type_move
    params.require(:planning_element_type).permit(*self.class.permitted_attributes[:move_to])
  end

  def planning_element(args = {})
    permitted = permitted_attributes(:planning_element, args)

    permitted_params = params.require(:planning_element).permit(*permitted)

    permitted_params.merge!(custom_field_values(:planning_element))

    permitted_params
  end

  def project_type
    params.require(:project_type).permit(*self.class.permitted_attributes[:project_type])
  end

  def project_type_move
    params.require(:project_type).permit(*self.class.permitted_attributes[:move_to])
  end

  def query
    # there is a weird bug in strong_parameters gem which makes the permit call
    # on the sort_criteria pattern return the sort_criteria-hash contents AND
    # the sort_criteria hash itself (again with content) in the same hash.
    # Here we try to circumvent this
    p = params.require(:query).permit(*self.class.permitted_attributes[:query])
    p[:sort_criteria] = params.require(:query).permit(sort_criteria: { '0' => [], '1' => [], '2' => [] })
    p[:sort_criteria].delete :sort_criteria
    p
  end

  def role
    params.require(:role).permit(*self.class.permitted_attributes[:role])
  end

  def role?
    params[:role] ? role : nil
  end

  def status
    params.require(:status).permit(*self.class.permitted_attributes[:status])
  end

  alias :update_work_package :new_work_package

  def user
    permitted_params = params.require(:user).permit(*self.class.permitted_attributes[:user])
    permitted_params.merge!(custom_field_values(:user))

    permitted_params
  end

  def user_register_via_omniauth
    permitted_params = params.require(:user) \
                       .permit(:login, :firstname, :lastname, :mail, :language)
    permitted_params.merge!(custom_field_values(:user))

    permitted_params
  end

  def user_update_as_admin(external_authentication, change_password_allowed)
    # Found group_ids in safe_attributes and added them here as I
    # didn't know the consequences of removing these.
    # They were not allowed on create.
    user_create_as_admin(external_authentication, change_password_allowed, [group_ids: []])
  end

  def user_create_as_admin(external_authentication, change_password_allowed, additional_params = [])
    if current_user.admin?
      additional_params << :auth_source_id unless external_authentication
      additional_params << :force_password_change if change_password_allowed

      allowed_params = self.class.permitted_attributes[:user] + \
                       additional_params + \
                       [:admin, :login]

      permitted_params = params.require(:user).permit(*allowed_params)
      permitted_params.merge!(custom_field_values(:user))

      permitted_params
    else
      params.require(:user).permit
    end
  end

  def type
    params.require(:type).permit(*self.class.permitted_attributes[:type])
  end

  def type_move
    params.require(:type).permit(*self.class.permitted_attributes[:move_to])
  end

  def work_package
    params.require(:work_package).permit(:subject,
                                         :description,
                                         :start_date,
                                         :due_date,
                                         :note,
                                         :planning_element_type_id,
                                         :planning_element_status_comment,
                                         :planning_element_status_id,
                                         :parent_id,
                                         :responsible_id,
                                         :lock_version)
  end

  def wiki_page_rename
    permitted = permitted_attributes(:wiki_page)

    params.require(:page).permit(*permitted)
  end

  def wiki_page
    permitted = permitted_attributes(:wiki_page)

    permitted_params = params.require(:content).require(:page).permit(*permitted)

    permitted_params
  end

  def wiki_content
    params.require(:content).permit(*self.class.permitted_attributes[:wiki_content])
  end

  protected

  def custom_field_values(key)
    # a hash of arbitrary values is not supported by strong params
    # thus we do it by hand
    values = params.require(key)[:custom_field_values] || {}

    # only permit values following the schema
    # 'id as string' => 'value as string'
    values.reject! { |k, v| k.to_i < 1 || !v.is_a?(String) }

    values.empty? ?
      {} :
      { 'custom_field_values' => values }
  end

  def permitted_attributes(key, additions = {})
    merged_args = { params: params, current_user: current_user }.merge(additions)

    self.class.permitted_attributes[key].map do |permission|
      if permission.respond_to?(:call)
        permission.call(merged_args)
      else
        permission
      end
    end.compact
  end

  def self.permitted_attributes
    @whitelisted_params ||= {
      auth_source: [
        :name,
        :host,
        :port,
        :tls,
        :account,
        :account_password,
        :base_dn,
        :onthefly_register,
        :attr_login,
        :attr_firstname,
        :attr_lastname,
        :attr_mail],
      board: [
        :name,
        :description],
      color: [
        :name,
        :hexcode,
        :move_to],
      custom_field: [
        :editable,
        :field_format,
        :is_filter,
        :is_for_all,
        :is_required,
        :max_length,
        :min_length,
        :move_to,
        :name,
        :possible_values,
        :regexp,
        :searchable,
        :visible,
        translations_attributes: [
          :_destroy,
          :default_value,
          :id,
          :locale,
          :name,
          :possible_values],
        type_ids: []],
      enumeration: [
        :active,
        :is_default,
        :move_to,
        :name,
        :reassign_to_id],
      group: [
        :lastname],
      group_membership: [
        :membership_id,
        membership: [
          :project_id,
          role_ids: []]],
      member: [
        role_ids: []],
      new_work_package: [
        # attributes common with :planning_element below
        :assigned_to_id,
        { attachments: [:file, :description] },
        :category_id,
        :description,
        :done_ratio,
        :due_date,
        :estimated_hours,
        :fixed_version_id,
        :parent_id,
        :priority_id,
        :responsible_id,
        :start_date,
        :status_id,
        :type_id,
        :subject,
        Proc.new do |args|
          # avoid costly allowed_to? if the param is not there at all
          if args[:params]['work_package'] &&
             args[:params]['work_package'].has_key?('watcher_user_ids') &&
             args[:current_user].allowed_to?(:add_work_package_watchers, args[:project])

            { watcher_user_ids: [] }
          end
        end,
        Proc.new do |args|
          # avoid costly allowed_to? if the param is not there at all
          if args[:params]['work_package'] &&
             args[:params]['work_package'].has_key?('time_entry') &&
             args[:current_user].allowed_to?(:log_time, args[:project])

            { time_entry: [:hours, :activity_id, :comments] }
          end
        end,
        # attributes unique to :new_work_package
        :journal_notes,
        :lock_version],
      planning_element: [
        # attributes common with :new_work_package above
        :assigned_to_id,
        { attachments: [:file, :description] },
        :category_id,
        :description,
        :done_ratio,
        :due_date,
        :estimated_hours,
        :fixed_version_id,
        :parent_id,
        :priority_id,
        :responsible_id,
        :start_date,
        :status_id,
        :type_id,
        :subject,
        Proc.new do |args|
          # avoid costly allowed_to? if the param is not there at all
          if args[:params]['planning_element'] &&
             args[:params]['planning_element'].has_key?('watcher_user_ids') &&
             args[:current_user].allowed_to?(:add_work_package_watchers, args[:project])

            { watcher_user_ids: [] }
          end
        end,
        Proc.new do |args|
          # avoid costly allowed_to? if the param is not there at all
          if args[:params]['planning_element'] &&
             args[:params]['planning_element'].has_key?('time_entry') &&
             args[:current_user].allowed_to?(:log_time, args[:project])

            { time_entry: [:hours, :activity_id, :comments] }
          end
        end,
        # attributes unique to planning_element
        :note,
        :planning_element_status_comment,
        custom_fields: [ # json
          :id,
          :value,
          custom_field: [ # xml
            :id,
            :value]]],
      planning_element_type: [
        :name,
        :in_aggregation,
        :is_milestone,
        :is_default,
        :color_id],
      project_type: [
        :name,
        :allows_association,
        type_ids: [],
        reported_project_status_ids: []],
      query: [
        :name,
        :display_sums,
        :is_public,
        :group_by],
      role: [
        :name,
        :assignable,
        :move_to,
        permissions: []],
      status: [
        :name,
        :default_done_ratio,
        :is_closed,
        :is_default,
        :move_to],
      type: [
        :name,
        :is_in_roadmap,
        :in_aggregation,
        :is_milestone,
        :is_default,
        :color_id,
        project_ids: [],
        custom_field_ids: []],
      user: [
        :firstname,
        :lastname,
        :mail,
        :mail_notification,
        :language,
        :custom_fields],
      wiki_page: [
        :title,
        :parent_id,
        :redirect_existing_links],
      wiki_content: [
        :comments,
        :text,
        :lock_version],
      move_to: [:move_to]
    }
  end

  private

  ## Add attributes as permitted attributes (only to be used by the plugins plugin)
  #
  # attributes should be given as a Hash in the form
  # {:key => [:param1, :param2]}
  def self.add_permitted_attributes(attributes)
    # Make sure the permitted attributes are cached in @whitelisted_params
    permitted_attributes

    # Check no unsupported parameters are attempted to be whitelisted (they're ignored)
    unknown_keys = (attributes.keys - @whitelisted_params.keys)
    if unknown_keys.size > 0
      Rails.logger.warn(
        "Attempt to whitelist attributes for unknown keys: #{unknown_keys}, ignoring them.")
    end

    attributes.each_pair do |key, attrs|
      @whitelisted_params[key] += attrs unless unknown_keys.include?(key)
    end
  end
end

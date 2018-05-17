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

require 'permitted_params/allowed_settings'

class PermittedParams
  # This class intends to provide a method for all params hashes coming from the
  # client and that are used for mass assignment.
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
  # model_instance.METHOD_USING_ASSIGMENT = permitted_params.name_of_the_params_key_referenced
  #
  attr_reader :params, :current_user

  def initialize(params, current_user)
    @params = params
    @current_user = current_user
  end

  def self.permit(key, *params)
    unless permitted_attributes.has_key?(key)
      raise(ArgumentError, "no permitted params are configured for #{key}")
    end

    permitted_attributes[key].concat(params)
  end

  def attribute_help_text
    params.require(:attribute_help_text).permit(*self.class.permitted_attributes[:attribute_help_text])
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
    params.fetch(:type, {})
  end

  def group
    params.require(:group).permit(*self.class.permitted_attributes[:group])
  end

  def group_membership
    params.permit(*self.class.permitted_attributes[:group_membership])
  end

  def update_work_package(args = {})
    # used to be called new_work_package with an alias to update_work_package
    permitted = permitted_attributes(:new_work_package, args)

    permitted_params = params.require(:work_package).permit(*permitted)

    permitted_params = permitted_params.merge(custom_field_values(:work_package))

    permitted_params
  end

  def member
    params.require(:member).permit(*self.class.permitted_attributes[:member])
  end

  def planning_element_type
    params.require(:planning_element_type)
      .permit(*self.class.permitted_attributes[:planning_element_type])
  end

  def planning_element_type_move
    params.require(:planning_element_type)
      .permit(*self.class.permitted_attributes[:move_to])
  end

  def planning_element(args = {})
    permitted = permitted_attributes(:planning_element, args)

    permitted_params = params.require(:planning_element).permit(*permitted)

    permitted_params = permitted_params.merge(custom_field_values(:planning_element))

    permitted_params
  end

  def project_type
    params.require(:project_type).permit(*self.class.permitted_attributes[:project_type])
  end

  def projects_type_ids
    params.require(:project).require(:type_ids).map(&:to_i).select { |x| x > 0 }
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
    p[:sort_criteria] = params
                        .require(:query)
                        .permit(sort_criteria: { '0' => [], '1' => [], '2' => [] })
    p[:sort_criteria].delete :sort_criteria
    p
  end

  def calendar_filter
    keys =  Query.registered_filters.map(&:key)
    op_keys = keys_whitelisted_by_list(params["op"], keys)
    v_keys = keys_whitelisted_by_list(params["v"], keys).map { |f| { f => [] } }

    params.permit(:project_id,
                  :month,
                  :year,
                  f: [],
                  op: op_keys,
                  v: v_keys)
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

  def settings
    permitted_params = params.require(:settings).permit
    all_valid_keys = AllowedSettings.all

    permitted_params.merge(params[:settings].to_unsafe_hash.slice(*all_valid_keys))
  end

  def user
    permitted_params = params.require(:user).permit(*self.class.permitted_attributes[:user])
    permitted_params = permitted_params.merge(custom_field_values(:user))

    permitted_params
  end

  def user_register_via_omniauth
    permitted_params = params
                       .require(:user)
                       .permit(:login, :firstname, :lastname, :mail, :language)
    permitted_params = permitted_params.merge(custom_field_values(:user))

    permitted_params
  end

  def user_update_as_admin(external_authentication, change_password_allowed)
    # Found group_ids in safe_attributes and added them here as I
    # didn't know the consequences of removing these.
    # They were not allowed on create.
    user_create_as_admin(external_authentication, change_password_allowed, [group_ids: []])
  end

  def user_create_as_admin(external_authentication,
                           change_password_allowed,
                           additional_params = [])
    if current_user.admin?
      additional_params << :auth_source_id unless external_authentication
      additional_params << :force_password_change if change_password_allowed

      allowed_params = self.class.permitted_attributes[:user] + \
                       additional_params + \
                       [:admin, :login]

      permitted_params = params.require(:user).permit(*allowed_params)
      permitted_params = permitted_params.merge(custom_field_values(:user))

      permitted_params
    else
      params.require(:user).permit
    end
  end

  def type(args = {})
    permitted = permitted_attributes(:type, args)
    params.require(:type).permit(*permitted)
  end

  def type_move
    params.require(:type).permit(*self.class.permitted_attributes[:move_to])
  end

  def timelog
    params.permit(:period,
                  :period_type,
                  :from,
                  :to,
                  criterias: [])
  end

  def search
    params.permit(*self.class.permitted_attributes[:search])
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

  def timeline
    # Options here will be empty. This is just initializing it.
    whitelist = params.require(:timeline).permit(:name, options: {})

    if params['timeline'].has_key?('options')
      params['timeline']['options'].each do |key, _value|
        whitelist['options'][key] = params['timeline']['options'][key]
      end
    end

    whitelist.permit!
  end

  def pref
    params.require(:pref).permit(:hide_mail, :time_zone, :impaired, :theme,
                                 :comments_sorting, :warn_on_leaving_unsaved,
                                 :auto_hide_popups)
  end

  def project
    whitelist = params.require(:project).permit(:name,
                                                :description,
                                                :is_public,
                                                :responsible_id,
                                                :identifier,
                                                :project_type_id,
                                                custom_fields: [],
                                                work_package_custom_field_ids: [],
                                                type_ids: [],
                                                enabled_module_names: [])

    unless params[:project][:custom_field_values].nil?
      # Permit the sub-hash for custom_field_values
      whitelist[:custom_field_values] = params[:project][:custom_field_values].permit!
    end

    whitelist
  end

  def time_entry
    permitted_params = params.fetch(:time_entry, {}).permit(
      :hours, :comments, :work_package_id, :activity_id, :spent_on)

    permitted_params.merge(custom_field_values(:time_entry, required: false))
  end

  def news
    params.require(:news).permit(:title, :summary, :description)
  end

  def category
    params.require(:category).permit(:name, :assigned_to_id)
  end

  def version
    # `version_settings_attributes` is from a plugin. Unfortunately as it stands
    # now it is less work to do it this way than have the plugin override this
    # method. We hopefully will change this in the future.
    permitted_params = params.fetch(:version, {}).permit(:name,
                                                         :description,
                                                         :effective_date,
                                                         :due_date,
                                                         :start_date,
                                                         :wiki_page_title,
                                                         :status,
                                                         :sharing,
                                                         version_settings_attributes: [:id,
                                                                                       :display,
                                                                                       :project_id])

    permitted_params.merge(custom_field_values(:version, required: false))
  end

  def comment
    params.require(:comment).permit(:commented, :author, :comments)
  end

  # `params.fetch` and not `require` because the update controller action associated
  # with this is doing multiple things, therefore not requiring a message hash
  # all the time.
  def message(instance = nil)
    if instance && current_user.allowed_to?(:edit_messages, instance.project)
      params.fetch(:message, {}).permit(:subject, :content, :board_id, :locked, :sticky)
    else
      params.fetch(:message, {}).permit(:subject, :content, :board_id)
    end
  end

  def attachments
    params.permit(attachments: [:file, :description])['attachments']
  end

  def enumerations
    acceptable_params = [:active, :is_default, :move_to, :name, :reassign_to_i,
                         :parent_id, :custom_field_values, :reassign_to_id]

    whitelist = ActionController::Parameters.new

    # Sometimes we receive one enumeration, sometimes many in params, hence
    # the following branching.
    if params[:enumerations].present?
      params[:enumerations].each do |enum, _value|
        enum.tap do
          whitelist[enum] = {}
          acceptable_params.each do |param|
            # We rely on enum being an integer, an id that is. This will blow up
            # otherwise, which is fine.
            next if params[:enumerations][enum][param].nil?
            whitelist[enum][param] = params[:enumerations][enum][param]
          end
        end
      end
    else
      params[:enumeration].each do |key, _value|
        whitelist[key] = params[:enumeration][key]
      end
    end

    whitelist.permit!
  end

  def watcher
    params.require(:watcher).permit(:watchable, :user, :user_id)
  end

  def reply
    params.require(:reply).permit(:content, :subject)
  end

  def wiki
    params.require(:wiki).permit(:start_page)
  end

  def reporting
    params.fetch(:reporting, {}).permit(:reporting_to_project_id,
                                        :reported_project_status_id,
                                        :reported_project_status_comment)
  end

  def repository_diff
    params.permit(:rev, :rev_to, :project, :action, :controller)
  end

  def membership
    params.require(:membership).permit(*self.class.permitted_attributes[:membership])
  end

  protected

  def custom_field_values(key, required: true)
    # a hash of arbitrary values is not supported by strong params
    # thus we do it by hand
    object = required ? params.require(key) : params.fetch(key, {})
    values = object[:custom_field_values] || ActionController::Parameters.new

    # only permit values following the schema
    # 'id as string' => 'value as string'
    values.reject! { |k, v| k.to_i < 1 || !v.is_a?(String) }

    values.empty? ? {} : { 'custom_field_values' => values.permit! }
  end

  def permitted_attributes(key, additions = {})
    merged_args = { params: params, current_user: current_user }.merge(additions)

    self.class.permitted_attributes[key].map { |permission|
      if permission.respond_to?(:call)
        permission.call(merged_args)
      else
        permission
      end
    }.compact
  end

  def self.permitted_attributes
    @whitelisted_params ||= begin
      params = {
        attribute_help_text: [
          :type,
          :attribute_name,
          :help_text
        ],
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
          :attr_mail,
          :attr_admin],
        board: [
          :name,
          :description],
        color: [
          :name,
          :hexcode,
          :move_to
        ],
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
          :default_value,
          :possible_values,
          :multi_value,
          { custom_options_attributes: %i(id value default_value position) },
          type_ids: []
        ],
        enumeration: [
          :active,
          :is_default,
          :move_to,
          :name,
          :reassign_to_id
        ],
        group: [
          :lastname
        ],
        membership: [
          :project_id,
          role_ids: []],
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
        search: [
          :q,
          :offset,
          :previous,
          :scope,
          :all_words,
          :titles_only,
          :work_packages,
          :news,
          :changesets,
          :wiki_pages,
          :messages,
          :projects,
          :submit
        ],
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
          custom_field_ids: []
        ],
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

      # Accept new parameters, defaulting to an empty array
      params.default = []
      params
    end
  end

  ## Add attributes as permitted attributes (only to be used by the plugins plugin)
  #
  # attributes should be given as a Hash in the form
  # {key: [:param1, :param2]}
  def self.add_permitted_attributes(attributes)
    attributes.each_pair do |key, attrs|
      permitted_attributes[key] += attrs
    end
  end

  def keys_whitelisted_by_list(hash, list)
    (hash || {})
      .keys
      .select { |k| list.any? { |whitelisted| whitelisted.to_s == k.to_s || whitelisted === k } }
  end
end

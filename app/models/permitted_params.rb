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

class PermittedParams < Struct.new(:params, :user)

  # This class intends to provide a method for all params hashes comming from the
  # client and that are used for mass assignment.
  #
  # As such, please make it a deliberate decission to whitelist attributes.
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

  def project_type
    params.require(:project_type).permit(*self.class.permitted_attributes[:project_type])
  end

  def project_type_move
    params.require(:project_type).permit(*self.class.permitted_attributes[:project_type_move])
  end

  def color
    params.require(:color).permit(*self.class.permitted_attributes[:color])
  end

  def color_move
    params.require(:color).permit(*self.class.permitted_attributes[:color_move])
  end

  def planning_element_type
    params.require(:planning_element_type).permit(*self.class.permitted_attributes[:planning_element_type])
  end

  def planning_element_type_move
    params.require(:planning_element_type).permit(*self.class.permitted_attributes[:planning_element_type_move])
  end

  def planning_element
    params.require(:planning_element).permit(*self.class.permitted_attributes[:planning_element])
  end

  def new_work_package(args = {})
    permitted = permitted_attributes(:new_work_package, args)

    permitted_params = params.require(:work_package).permit(*permitted)

    permitted_params.merge!(custom_field_values(:work_package))

    permitted_params
  end

  alias :update_work_package :new_work_package

  def user_update_as_admin
    if user.admin?
      permitted_params = params.require(:user).permit(:firstname,
                                                      :lastname,
                                                      :mail,
                                                      :mail_notification,
                                                      :language,
                                                      :custom_fields,
                                                      :identity_url,
                                                      :auth_source_id,
                                                      :force_password_change,
                                                      :group_ids => [])
      permitted_params.merge!(custom_field_values(:user))

      permitted_params
    else
      params.require(:user).permit()
    end
  end

  def type
    params.require(:type).permit(*self.class.permitted_attributes[:type])
  end

  def type_move
    params.require(:type).permit(*self.class.permitted_attributes[:type_move])
  end

  def work_package
    params.require(:work_package).permit(:subject,
                                         :description,
                                         :start_date,
                                         :end_date,
                                         :note,
                                         :planning_element_type_id,
                                         :planning_element_status_comment,
                                         :planning_element_status_id,
                                         :parent_id,
                                         :responsible_id)
  end

  protected

  def custom_field_values(key)
    # a hash of arbitrary values is not supported by strong params
    # thus we do it by hand
    values = params.require(key)[:custom_field_values] || {}

    # only permit values following the schema
    # 'id as string' => 'value as string'
    values.reject!{ |k, v| k.to_i < 1 || !v.is_a?(String) }

    values.empty? ?
      {} :
      { "custom_field_values" => values }
  end

  def permitted_attributes(key, additions = {})
    merged_args = { :params => params, :user => user }.merge(additions)

    self.class.permitted_attributes[:new_work_package].map do |permission|
      if permission.respond_to?(:call)
        permission.call(merged_args)
      else
        permission
      end
    end.compact
  end

  def self.permitted_attributes
    @whitelisted_params ||= {
                              :new_work_package => [
                                                     :subject,
                                                     :description,
                                                     :start_date,
                                                     :due_date,
                                                     :planning_element_type_id,
                                                     :parent_id,
                                                     :parent_id,
                                                     :assigned_to_id,
                                                     :responsible_id,
                                                     :type_id,
                                                     :fixed_version_id,
                                                     :estimated_hours,
                                                     :done_ratio,
                                                     :priority_id,
                                                     :category_id,
                                                     :status_id,
                                                     :notes,
                                                     { attachments: [:file, :description] },
                                                     Proc.new do |args|
                                                       # avoid costly allowed_to? if the param is not there at all
                                                       if args[:params]["work_package"].has_key?("watcher_user_ids") &&
                                                          args[:user].allowed_to?(:add_work_package_watchers, args[:project])

                                                         { :watcher_user_ids => [] }
                                                       end
                                                     end,
                                                     Proc.new do |args|
                                                       # avoid costly allowed_to? if the param is not there at all
                                                       if args[:params]["work_package"].has_key?("time_entry") &&
                                                          args[:user].allowed_to?(:log_time, args[:project])

                                                         { time_entry: [:hours, :activity_id, :comments] }
                                                       end
                                                     end
                                                   ],
                               :color_move => [:move_to],
                               :color => [
                                           :name,
                                           :hexcode,
                                           :move_to
                                         ],
                               :planning_element => [
                                                      :subject,
                                                      :description,
                                                      :start_date,
                                                      :due_date,
                                                      :note,
                                                      :planning_element_type_id,
                                                      :planning_element_status_comment,
                                                      :planning_element_status_id,
                                                      :parent_id,
                                                      :responsible_id
                                                    ],
                               :planning_element_type => [
                                                           :name,
                                                           :in_aggregation,
                                                           :is_milestone,
                                                           :is_default,
                                                           :color_id
                                                         ],
                               :planning_element_type_move => [:move_to],
                               :project_type_move => [:move_to],
                               :project_type => [
                                                  :name,
                                                  :allows_association,
                                                  :type_ids => [],
                                                  :reported_project_status_ids => []
                                                ],
                               :type => [
                                          :name,
                                          :is_in_roadmap,
                                          :in_aggregation,
                                          :is_milestone,
                                          :is_default,
                                          :color_id,
                                          :project_ids => [],
                                          :custom_field_ids => []
                                        ],
                               :type_move => [:move_to]
                            }
  end
end

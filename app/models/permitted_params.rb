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

  def project_type
    params.require(:project_type).permit(:name,
                                         :allows_association,
                                         # have to check whether this is correct
                                         # just copying over from model for now
                                         :planning_element_type_ids => [],
                                         :reported_project_status_ids => [])
  end

  def project_type_move
    params.require(:project_type).permit(:move_to)
  end

  def color
    params.require(:color).permit(:name,
                                  :hexcode,
                                  :move_to)
  end

  def color_move
    params.require(:color).permit(:move_to)
  end

  def planning_element_type
    params.require(:planning_element_type).permit(:name,
                                                  :in_aggregation,
                                                  :is_milestone,
                                                  :is_default,
                                                  :color_id)
  end

  def planning_element_type_move
    params.require(:planning_element_type).permit(:move_to)
  end

  def scenario
    params.require(:scenario).permit(:name,
                                     :description)
  end

  def planning_element
    params.require(:planning_element).permit(:subject,
                                             :description,
                                             :start_date,
                                             :end_date,
                                             { scenarios: [:id, :start_date, :end_date] },
                                             :note,
                                             :planning_element_type_id,
                                             :planning_element_status_comment,
                                             :planning_element_status_id,
                                             :parent_id,
                                             :responsible_id)
  end

  def user_update_as_admin
    if user.admin?
      params.require(:user).permit(:firstname,
                                   :lastname,
                                   :mail,
                                   :mail_notification,
                                   :language,
                                   :custom_field_values,
                                   :custom_fields,
                                   :identity_url,
                                   :auth_source_id,
                                   :force_password_change,
                                   :group_ids => [])
    else
      params.require(:user).permit()
    end
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
end

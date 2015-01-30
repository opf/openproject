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

class CopyProjectJob < Struct.new(:user_id,
                                  :source_project_id,
                                  :target_project_params,
                                  :enabled_modules,
                                  :associations_to_copy,
                                  :send_mails)
  include OpenProject::LocaleHelper

  def perform
    User.current = user

    target_project, errors = with_locale_for(user) do
      create_project_copy(source_project,
                          target_project_params,
                          enabled_modules,
                          associations_to_copy,
                          send_mails)
    end

    if target_project
      UserMailer.copy_project_succeeded(user, source_project, target_project, errors)
    else
      target_project_name = target_project_params[:name]

      UserMailer.copy_project_failed(user, source_project, target_project_name)
    end
  end

  private

  def user
    @user ||= User.find user_id
  end

  def source_project
    @project ||= Project.find source_project_id
  end

  def create_project_copy(source_project,
                          target_project_params,
                          enabled_modules,
                          associations_to_copy,
                          send_mails)
    target_project = nil
    errors = []

    UserMailer.with_deliveries(send_mails) do
      parent_id = target_project_params[:parent_id]
      target_project = Project.new.tap do |p|
        p.safe_attributes = target_project_params
        p.enabled_module_names = enabled_modules
      end

      if validate_parent_id(target_project, parent_id) && target_project.save
        target_project.set_allowed_parent!(parent_id) if parent_id

        target_project.copy_associations(source_project, only: associations_to_copy)

        # Project was created
        # But some objects might not have been copied due to validation failures
        error_objects = (target_project.compiled_errors.flatten + [target_project.errors]).flatten
        error_objects.each do |error_object|
          base = error_object.instance_variable_get(:@base)
          error_prefix = base.is_a?(Project) ? '' : "#{base.class.model_name.human} '#{base}': "

          error_object.full_messages.flatten.each do |error|
            errors << error_prefix + error
          end
        end
      else
        errors = target_project.errors.full_messages
        target_project = nil
      end
    end
  rescue ActiveRecord::RecordNotFound
  ensure
    return target_project, errors
  end

  # Validates parent_id param according to user's permissions
  # TODO: move it to Project model in a validation that depends on User.current
  def validate_parent_id(project, parent_id)
    return true if User.current.admin?
    if parent_id || project.new_record?
      parent = parent_id.blank? ? nil : Project.find_by_id(parent_id.to_i)
      unless project.allowed_parents.include?(parent)
        project.errors.add :parent_id, :invalid
        return false
      end
    end
    true
  end
end

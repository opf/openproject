#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CopyProjectJob < ApplicationJob
  queue_with_priority :low
  include OpenProject::LocaleHelper

  attr_reader :user_id,
              :source_project_id,
              :target_project_params,
              :target_project_name,
              :target_project,
              :errors,
              :associations_to_copy,
              :send_mails

  def perform(user_id:,
              source_project_id:,
              target_project_params:,
              associations_to_copy:,
              send_mails: false)
    # Needs refactoring after moving to activejob

    @user_id               = user_id
    @source_project_id     = source_project_id
    @target_project_params = target_project_params.with_indifferent_access
    @associations_to_copy  = associations_to_copy
    @send_mails            = send_mails

    User.current = user
    @target_project_name = target_project_params[:name]

    @target_project, @errors = with_locale_for(user) do
      create_project_copy
    end

    if target_project
      ProjectMailer.copy_project_succeeded(user, source_project, target_project, errors).deliver_now
    else
      ProjectMailer.copy_project_failed(user, source_project, target_project_name, errors).deliver_now
    end
  rescue StandardError => e
    logger.error { "Failed to finish copy project job: #{e} #{e.message}" }
    errors = [I18n.t('copy_project.failed_internal')]
    ProjectMailer.copy_project_failed(user, source_project, target_project_name, errors).deliver_now
  end

  private

  def user
    @user ||= User.find user_id
  end

  def source_project
    @project ||= Project.find source_project_id
  end

  def create_project_copy
    errors = []

    ProjectMailer.with_deliveries(send_mails) do
      service_call = copy_project_attributes
      target_project = service_call.result

      if service_call.success? && target_project.save
        errors = copy_project_associations(target_project)
      else
        service_call.errors.merge!(target_project.errors, nil)
        errors = service_call.errors.full_messages
        target_project = nil
        logger.error("Copying project fails with validation errors: #{errors.join("\n")}")
      end

      return target_project, errors
    end
  rescue ActiveRecord::RecordNotFound => e
    logger.error("Entity missing: #{e.message} #{e.backtrace.join("\n")}")
  rescue StandardError => e
    logger.error('Encountered an error when trying to copy project '\
                 "'#{source_project_id}' : #{e.message} #{e.backtrace.join("\n")}")
  ensure
    unless errors.empty?
      logger.error('Encountered an errors while trying to copy related objects for '\
                   "project '#{source_project_id}': #{errors.inspect}")
    end
  end

  def logger
    Rails.logger
  end

  def copy_project_attributes
    target_project = Project.copy_attributes(source_project)

    cleanup_target_project_attributes(target_project)
    cleanup_target_project_params

    Projects::SetAttributesService
      .new(user: user,
           model: target_project,
           contract_class: Projects::CopyContract,
           contract_options: { copied_from: source_project })
      .call(target_project_params)
  end

  def cleanup_target_project_params
    if (parent_id = target_project_params["parent_id"]) && (parent = Project.find_by(id: parent_id))
      target_project_params.delete("parent_id") unless user.allowed_to?(:add_subprojects, parent)
    end
  end

  def cleanup_target_project_attributes(target_project)
    if target_project.parent
      target_project.parent = nil unless user.allowed_to?(:add_subprojects, target_project.parent)
    end
  end

  def copy_project_associations(target_project)
    target_project.copy_associations(source_project, only: associations_to_copy)
    errors = []

    # Project was created
    # But some objects might not have been copied due to validation failures
    error_objects = project_errors(target_project)
    error_objects.each do |error_object|
      error_prefix = error_prefix_for(error_object)

      error_object.full_messages.flatten.each do |error|
        errors << error_prefix + error
      end
    end

    errors
  end

  def project_errors(project)
    (project.compiled_errors.flatten + [project.errors]).flatten
  end

  def error_prefix_for(error_object)
    base = error_object.instance_variable_get(:@base)
    base.is_a?(Project) ? '' : "#{base.class.model_name.human} '#{base}': "
  end
end

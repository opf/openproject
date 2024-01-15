#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class CopyProjectJob < ApplicationJob
  queue_with_priority :above_normal
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
      successful_status_update
      ProjectMailer.copy_project_succeeded(user, source_project, target_project, errors).deliver_later
    else
      failure_status_update
      ProjectMailer.copy_project_failed(user, source_project, target_project_name, errors).deliver_later
    end
  rescue StandardError => e
    logger.error { "Failed to finish copy project job: #{e} #{e.message}" }
    errors = [I18n.t('copy_project.failed_internal')]
    failure_status_update
    ProjectMailer.copy_project_failed(user, source_project, target_project_name, errors).deliver_later
  end

  def store_status?
    true
  end

  def updates_own_status?
    true
  end

  protected

  def title
    I18n.t(:label_copy_project)
  end

  private

  def successful_status_update
    payload = redirect_payload(url_helpers.project_url(target_project))
      .merge(hal_links(target_project))

    if errors.any?
      payload[:errors] = errors
    end

    upsert_status status: :success,
                  message: I18n.t('copy_project.succeeded', target_project_name: target_project.name),
                  payload:
  end

  def failure_status_update
    message = I18n.t('copy_project.failed', source_project_name: source_project.name)

    if errors
      message << ": #{errors.join("\n")}"
    end

    upsert_status status: :failure, message:
  end

  def hal_links(project)
    {
      _links: {
        project: {
          href: ::API::V3::Utilities::PathHelper::ApiV3Path.project(project.id),
          title: project.name
        }
      }
    }
  end

  def user
    @user ||= User.find user_id
  end

  def source_project
    @source_project ||= Project.find source_project_id
  end

  def create_project_copy
    errors = []

    ProjectMailer.with_deliveries(send_mails) do
      service_call = copy_project
      target_project = service_call.result
      errors = service_call.errors.full_messages

      # We assume the copying worked "successfully" if the project was saved
      unless target_project&.persisted?
        target_project = nil
        logger.error("Copying project fails with validation errors: #{errors.join("\n")}")
      end

      return target_project, errors
    end
  rescue ActiveRecord::RecordNotFound => e
    logger.error("Entity missing: #{e.message} #{e.backtrace.join("\n")}")
  rescue StandardError => e
    logger.error('Encountered an error when trying to copy project ' \
                 "'#{source_project_id}' : #{e.message} #{e.backtrace.join("\n")}")
  ensure
    unless errors.empty?
      logger.error('Encountered an errors while trying to copy related objects for ' \
                   "project '#{source_project_id}': #{errors.inspect}")
    end
  end

  def copy_project
    ::Projects::CopyService
      .new(source: source_project, user:)
      .call(copy_project_params)
  end

  def copy_project_params
    params = { target_project_params:, send_notifications: send_mails }
    params[:only] = associations_to_copy if associations_to_copy.present?

    params
  end

  def logger
    Rails.logger
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end
end

# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
  include OpenProject::LocaleHelper
  include GoodJob::ActiveJobExtensions::Batches

  queue_with_priority :above_normal

  # Again error handling pushing the branch costs up
  def perform(target_project_params:, associations_to_copy:, send_mails: false)
    User.current = user
    target_project_params = target_project_params.with_indifferent_access

    target_project, errors = with_locale_for(user) do
      create_project_copy(target_project_params, associations_to_copy, send_mails)
    end

    update_batch(target_project:, errors:, target_project_name: target_project_params[:name])

    if target_project
      successful_status_update(target_project, errors)
    else
      failure_status_update(errors)
    end
  rescue StandardError => e
    logger.error { "Failed to finish copy project job: #{e} #{e.message}" }
    errors = [I18n.t("copy_project.failed_internal")]
    update_batch(errors:)
    failure_status_update(errors)
  end

  def store_status? = true

  def updates_own_status? = true

  protected

  def title = I18n.t(:label_copy_project)

  private

  def update_batch(hash)
    batch.properties.merge!(hash)
    batch.save
  end

  def successful_status_update(target_project, errors)
    payload = redirect_payload(url_helpers.project_url(target_project)).merge(hal_links(target_project))

    if errors.any?
      payload[:errors] = errors
    end

    upsert_status status: :success,
                  message: I18n.t("copy_project.succeeded", target_project_name: target_project.name),
                  payload:
  end

  def failure_status_update(errors)
    message = I18n.t("copy_project.failed", source_project_name: source_project.name)

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

  def user = batch.properties[:user]

  def source_project = batch.properties[:source_project]

  # rubocop:disable Metrics/AbcSize
  # Most of the cost is from handling errors, we need to check what can be moved around / removed
  def create_project_copy(target_project_params, associations_to_copy, send_mails)
    errors = []

    ProjectMailer.with_deliveries(send_mails) do
      service_result = copy_project(target_project_params, associations_to_copy, send_mails)
      target_project = service_result.result
      errors = service_result.errors.full_messages

      # We assume the copying worked "successfully" if the project was saved
      if target_project&.persisted?
        return target_project, errors
      else
        logger.error("Copying project fails with validation errors: #{errors.join("\n")}")
        return nil, errors
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    logger.error("Entity missing: #{e.message} #{e.backtrace.join("\n")}")
    raise e
  rescue StandardError => e
    logger.error("Encountered an error when trying to copy project " \
                 "'#{source_project.id}' : #{e.message} #{e.backtrace.join("\n")}")
    raise e
  ensure
    if errors.any?
      logger.error("Encountered an errors while trying to copy related objects for " \
                   "project '#{source_project.id}': #{errors.inspect}")
    end
  end
  # rubocop:enable Metrics/AbcSize

  def copy_project(target_project_params, associations_to_copy, send_notifications)
    copy_service = ::Projects::CopyService.new(source: source_project, user:)
    result = copy_service.call({ target_project_params:, send_notifications:, only: Array(associations_to_copy) })

    enqueue_copy_project_folder_jobs(copy_service.state.copied_project_storages,
                                     copy_service.state.work_package_id_lookup,
                                     associations_to_copy)

    result
  end

  def enqueue_copy_project_folder_jobs(copied_storages, work_packages_map, only)
    return unless only.intersect?(%w[file_links storage_project_folders])

    Array(copied_storages).each do |storage_pair|
      batch.enqueue do
        Storages::CopyProjectFoldersJob
          .perform_later(source: storage_pair[:source], target: storage_pair[:target], work_packages_map:)
      end
    end
  end

  def logger = OpenProject.logger

  def url_helpers = OpenProject::StaticRouting::StaticUrlHelpers.new
end

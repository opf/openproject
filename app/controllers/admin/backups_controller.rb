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

class Admin::BackupsController < ApplicationController
  include PasswordConfirmation
  include ActionView::Helpers::TagHelper
  include BackupHelper

  layout 'admin'

  before_action :check_enabled
  before_action :authorize_global

  before_action :check_password_confirmation, only: %i[perform_token_reset]

  menu_item :backups

  def show
    @backup_token = Token::Backup.find_by user: current_user
    last_backup = find_backup user: current_user

    if last_backup
      @job_status_id = last_backup.job_status.job_id
      @last_backup_date = format_time(last_backup.updated_at)
      @last_backup_attachment_id = last_backup.attachments.first&.id
    end

    @may_include_attachments = may_include_attachments? ? "true" : "false"
  end

  def reset_token
    @backup_token = Token::Backup.find_by user: current_user
    @user = current_user
  end

  def perform_token_reset
    token = create_backup_token user: current_user

    token_reset_successful! token
  rescue StandardError => e
    token_reset_failed! e
  ensure
    redirect_to action: 'show'
  end

  def delete_token
    Token::Backup.where(user: current_user).destroy_all

    flash[:info] = t("backup.text_token_deleted")

    redirect_to action: 'show'
  end

  def default_breadcrumb
    t(:label_backup)
  end

  def show_local_breadcrumb
    true
  end

  def check_enabled
    render_404 unless OpenProject::Configuration.backup_enabled?
  end

  private

  def find_backup(status: :success, user: current_user)
    Backup
      .joins(:job_status)
      .where(job_status: { user:, status: })
      .last
  end

  def token_reset_successful!(token)
    notify_user_and_admins current_user, backup_token: token

    flash[:warning] = token_reset_flash_message token
  end

  def token_reset_flash_message(token)
    [
      t('my.access_token.notice_reset_token', type: 'Backup'),
      content_tag(:strong, token.plain_value),
      t('my.access_token.token_value_warning')
    ]
  end

  def token_reset_failed!(error)
    Rails.logger.error "Failed to reset user ##{current_user.id}'s Backup token: #{error}"

    flash[:error] = t('my.access_token.failed_to_reset_token', error: error.message)
  end

  def may_include_attachments?
    Backup.include_attachments? && Backup.attachments_size_in_bounds?
  end
end

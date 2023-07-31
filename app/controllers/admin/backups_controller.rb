#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  include BackupPreviewHelper
  include OmniauthConsentHelper

  layout 'admin'

  before_action :check_enabled
  before_action :authorize_global, except: %i[back]

  before_action :check_password_confirmation, only: %i[perform_token_reset], if: :check_password?
  before_action :request_consent, only: %i[perform_token_reset], unless: :check_password?

  skip_before_action :check_if_login_required, only: %i[back]

  menu_item :backups

  def index
    @backups = Backup.all
  end

  def default_breadcrumb
    if action_name == 'index'
      t('label_backup')
    else
      ActionController::Base.helpers.link_to(t('label_backup'), admin_backups_path)
    end
  end

  def show_local_breadcrumb
    true
  end

  def new
    @backup_token = Token::Backup.find_by user: current_user
    last_backup = find_backup user: current_user

    if last_backup
      @job_status_id = last_backup.job_status.job_id
      @last_backup_date = format_time(last_backup.updated_at)
      @last_backup_attachment_id = last_backup.attachments.first&.id
    end

    @may_include_attachments = may_include_attachments? ? "true" : "false"
  end

  def preview
    if RestoreBackupJob.preview_active? backup_id: params[:id]
      if Backup.find(params[:id]).job_status.status != "success"
        flash[:error] = I18n.t("backup_preview.restore.not_completed")

        return redirect_to admin_backups_path
      end

      return do_preview backup_id: params[:id]
    end

    @backup_token = Token::Backup.find_by user: current_user
    @backup = Backup.find params[:id]
    @job_status_id = @backup.job_status.job_id
  end

  def restore
    if RestoreBackupJob.preview_active?(backup_id: params[:id]) && !String(params[:reset]).to_bool
      if Backup.find(params[:id]).job_status.status != "success"
        flash[:error] = I18n.t("backup.restore.not_completed")

        return redirect_to admin_backups_path
      end

      return do_restore backup_id: params[:id]
    end

    @backup_token = Token::Backup.find_by user: current_user
    @backup = Backup.find params[:id]
    @job_status_id = @backup.job_status.job_id
  end

  def do_preview(backup_id:)
    backup = Backup.find backup_id
    schema = RestoreBackupJob.preview_schema_name backup_id: backup_id

    cookies.signed[:backup_preview] = backup.attributes
      .merge(schema: schema, previous_user_id: current_user.id)
      .symbolize_keys
      .to_yaml

    cookies.signed[:login_user_id] = get_schema_user_id schema

    redirect_to "/admin/backups/"
  end

  def do_restore(backup_id:)
    schema = RestoreBackupJob.preview_schema_name backup_id: backup_id

    cookies.signed[:login_user_id] = get_schema_user_id schema

    RestoreBackupJob.switch_database_to_restored_backup! backup_id: backup_id

    Setting._maintenance_mode = { enabled: false }

    redirect_to restored_admin_backups_path
  end

  def restored
    flash[:info] = I18n.t("backup.restore.complete")

    redirect_to home_path
  end

  def get_schema_user_id(schema)
    Apartment::Tenant.switch(schema) do
      if User.where(id: current_user.id).exists?
        current_user.id
      else
        User.active.admin.pluck(:id).first
      end
    end
  end

  def back
    if !backup_preview?
      flash[:error] = "No preview active"

      return redirect_back_or_default home_path
    end

    backup_id = backup_preview[:id]

    if RestoreBackupJob.preview_active?(backup_id: backup_id).blank?
      flash[:error] = "Not currently previewing anything"

      return redirect_to "/admin/backups/"
    end

    cookies.signed[:login_user_id] = backup_preview[:previous_user_id]

    Apartment::Tenant.switch(RestoreBackupJob.default_schema_name) do
      CloseBackupPreviewJob.perform_later backup_id
    end

    cookies.delete :backup_preview

    if String(params[:restore]).to_bool
      redirect_to restore_admin_backup_path(backup_id, reset: true)
    else
      redirect_to home_path
    end
  end

  def upload

  end

  def perform_upload
    backup = Backup.new creator: current_user, comment: params[:comment]
    backup.attachments.build file: params[:backup_file], author: current_user
    backup.save!

    backup.size_in_mb = (backup.attachments.first.filesize / 1024.0 / 1024.0).round(2)
    backup.save!

    JobStatus::Status.create(reference: backup, message: "imported", status: :success)

    flash[:info] = I18n.t("backup.notice_uploaded", comment: backup.comment)

    redirect_to "/admin/backups"
  end

  def destroy
    backup = Backup.find params[:id]

    backup.destroy!

    flash[:info] = I18n.t("backup.notice_deleted")

    redirect_to "/admin/backups/"
  end

  def reset_token
    return perform_token_reset if omniauth_consent_given?(current_user)

    @backup_token = Token::Backup.find_by user: current_user
    @user = current_user
  end

  def perform_token_reset
    token = create_backup_token user: current_user

    token_reset_successful! token
  rescue StandardError => e
    token_reset_failed! e
  ensure
    redirect_to action: 'new'
  end

  def delete_token
    Token::Backup.where(user: current_user).destroy_all

    flash[:info] = t("backup.text_token_deleted")

    redirect_to action: 'new'
  end

  def check_enabled
    render_404 unless OpenProject::Configuration.backup_enabled?
  end

  private

  def check_password?
    !current_user.uses_external_authentication?
  end

  def request_consent
    return false unless current_user.uses_external_authentication?

    request_omniauth_consent current_user
  end

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

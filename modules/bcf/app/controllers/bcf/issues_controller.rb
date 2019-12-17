#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module ::Bcf
  class IssuesController < BaseController
    include PaginationHelper
    include BcfWorkPackagesFilterHelper

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :import_canceled?

    before_action :check_file_param, only: %i[prepare_import]
    before_action :get_persisted_file, only: %i[perform_import configure_import]
    before_action :persist_file, only: %i[prepare_import]
    before_action :set_import_options, only: %i[perform_import]

    before_action :build_importer, only: %i[prepare_import configure_import perform_import]

    menu_item :work_packages

    def upload; end

    def index
      redirect_to action: :upload
    end

    def prepare_import
      render_next
    rescue StandardError => e
      flash[:error] = I18n.t('bcf.bcf_xml.import_failed', error: e.message)
      redirect_to action: :upload
    end

    def configure_import
      render_next
    rescue StandardError => e
      flash[:error] = I18n.t('bcf.bcf_xml.import_failed', error: e.message)
      redirect_to action: :upload
    end

    def perform_import
      begin
        results = @importer.import!(@import_options).flatten
        @issues = { successful: [], failed: [] }
        results.each do |issue|
          if issue.errors.present?
            @issues[:failed] << issue
          else
            @issues[:successful] << issue
          end
        end
      rescue StandardError => e
        flash[:error] = I18n.t('bcf.bcf_xml.import_failed', error: e.message)
      end

      @bcf_attachment.destroy
    end

    def redirect_to_bcf_issues_list
      redirect_to project_work_packages_bcf_issues_path(@project)
    end

    private

    def import_canceled?
      if %i[unknown_types_action
            unknown_statuses_action
            invalid_people_action
            unknown_mails_action
            non_members_action].map { |key| params.dig(:import_options, key) }.include? 'cancel'
        flash[:notice] = I18n.t('bcf.bcf_xml.import_canceled')
        redirect_to_bcf_issues_list
      end
    end

    def set_import_options
      @import_options = {
        unknown_types_action:          params.dig(:import_options, :unknown_types_action).presence      || "use_default",
        unknown_statuses_action:       params.dig(:import_options, :unknown_statuses_action).presence   || "use_default",
        unknown_priorities_action:     params.dig(:import_options, :unknown_priorities_action).presence || "use_default",
        invalid_people_action:         params.dig(:import_options, :invalid_people_action).presence     || "anonymize",
        unknown_mails_action:          params.dig(:import_options, :unknown_mails_action).presence      || 'invite',
        non_members_action:            params.dig(:import_options, :non_members_action).presence        || 'add',
        unknown_types_chose_ids:       params.dig(:import_options, :unknown_types_chose_ids)            || [],
        unknown_statuses_chose_ids:    params.dig(:import_options, :unknown_statuses_chose_ids)         || [],
        unknown_priorities_chose_ids:  params.dig(:import_options, :unknown_priorities_chose_ids)       || [],
        unknown_mails_invite_role_ids: params.dig(:import_options, :unknown_mails_invite_role_ids)      || [],
        non_members_add_role_ids:      params.dig(:import_options, :non_members_add_role_ids)           || []
      }
    end

    def render_next
      if render_config_unknown_types?
        render_config_unknown_types
      elsif render_config_unknown_statuses?
        render_config_unknown_statuses
      elsif render_config_unknown_priorities?
        render_config_unknown_priorities
      elsif render_config_invalid_people?
        render_config_invalid_people
      elsif render_config_unknown_mails?
        render_config_unknown_mails
      elsif render_config_non_members?
        render_config_non_members
      else
        render_diff_on_work_packages
      end
    end

    def render_diff_on_work_packages
      @listing = @importer.extractor_list
      if @listing.blank?
        raise(StandardError.new(I18n.t('bcf.exceptions.file_invalid')))
      end

      @issues = ::Bcf::Issue
                .includes(work_package: %i[status priority assigned_to])
                .where(uuid: @listing.map { |e| e[:uuid] }, project: @project)
      render 'bcf/issues/diff_on_work_packages'
    end

    def render_config_invalid_people
      render 'bcf/issues/configure_invalid_people'
    end

    def render_config_invalid_people?
      @importer.aggregations.invalid_people.present? && !params.dig(:import_options, :invalid_people_action).present?
    end

    def render_config_unknown_types
      render 'bcf/issues/configure_unknown_types'
    end

    def render_config_unknown_types?
      @importer.aggregations.unknown_types.present? && !params.dig(:import_options, :unknown_types_action).present?
    end

    def render_config_unknown_statuses
      render 'bcf/issues/configure_unknown_statuses'
    end

    def render_config_unknown_statuses?
      @importer.aggregations.unknown_statuses.present? && !params.dig(:import_options, :unknown_statuses_action).present?
    end

    def render_config_unknown_priorities?
      @importer.aggregations.unknown_priorities.present? && !params.dig(:import_options, :unknown_priorities_action).present?
    end

    def render_config_unknown_priorities
      render 'bcf/issues/configure_unknown_priorities'
    end

    def render_config_unknown_mails
      @roles = Role.givable
      render 'bcf/issues/configure_unknown_mails'
    end

    def render_config_unknown_mails?
      @importer.aggregations.unknown_mails.present? && !params.dig(:import_options, :unknown_mails_action).present?
    end

    def render_config_non_members
      @roles = Role.givable
      render 'bcf/issues/configure_non_members'
    end

    def render_config_non_members?
      @importer.aggregations.non_members.present? && !params.dig(:import_options, :non_members_action).present?
    end

    def build_importer
      @importer = ::OpenProject::Bcf::BcfXml::Importer.new @bcf_xml_file, @project, current_user: current_user
    end

    def get_persisted_file
      @bcf_attachment = Attachment.find_by! id: session[:bcf_file_id], author: current_user
      @bcf_xml_file = File.new @bcf_attachment.local_path
    rescue ActiveRecord::RecordNotFound
      render_404 'BCF file not found'
    end

    def persist_file
      @bcf_attachment = Attachment.create!(file: params[:bcf_file],
                                           description: params[:bcf_file].original_filename,
                                           author: current_user)
      @bcf_xml_file = File.new(@bcf_attachment.local_path)
      session[:bcf_file_id] = @bcf_attachment.id
    rescue StandardError => e
      flash[:error] = "Failed to persist BCF file: #{e.message}"
      redirect_to action: :upload
    end

    def check_file_param
      path = params[:bcf_file]&.path
      unless path && File.readable?(path)
        flash[:error] = I18n.t('bcf.bcf_xml.import_failed', error: 'File missing or not readable')
        redirect_to action: :upload
      end
    end
  end
end

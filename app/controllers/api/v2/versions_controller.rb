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

module Api
  module V2
    class VersionsController < ApplicationController
      include PaginationHelper

      include ::Api::V2::ApiController
      include ::Api::V2::Concerns::MultipleProjects

      Version = Struct.new(:id,
                           :name,
                           :description,
                           :project_id,
                           :status,
                           :start_date,
                           :effective_date,
                           :shared_with)

      rescue_from ActiveRecord::RecordNotFound, with: -> { render_404 }

      before_filter :find_all_projects_by_project_id
      accept_key_auth :index

      def index
        respond_to do |format|
          format.api
        end
      end

      private

      def find_single_project(version_scope = nil)
        find_project_by_project_id  unless performed?
        authorize                   unless performed?
        assign_versions([@project], version_scope) unless performed?
      end

      def find_multiple_projects(version_scope = nil)
        # find_project_by_project_id
        ids, identifiers = params[:project_id].split(/,/).map(&:strip).partition { |s| s =~ /\A\d*\z/ }
        ids = ids.map(&:to_i).sort
        identifiers = identifiers.sort

        load_multiple_projects(ids, identifiers)

        if !projects_contain_certain_ids_and_identifiers(ids, identifiers)
          # => not all projects could be found
          render_404
          return
        end

        filter_authorized_projects

        if @projects.blank?
          @versions = []
          return
        end

        assign_versions(@projects, version_scope)
      end

      # Filters
      def find_all_projects_by_project_id
        version_scope = nil

        if params[:project_id] && params[:ids]
          identifiers = params[:ids].split(/,/).map(&:strip).map(&:to_i)
          version_scope = ::Version.find_all_by_id(identifiers)
                          .map(&:id)
        end

        if params[:project_id] !~ /,/
          find_single_project version_scope
        else
          find_multiple_projects version_scope
        end
      end

      def assign_versions(projects, version_ids)
        projects_by_version = Hash.new { |h, k| h[k] = [] }

        projects.each do |project|
          project.shared_versions.each do |version|
            if version_ids.nil? || version_ids.include?(version.id)
              projects_by_version[version] << project unless projects_by_version[version].include? project
            end
          end
        end

        @versions = projects_by_version.each_with_object([]) do |(version, versions_projects), l|
          l << internal_version(version, versions_projects.map(&:id))
        end
      end

      def internal_version(version, shared_with)
        Version.new(version.id,
                    version.name,
                    version.description,
                    version.project_id,
                    version.status,
                    version.start_date,
                    version.effective_date,
                    Array.new(shared_with))
      end
    end
  end
end

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module WikiPagesExt
      # Standalone Grape API providing the wiki page endpoints introduced by
      # the `wiki_api` module. Mounted under Root to avoid conflicts with the
      # `:id` route parameter already declared by the core wiki_pages API.
      #
      # Endpoints:
      #
      #   GET    /api/v3/projects/:project_id/wiki_pages
      #   POST   /api/v3/projects/:project_id/wiki_pages
      #   GET    /api/v3/projects/:project_id/wiki_pages/tree
      #   GET    /api/v3/projects/:project_id/wiki_pages/search
      #
      #   PATCH  /api/v3/wiki_pages/:wp_id
      #   DELETE /api/v3/wiki_pages/:wp_id
      #   GET    /api/v3/wiki_pages/:wp_id/versions
      #   GET    /api/v3/wiki_pages/:wp_id/versions/:wp_version
      #   POST   /api/v3/wiki_pages/:wp_id/versions/:wp_version/restore
      #   POST   /api/v3/wiki_pages/:wp_id/lock
      #   POST   /api/v3/wiki_pages/:wp_id/unlock
      #   POST   /api/v3/wiki_pages/:wp_id/move
      #   POST   /api/v3/wiki_pages/:wp_id/copy
      class WikiAPI < ::API::OpenProjectAPI
        helpers ::API::Utilities::UrlPropsParsingHelper
        helpers ::API::V3::WikiPagesExt::WikiHelpers

        helpers do
          def load_wiki_page!(id)
            WikiPage.visible(current_user).find(id)
          end

          def render_page(page)
            ::API::V3::WikiPagesExt::WikiPageFullRepresenter
              .new(page, current_user:, embed_links: true)
          end

          def run_update!(page, attributes)
            call = ::WikiPages::UpdateService
                     .new(user: current_user,
                          contract_class: ::WikiPages::UpdateContract,
                          model: page)
                     .call(attributes)

            if call.success?
              render_page(call.result)
            else
              raise ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end
          end
        end

        # ---------------- Project-scoped collection ----------------

        resources :projects do
          route_param :project_id, type: Integer, desc: "Project id" do
            after_validation do
              @project = Project.visible(current_user).find(params[:project_id])
              authorize_in_project(:view_wiki_pages, project: @project)
              @wiki = ensure_wiki!(@project)
            end

            resources :wiki_pages do
              # GET /projects/:project_id/wiki_pages
              get do
                scope = @wiki.pages
                             .includes(:parent, :author, wiki: :project)
                             .order(:title)

                ::API::V3::WikiPagesExt::WikiPageCollectionRepresenter.new(
                  scope,
                  self_link: api_v3_paths.wiki_pages_by_project(@project.id),
                  page: to_i_or_nil(params[:offset]),
                  per_page: resolve_page_size(params[:pageSize]),
                  current_user:
                )
              end

              # POST /projects/:project_id/wiki_pages
              post do
                authorize_in_project(:edit_wiki_pages, project: @project)

                attributes = parse_wiki_page_body(request)
                new_page   = WikiPage.new(wiki: @wiki)

                call = ::WikiPages::CreateService
                         .new(user: current_user,
                              contract_class: ::WikiPages::CreateContract,
                              model: new_page)
                         .call(attributes)

                if call.success?
                  render_page(call.result)
                else
                  raise ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
                end
              end

              # GET /projects/:project_id/wiki_pages/tree
              get :tree do
                pages = @wiki.pages
                             .includes(:parent, :author, wiki: :project)
                             .order(:title)
                             .to_a

                { _type: "Collection", total: pages.size, tree: build_tree(pages) }
              end

              # GET /projects/:project_id/wiki_pages/search
              get :search do
                query    = params[:q].to_s.strip
                page_idx = to_i_or_nil(params[:offset]) || 1
                size     = resolve_page_size(params[:pageSize])

                results = ::OpenProject::WikiAPI::Search.call(
                  wiki: @wiki, query:, page: page_idx, per_page: size
                )

                ::API::V3::WikiPagesExt::WikiPageCollectionRepresenter.new(
                  results,
                  self_link: api_v3_paths.wiki_pages_search(@project.id),
                  page: page_idx,
                  per_page: size,
                  current_user:
                )
              end
            end
          end
        end

        # ---------------- Per-page operations ----------------
        #
        # The capture parameter is named :wp_id (not :id) to avoid future
        # conflicts should this API ever be mounted inside another route
        # namespace that already binds :id.
        resources :wiki_pages do
          route_param :wp_id, type: Integer, desc: "Wiki page id" do
            # PATCH /wiki_pages/:wp_id
            patch do
              page = load_wiki_page!(params[:wp_id])
              authorize_in_project(:edit_wiki_pages, project: page.project)

              run_update!(page, parse_wiki_page_body(request))
            end

            # DELETE /wiki_pages/:wp_id
            delete do
              page = load_wiki_page!(params[:wp_id])
              authorize_in_project(:manage_wiki, project: page.project)

              page.destroy!
              status 204
              nil
            end

            # ---- Versions ----

            resource :versions do
              get do
                page = load_wiki_page!(params[:wp_id])
                authorize_in_project(:view_wiki_edits, project: page.project)

                journals = page.journals.order(version: :desc)
                ::API::V3::WikiPagesExt::Versions::WikiPageVersionCollectionRepresenter.new(
                  journals,
                  self_link: api_v3_paths.wiki_page_versions(page.id),
                  page: 1,
                  per_page: [journals.size, 1].max,
                  current_user:
                )
              end

              route_param :wp_version, type: Integer, desc: "Wiki page version" do
                get do
                  page = load_wiki_page!(params[:wp_id])
                  authorize_in_project(:view_wiki_edits, project: page.project)

                  journal = page.journals.find_by!(version: params[:wp_version])
                  ::API::V3::WikiPagesExt::Versions::WikiPageVersionRepresenter
                    .new(journal, page:, current_user:)
                end

                post :restore do
                  page = load_wiki_page!(params[:wp_id])
                  authorize_in_project(:edit_wiki_pages, project: page.project)

                  journal = page.journals.find_by!(version: params[:wp_version])
                  restored_text = journal.data&.text.to_s

                  status 200
                  run_update!(page, text: restored_text, lock_version: page.lock_version)
                end
              end
            end

            # ---- Lock / Unlock (backed by the WikiPage#protected? flag) ----
            #
            # Both endpoints require :manage_wiki because that is the
            # permission that guards the WikiPage#protected? flag in core.
            post :lock do
              page = load_wiki_page!(params[:wp_id])
              authorize_in_project(:manage_wiki, project: page.project)

              status 200
              run_update!(page, protected: true, lock_version: page.lock_version)
            end

            post :unlock do
              page = load_wiki_page!(params[:wp_id])
              authorize_in_project(:manage_wiki, project: page.project)

              status 200
              run_update!(page, protected: false, lock_version: page.lock_version)
            end

            # ---- Move ----

            post :move do
              page = load_wiki_page!(params[:wp_id])
              authorize_in_project(:manage_wiki, project: page.project)

              body = parse_json_body(request)
              attrs = {}
              attrs[:parent_title] = body["parentTitle"] if body.key?("parentTitle")

              if body["projectId"].present?
                target_project = Project.visible(current_user).find(body["projectId"])
                authorize_in_project(:edit_wiki_pages, project: target_project)

                target_wiki = target_project.wiki
                raise ::API::Errors::NotFound, "Target project has no wiki enabled" if target_wiki.nil?

                page.wiki = target_wiki
                attrs[:parent_title] = nil
              end

              attrs[:lock_version] = page.lock_version

              status 200
              run_update!(page, attrs)
            end

            # ---- Copy ----

            post :copy do
              page = load_wiki_page!(params[:wp_id])
              body = parse_json_body(request)

              target_project = if body["projectId"].present?
                                 Project.visible(current_user).find(body["projectId"])
                               else
                                 page.project
                               end

              authorize_in_project(:edit_wiki_pages, project: target_project)
              target_wiki = target_project.wiki
              raise ::API::Errors::NotFound, "Target project has no wiki enabled" if target_wiki.nil?

              new_title = body["title"].presence || "#{page.title} (copy)"

              call = if target_wiki.id == page.wiki_id
                       ::WikiPages::CopyService
                         .new(user: current_user,
                              contract_class: ::WikiPages::CopyContract,
                              model: page)
                         .call(title: new_title)
                     else
                       new_page = WikiPage.new(wiki: target_wiki)
                       ::WikiPages::CreateService
                         .new(user: current_user,
                              contract_class: ::WikiPages::CreateContract,
                              model: new_page)
                         .call(title: new_title,
                               text: page.text,
                               protected: page.protected?)
                     end

              if call.success?
                render_page(call.result)
              else
                raise ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
              end
            end
          end
        end
      end
    end
  end
end

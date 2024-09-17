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

module API
  module V3
    module Render
      class RenderAPI < ::API::OpenProjectAPI
        format :txt
        parser :txt, ::API::V3::Formatter::TxtCharset

        resources :render do
          helpers do
            SUPPORTED_CONTEXT_NAMESPACES ||= %w(work_packages projects news posts wiki_pages meeting_contents).freeze
            SUPPORTED_MEDIA_TYPE ||= "text/plain".freeze

            def allowed_content_types
              [SUPPORTED_MEDIA_TYPE]
            end

            def check_content_type
              actual = request.content_type

              unless actual&.starts_with?(SUPPORTED_MEDIA_TYPE)
                bad_type = actual || I18n.t("api_v3.errors.missing_content_type")
                message = I18n.t("api_v3.errors.invalid_content_type",
                                 content_type: SUPPORTED_MEDIA_TYPE,
                                 actual: bad_type)

                fail ::API::Errors::UnsupportedMediaType, message
              end
            end

            def check_format(format)
              unless ::OpenProject::TextFormatting::Formats.supported?(format)
                fail ::API::Errors::NotFound, I18n.t("api_v3.errors.code_404")
              end
            end

            def setup_response
              status 200
              content_type "text/html"
            end

            def request_body
              env["api.request.body"]
            end

            def context_object
              try_context_object
            rescue ::ActiveRecord::RecordNotFound
              fail ::API::Errors::InvalidRenderContext.new(
                I18n.t("api_v3.errors.render.context_object_not_found")
              )
            end

            def try_context_object
              if params[:context]
                context = parse_context
                namespace = context[:namespace]

                klass = if namespace == "posts"
                          Message
                        elsif SUPPORTED_CONTEXT_NAMESPACES.without("posts").include?(namespace)
                          namespace.camelcase.singularize.constantize
                        end

                return unless klass

                klass.visible(current_user).find(context[:id])
              end
            end

            def parse_context
              context = ::API::Utilities::ResourceLinkParser.parse(params[:context])

              if context.nil?
                fail ::API::Errors::InvalidRenderContext.new(
                  I18n.t("api_v3.errors.render.context_not_parsable")
                )
              elsif SUPPORTED_CONTEXT_NAMESPACES.exclude?(context[:namespace]) ||
                    context[:version] != "3"
                fail ::API::Errors::InvalidRenderContext.new(
                  I18n.t("api_v3.errors.render.unsupported_context")
                )
              else
                context
              end
            end
          end

          route_param :render_format do
            after_validation do
              @format = params[:render_format]
            end

            post do
              check_format(@format)
              check_content_type
              setup_response

              renderer = ::API::Utilities::TextRenderer.new(request_body,
                                                            object: context_object,
                                                            format: @format)
              renderer.to_html
            end
          end
        end
      end
    end
  end
end

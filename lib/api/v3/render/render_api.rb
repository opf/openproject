#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

module API
  module V3
    module Render
      class RenderAPI < Grape::API
        format :txt
        parser :txt, ::API::V3::Formatter::TxtCharset

        resources :render do
          helpers do
            SUPPORTED_CONTEXT_NAMESPACES = ['work_packages'].freeze
            SUPPORTED_MEDIA_TYPE = 'text/plain'

            def check_content_type
              actual = request.content_type

              unless actual.starts_with? SUPPORTED_MEDIA_TYPE
                message = I18n.t('api_v3.errors.invalid_content_type',
                                 content_type: SUPPORTED_MEDIA_TYPE,
                                 actual: actual)

                fail API::Errors::InvalidRequestBody, message
              end
            end

            def setup_response
              status 200
              content_type 'text/html'
            end

            def request_body
              env['api.request.body']
            end

            def context_object
              try_context_object
            rescue ::ActiveRecord::RecordNotFound
              fail API::Errors::InvalidRenderContext.new(
                I18n.t('api_v3.errors.render.context_object_not_found')
              )
            end

            def try_context_object
              if params[:context]
                context = parse_context

                case context[:ns]
                when 'work_packages'
                  WorkPackage.visible(current_user).find(context[:id])
                end
              end
            end

            def parse_context
              context = ::API::V3::Utilities::ResourceLinkParser.parse(params[:context])

              if context.nil?
                fail API::Errors::InvalidRenderContext.new(
                  I18n.t('api_v3.errors.render.context_not_found')
                )
              elsif !SUPPORTED_CONTEXT_NAMESPACES.include? context[:ns]
                fail API::Errors::InvalidRenderContext.new(
                  I18n.t('api_v3.errors.render.unsupported_context')
                )
              else
                context
              end
            end

            def renderer(type)
              case type
              when :textile
                ::API::Utilities::Renderer::TextileRenderer.new(request_body, context_object)
              when :plain
                ::API::Utilities::Renderer::PlainRenderer.new(request_body)
              end
            end

            def render(type)
              renderer(type).to_html
            end
          end

          resources :textile do
            post do
              check_content_type
              setup_response

              render :textile
            end
          end

          resources :plain do
            post do
              check_content_type
              setup_response

              render :plain
            end
          end
        end
      end
    end
  end
end

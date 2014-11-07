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

        resources :render do
          helpers do
            SUPPORTED_CONTEXT_NAMESPACES = ['work_packages'].freeze

            def request_body
              env['api.request.body']
            end

            def context_object
              begin
                try_context_object
              rescue ::ActiveRecord::RecordNotFound
                fail API::Errors::InvalidRenderContext.new('Context does not exist!')
              end
            end

            def try_context_object
              if params[:context]
                context = parse_context

                case context[:ns]
                when 'work_packages'
                  WorkPackage.visible(current_user).find(context[:id])
                else
                end
              end
            end

            def parse_context
              context = ::API::V3::Utilities::ResourceLinkParser.parse(params[:context])

              fail API::Errors::InvalidRenderContext.new('No context found.') if context.nil?

              unless SUPPORTED_CONTEXT_NAMESPACES.include? context[:ns]
                fail API::Errors::InvalidRenderContext.new('Unsupported context found.')
              end

              context
            end

            def render(type)
              case type
              when :textile
                renderer = ::API::Utilities::Renderer::TextileRenderer.new(request_body, context_object)
                renderer.to_html
              else
              end
            end
          end

          resources :textile do
            post do
              status 200
              content_type 'text/html'

              render :textile
            end
          end
        end
      end
    end
  end
end

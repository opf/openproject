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
        include OpenProject::TextFormatting
        format :txt

        resources :render do
          helpers do
            SUPPORTED_CONTEXT_NAMESPACES = ['work_packages'].freeze

            def request_body
              env['api.request.body']
            end

            def context_object
              if params[:context]
                context_object = nil
                namespace, id = parse_context

                case namespace
                when 'work_packages'
                  context_object = WorkPackage.visible(current_user).find_by_id(id)
                end

                unless context_object
                  fail API::Errors::InvalidRenderContext.new('Context does not exist!')
                end
              end
            end

            def parse_context
              contexts = API::V3::Root.routes.map do |route|
                route_options = route.instance_variable_get(:@options)
                match = route_options[:compiled].match(params[:context])

                if match
                  {
                    ns: /\/(?<ns>\w+)\//.match(route_options[:namespace])[:ns],
                    id: match[:id]
                  }
                end
              end

              contexts.compact!.uniq! { |c| c[:ns] }

              fail API::Errors::InvalidRenderContext.new('No context found.') if contexts.empty?

              unless SUPPORTED_CONTEXT_NAMESPACES.include? contexts[0][:ns]
                fail API::Errors::InvalidRenderContext.new('Unsupported context found.')
              end

              [contexts[0][:ns], contexts[0][:id]]
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

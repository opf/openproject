#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
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
    module BcfXml
      class BcfXmlAPI < ::API::OpenProjectAPI
        resources :projects do
          route_param :id do
            namespace 'bcf_xml' do
              helpers do
                # Global helper to set allowed content_types
                # This may be overriden when multipart is allowed (file uploads)
                def allowed_content_types
                  if post_request?
                    %w(multipart/form-data)
                  else
                    super
                  end
                end

                def post_request?
                  request.env['REQUEST_METHOD'] == 'POST'
                end

                def import_options
                  params[:import_options].presence || {}
                end
              end

              post do
                project = Project.find(params[:id])

                authorize(:manage_bcf, context: project) do
                  raise API::Errors::NotFound.new
                end

                begin
                  file = params[:bcf_xml_file][:tempfile]
                  importer = ::OpenProject::Bcf::BcfXml::Importer.new(file,
                                                                      project,
                                                                      current_user: User.current)
                  importer.import! import_options
                rescue StandardError => e
                  raise API::Errors::InternalError.new e.message
                ensure
                  file.delete
                end
              end
            end
          end
        end
      end
    end
  end
end

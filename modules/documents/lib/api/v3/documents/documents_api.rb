#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module API
  module V3
    module Documents
      class DocumentsAPI < ::API::OpenProjectAPI
        helpers ::API::Utilities::PageSizeHelper

        resources :documents do
          get do
            query = ParamsToQueryService
                    .new(Document, current_user)
                    .call(params)

            if query.valid?
              DocumentCollectionRepresenter.new(query.results,
                                                api_v3_paths.documents,
                                                page: to_i_or_nil(params[:offset]),
                                                per_page: resolve_page_size(params[:pageSize]),
                                                current_user: current_user)
            else
              raise ::API::Errors::InvalidQuery.new(query.errors.full_messages)
            end
          end

          route_param :id, type: Integer, desc: 'Document ID' do
            helpers do
              def document
                Document.visible.find(params[:id])
              end
            end

            get do
              ::API::V3::Documents::DocumentRepresenter.new(document,
                                                            current_user: current_user,
                                                            embed_links: true)
            end

            mount ::API::V3::Attachments::AttachmentsByDocumentAPI
          end
        end
      end
    end
  end
end

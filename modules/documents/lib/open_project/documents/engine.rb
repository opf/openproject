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

module OpenProject::Documents
  class Engine < ::Rails::Engine
    engine_name :openproject_documents

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-documents",
             author_url: "http://www.openproject.org",
             bundled: true do
      menu :project_menu,
           :documents,
           { controller: "/documents", action: "index" },
           caption: :label_document_plural,
           before: :members,
           icon: "note"

      project_module :documents do |_map|
        permission :view_documents,
                   { documents: %i[index show download] },
                   permissible_on: :project
        permission :manage_documents,
                   { documents: %i[new create edit update destroy] },
                   permissible_on: :project,
                   require: :loggedin
      end

      Redmine::Search.register :documents
    end

    activity_provider :documents, class_name: "Activities::DocumentActivityProvider", default: false

    patches %i[Project]

    add_api_path :documents do
      "#{root}/documents"
    end

    add_api_path :document do |id|
      "#{root}/documents/#{id}"
    end

    add_api_path :attachments_by_document do |id|
      "#{document(id)}/attachments"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Documents::DocumentsAPI
    end

    # Add documents to allowed search params
    additional_permitted_attributes search: %i(documents)

    config.to_prepare do
      Enumeration.register_subclass(DocumentCategory)
    end
  end
end

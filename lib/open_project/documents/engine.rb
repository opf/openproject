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


module OpenProject::Documents
  class Engine < ::Rails::Engine
    engine_name :openproject_documents

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-documents',
             author_url: "http://www.openproject.com",
             global_assets: { css: 'documents/global_rules' },
             requires_openproject: ">= 4.0.0" do

      menu :project_menu, :documents,
                          { controller: '/documents', action: 'index' },
                          param: :project_id,
                          caption: :label_document_plural,
                          icon: 'icon2 icon-notes'

      project_module :documents do |_map|
        permission :manage_documents, {
          documents: [:new, :create, :edit, :update, :destroy, :add_attachment]
          }, require: :loggedin
        permission :view_documents, documents: [:index, :show, :download]
      end

      Redmine::Notifiable.all << Redmine::Notifiable.new('document_added')

      Redmine::Activity.map do |activity|
        activity.register :documents, class_name: 'Activity::DocumentActivityProvider', default: false
      end

      Redmine::Search.register :documents
    end

    patches [:CustomFieldsHelper, :Project]

    assets %w(documents/documents.css)

    # Add documents to allowed search params
    additional_permitted_attributes search: %i(documents)

    initializer "documents.register_hooks" do
      require 'open_project/documents/hooks'
    end

    config.to_prepare do
      require_dependency 'document'
      require_dependency 'document_category'
      require_dependency 'document_category_custom_field'

      # Have to apply this one by hand and not via op_engine patches method
      # becauses the op_engine method does not allow for patching something
      # in the lib/open_project directory. Bummer.
      require_dependency 'open_project/documents/patches/text_formatting_patch'
    end
  end
end

#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'open_project/plugins'

module OpenProject::IFCModels
  class Engine < ::Rails::Engine
    engine_name :openproject_ifc_models

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-ifc_models',
             author_url: 'https://openproject.com',
             settings: {
               default: {
               }
             } do

      project_module :ifc_models do
        permission :view_ifc_models,
                   { 'ifc_models/ifc_models': %i[index show] }
        permission :manage_ifc_models,
                   { 'ifc_models/ifc_models': %i[index show destroy edit update create new] },
                   dependencies: %i[view_ifc_models]
      end
    end

    assets %w(ifc_models/ifc_models.css)

    initializer 'ifc_models.menu' do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:ifc_models,
                  { controller: '/ifc_models/ifc_models', action: 'index' },
                  caption: :'ifc_models.label_ifc_models',
                  param: :project_id,
                  icon: 'icon2 icon-ifc')
      end
    end

    config.to_prepare do
      require 'open_project/ifc_models/hooks'
    end

    patches %i[Project]
  end
end

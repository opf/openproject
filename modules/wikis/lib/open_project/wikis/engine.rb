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

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

module OpenProject::Wikis
  class Engine < ::Rails::Engine
    engine_name :openproject_wikis

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "openproject_wikis.inflections" do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym "XWiki"
      end

      OpenProject::Inflector.rule do |basename, abspath|
        case basename
        when "xwiki"
          "XWiki"
        when /\Axwiki_(.*)\z/
          "XWiki#{default_inflect($1, abspath)}"
        end
      end
    end

    config.to_prepare do
      API::V3::Configuration::ConfigurationRepresenter.property(
        :wikisAvailable,
        getter: ->(*) { ::Wikis::Provider.enabled.exists? }
      )

      OpenProject::TextFormatting::Filters::PatternMatcherFilter.append_matcher ::Wikis::TextFormatting::WikiLinkMatcher

      # Registering queries and filters
      ::Queries::Register.register(::Queries::Wikis::PageLinks::PageLinkQuery) do
        filter ::Queries::Wikis::PageLinks::Filter::IdentifierFilter
        filter ::Queries::Wikis::PageLinks::Filter::ProviderFilter
        filter ::Queries::Wikis::PageLinks::Filter::WikiPageLinkTypeFilter
      end
    end

    replace_principal_references "Wikis::PageLink" => %i[author_id]

    register "openproject-wikis", author_url: "https://openproject.org" do
      project_module :work_package_tracking do
        permission :manage_wiki_page_links,
                   {
                     "wikis/pages": %i[create_and_link create_new_page_dialog],
                     "wikis/relation_page_links": %i[create
                                                     destroy
                                                     confirm_delete_dialog
                                                     link_existing_dialog]
                   },
                   permissible_on: :project,
                   dependencies: %i[edit_work_packages],
                   contract_actions: { wiki_page_links: %i[manage] }
      end

      menu :work_package_split_view,
           :wikis,
           { tab: :wikis },
           skip_permissions_check: true,
           after: :relations,
           badge: ->(work_package:, **) { Wikis::PageLinkService.new.count(work_package) },
           if: lambda { |_project|
             Wikis::Provider.enabled.exists? &&
               OpenProject::FeatureDecisions.wiki_enhancements_active?
           }

      menu :admin_menu,
           :wiki_providers,
           { controller: "/wikis/admin/wiki_providers", action: :index },
           if: ->(_) { User.current.admin? && OpenProject::FeatureDecisions.wiki_enhancements_active? },
           caption: :"menus.admin.wikis",
           icon: :book

      menu :admin_menu,
           :internal_wiki_provider,
           { controller: "/wikis/admin/internal_wiki_provider", action: :show },
           parent: :wiki_providers,
           if: ->(_) { User.current.admin? && OpenProject::FeatureDecisions.wiki_enhancements_active? },
           caption: :"menus.admin.internal_wiki_provider"

      menu :admin_menu,
           :external_wiki_providers,
           { controller: "/wikis/admin/wiki_providers", action: :index },
           parent: :wiki_providers,
           if: ->(_) { User.current.admin? && OpenProject::FeatureDecisions.wiki_enhancements_active? },
           caption: :"menus.admin.external_wiki_providers"
    end

    patch_with_namespace :WikiPages, :CreateService
    patch_with_namespace :WikiPages, :UpdateService
    patch_with_namespace :WorkPackages, :CreateService
    patch_with_namespace :WorkPackages, :UpdateService

    add_api_path(:wiki_page_links) { "#{root}/wiki_page_links" }
    add_api_path(:wiki_page_link) { |page_link_id| "#{wiki_page_links}/#{page_link_id}" }
    add_api_path(:wiki_provider) { |provider_universal_identifier| "#{root}/wiki_providers/#{provider_universal_identifier}" }
    add_api_path(:work_package_wiki_page_links) { |work_package_id| "#{work_package(work_package_id)}/wiki_page_links" }

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::PageLinks::PageLinksAPI
    end

    add_api_endpoint "API::V3::WorkPackages::WorkPackagesAPI", :id do
      mount ::API::V3::PageLinks::WorkPackageWikiPageLinksAPI
    end
  end
end

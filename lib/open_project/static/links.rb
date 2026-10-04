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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Static
    module Links
      class << self
        def help_link_overridden?
          OpenProject::Configuration.force_help_link.present?
        end

        def help_link
          OpenProject::Configuration.force_help_link.presence || static_links[:user_guides][:href]
        end

        def cache_key
          @cache_key ||= OpenProject::Cache::CacheKey.expand(links)
        end

        def label_for(*path)
          key = links.dig(*path, :label)
          return if key.nil?

          I18n.t(key)
        end

        def url_for(*path, localize_url: true, url_params: {})
          href = links.dig(*path, :href)
          return if href.nil?

          if localize_url && website_link?(href)
            url_with_query(href, **url_params, go_to_locale: I18n.locale)
          else
            url_with_query(href, **url_params)
          end
        end

        def has?(name)
          @links.key? name
        end

        def website_link?(url)
          url&.start_with?(website_url)
        end

        def website_url
          links[:website][:href]
        end

        def reset_cache
          @cache_key = nil
          @links = nil
          @static_links = nil
        end

        private

        def links
          @links ||= static_links.merge(dynamic_links)
        end

        def url_with_query(href, **params)
          return href if params.empty?

          url = Addressable::URI.parse(href)
          url.query_values = (url.query_values || {}).merge(params)
          url.to_s
        end

        def dynamic_links
          dynamic = {
            help: {
              href: help_link,
              label: "top_menu.help_and_support"
            },
            current_release_notes: {
              href: current_release_notes_link,
              label: :label_release_notes
            }
          }

          if impressum_link = OpenProject::Configuration.impressum_link
            dynamic[:impressum] = {
              href: impressum_link,
              label: "homescreen.links.impressum"
            }
          end

          dynamic
        end

        def current_release_notes_link
          version = OpenProject::VERSION.to_semver(separator: "-")
          "https://www.openproject.org/docs/release-notes/#{version}"
        end

        def static_links
          @static_links ||= begin
            yaml = Rails.root.join("config/static_links.yml").read
            YAML.safe_load(yaml, permitted_classes: [Symbol], symbolize_names: true)
          end
        end
      end
    end
  end
end

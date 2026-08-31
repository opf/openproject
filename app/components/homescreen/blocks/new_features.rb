# frozen_string_literal: true

# -- copyright
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
# ++

module Homescreen
  module Blocks
    class NewFeatures < Grids::WidgetComponent
      ALLOWED_FILE_TYPES = %w[jpg png jpeg svg].freeze

      def title
        I18n.t(:label_new_features)
      end

      def feature_teaser_image
        defined?(@feature_teaser_image) || begin
          @feature_teaser_image = ALLOWED_FILE_TYPES
            .map { |extension| feature_teaser_image_name(extension:) }
            .detect { |name| helpers.has_rails_asset?(name) }
        end

        @feature_teaser_image
      end

      def feature_teaser_image_name(extension:)
        "#{feature_version}_features.#{extension}"
      end

      def has_image?
        feature_teaser_image.present?
      end

      def new_features_header
        I18n.t("homescreen.blocks.new_features.header")
      end

      def learn_more_link_text
        I18n.t("homescreen.blocks.new_features.learn_about")
      end

      def new_features_title
        I18n.t("#{base_i18n_key}.new_features_title",
               default: "Missing feature title")
      end

      def new_features
        I18n.t("#{base_i18n_key}.new_features_list").values
      end

      def teaser_exists?
        I18n.exists?(base_i18n_key)
      end

      def base_i18n_key
        "homescreen.blocks.new_features.#{feature_version}"
      end

      private

      def feature_version
        [
          OpenProject::VERSION::MAJOR,
          OpenProject::VERSION::MINOR
        ].join("_")
      end
    end
  end
end

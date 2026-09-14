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

module OpenProject
  module EnterpriseEdition
    # @logical_path OpenProject/EnterpriseEdition
    class BannerComponentPreview < Lookbook::Preview
      # The easiest way to render the banner component is to provide a feature key and
      # have the assorted data structures match the expectations.
      # The text will be fetched from the i18n files:
      # ```
      # en:
      #   ee:
      #     # Title used unless it is overwritten for the specific feature
      #     title: "Enterprise add-on"
      #     upsell:
      #       [feature_key]:
      #         # Title used for this feature only. If this is missing, the default feature key is used.
      #         title: "A splendid feature"
      #         # Could also be description_html if necessary
      #         description: "This is a splendid feature that you should use. It just might transform your life."
      #         # An unordered list of features
      #         features:
      #           some_key: "Some feature"
      #           some_other_key: "Some other feature"
      # ```
      # You can also provide a custom i18n_scope to change the place where the component looks for
      # title, description, and features.
      #
      # The href is inferred from `OpenProject::Static::Links.enterprise_features[feature_key][:href]`.
      # @param dismissable toggle
      # @display min_height 250px
      def default(dismissable: false)
        render(
          ::EnterpriseEdition::BannerComponent
            .new(:customize_life_cycle, dismissable:, show_always: true)
        )
      end

      # @display min_height 350px
      def medium
        render(
          ::EnterpriseEdition::BannerComponent
            .new(:customize_life_cycle,
                 variant: :medium,
                 image: "enterprise/internal-comments.png",
                 show_always: true)
        )
      end

      # @display min_height 600px
      def large
        render(
          ::EnterpriseEdition::BannerComponent
            .new(:date_alerts,
                 variant: :large,
                 video: "enterprise/date-alert-notifications.mp4",
                 show_always: true)
        )
      end

      # Compares the two dark mode strategies for the `:medium` variant. This preview is forced
      # into dark mode: the top banner has no `dark_image` and falls back to inverting the light
      # image, while the bottom banner renders a dedicated `dark_image`.
      # @display min_height 700px
      # @display color_mode dark
      def dark_image
        render_with_template
      end

      # @display min_height 350px
      def medium_dismissable
        render(
          ::EnterpriseEdition::BannerComponent
            .new(:customize_life_cycle,
                 variant: :medium,
                 dismissable: true,
                 dismiss_key: nil,
                 image: "enterprise/internal-comments.png",
                 show_always: true)
        )
      end

      # @display min_height 250px
      def dismissable
        render(
          ::EnterpriseEdition::BannerComponent
            .new(:customize_life_cycle, dismiss_key: nil, dismissable: true, show_always: true)
        )
      end
    end
  end
end

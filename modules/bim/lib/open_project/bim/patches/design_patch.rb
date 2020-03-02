require 'open_project/custom_styles/design'

module OpenProject::Bim
  module Patches
    module DesignPatch
      def self.included(base)
        class << base
          prepend ClassMethods
        end
      end

      module ClassMethods
        def variables
          if OpenProject::Configuration.bim?
            super.merge 'primary-color' => "#3270DB",
                        'primary-color-dark' => "#163473",
                        'alternative-color' => "#349939",
                        'header-bg-color' => "#05002C",
                        'header-item-bg-hover-color' => "#163473",
                        'content-link-color' => "#275BB5",
                        'main-menu-bg-color' => "#0E2045",
                        'main-menu-bg-selected-background' => "#3270DB",
                        'main-menu-bg-hover-background' => "#163473",
                        'header-home-link-bg' => '#{image-url("bim/logo_openproject_bim_big.png") no-repeat 20px 0}',
                        'new-feature-teaser-image' => '#{image-url("bim/new_feature_teaser.jpg")}'
          else
            super
          end
        end
      end
    end
  end
end

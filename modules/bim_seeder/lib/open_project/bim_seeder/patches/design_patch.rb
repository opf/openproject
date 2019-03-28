require 'open_project/design'

module OpenProject::BimSeeder
  module Patches
    module DesignPatch
      DEFAULTS = OpenProject::Design::DEFAULTS.merge(
        {
          'primary-color'                                        => "#748EA8",
          'primary-color-dark'                                   => "#566484",
          'header-bg-color'                                      => "#566484",
          'header-item-bg-hover-color'                           => "#748EA8",
          'main-menu-bg-color'                                   => "#333739",
          'main-menu-bg-selected-background'                     => "#748EA8",
          'main-menu-bg-hover-background'                        => "#566484",
          'header-home-link-bg'                                  => '#{image-url("bim_seeder/logo_openproject_bim_big.png") no-repeat 20px 0}'
        }
      ).freeze
    end
  end
end

OpenProject::Design.send(:remove_const, 'DEFAULTS')
OpenProject::Design.const_set('DEFAULTS', OpenProject::BimSeeder::Patches::DesignPatch::DEFAULTS)

module OpenProject
  module BimSeeder
    require "open_project/bim_seeder/engine"

    # The DesignPatch is not a typical method patch, as it replaces a constant and thus needs to be applied without the
    # standard patch logic for plugins.
    require "open_project/bim_seeder/patches/design_patch"
  end
end

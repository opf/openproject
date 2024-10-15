class RemoveObsoleteDesignVariables < ActiveRecord::Migration[7.1]
  OBSOLETE_COLOR_VARIABLES = %w( main-menu-font-color
                                 main-menu-selected-font-color
                                 main-menu-hover-font-color
                                 main-menu-border-color
                                 header-item-font-color
                                 header-item-font-hover-color
                                 header-border-bottom-color ).freeze

  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  def up
    MigrationDesignColor.where(variable: OBSOLETE_COLOR_VARIABLES).delete_all
  end

  def down
    # This is not revertible
  end
end

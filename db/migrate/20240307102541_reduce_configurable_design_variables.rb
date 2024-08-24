class ReduceConfigurableDesignVariables < ActiveRecord::Migration[7.1]
  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  def up
    # Delete "primary-color" and "primary-color-dark"
    MigrationDesignColor
      .where(variable: %w(primary-color primary-color-dark))
      .delete_all

    # Rename "alternative-color" to "primary-button-color"
    MigrationDesignColor
      .where(variable: "alternative-color")
      .update(variable: "primary-button-color")

    # Rename "content-link-color" to "accent-color"
    MigrationDesignColor
      .where(variable: "content-link-color")
      .update(variable: "accent-color")
  end

  def down
    MigrationDesignColor
      .create(variable: "primary-color", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_PRIMARY_COLOR)
    MigrationDesignColor
      .create(variable: "primary-color-dark", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_PRIMARY_DARK_COLOR)

    MigrationDesignColor
      .where(variable: "primary-button-color")
      .update(variable: "alternative-color")

    MigrationDesignColor
      .where(variable: "accent-color")
      .update(variable: "content-link-color")
  end
end

class ChangeDefaultAccentAndBimPrimaryColor < ActiveRecord::Migration[7.1]
  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  def up
    # The default Bim value was forgotten in previous migrations
    if OpenProject::Configuration.bim?
      MigrationDesignColor
        .where(variable: "primary-button-color", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_BIM_ALTERNATIVE_COLOR)
        .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR)
    end

    # When merging the old "primary" and "link" color into the new "accent" color,
    # it was forgotten to use the value of "primary" for it.
    MigrationDesignColor
      .where(variable: "accent-color", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_LINK_COLOR)
      .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::ACCENT_COLOR)
  end

  def down
    if OpenProject::Configuration.bim?
      MigrationDesignColor
        .where(variable: "primary-button-color", hexcode: OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR)
        .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_BIM_ALTERNATIVE_COLOR)
    end

    MigrationDesignColor
      .where(variable: "accent-color", hexcode: OpenProject::CustomStyles::ColorThemes::ACCENT_COLOR)
      .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_LINK_COLOR)
  end
end

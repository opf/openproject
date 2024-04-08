class ChangeDefaultValueForBimPrimaryColor < ActiveRecord::Migration[7.1]
  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  def up
    primary_button_color = MigrationDesignColor.find_by(variable: "primary-button-color")
    if primary_button_color&.hexcode == OpenProject::CustomStyles::ColorThemes::DEPRECATED_BIM_ALTERNATIVE_COLOR
      primary_button_color.update(hexcode: OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR)
    end
  end

  def down
    primary_button_color = MigrationDesignColor.find_by(variable: "primary-button-color")
    if primary_button_color&.hexcode == OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR
      primary_button_color.update(hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_BIM_ALTERNATIVE_COLOR)
    end
  end
end

class ChangeDefaultValueOfAlternativeColor < ActiveRecord::Migration[7.1]
  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  def up
    alternative_color = MigrationDesignColor.find_by(variable: "alternative-color")
    if alternative_color&.hexcode == OpenProject::CustomStyles::ColorThemes::DEPRECATED_ALTERNATIVE_COLOR
      alternative_color.update(hexcode: OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR)
    end
  end

  def down
    alternative_color = MigrationDesignColor.find_by(variable: "alternative-color")
    if alternative_color&.hexcode == OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR
      alternative_color.update(hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_ALTERNATIVE_COLOR)
    end
  end
end

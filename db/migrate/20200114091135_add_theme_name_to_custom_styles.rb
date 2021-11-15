class AddThemeNameToCustomStyles < ActiveRecord::Migration[6.0]
  def change
    add_column :custom_styles,
               :theme,
               :string,
               default: OpenProject::CustomStyles::ColorThemes::DEFAULT_THEME_NAME
  end
end

class AddThemeLogoToCustomStyle < ActiveRecord::Migration[6.0]
  def change
    add_column :custom_styles, :theme_logo, :string, default: nil
  end
end

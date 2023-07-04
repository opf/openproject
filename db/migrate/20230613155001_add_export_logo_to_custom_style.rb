class AddExportLogoToCustomStyle < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_styles,
               :export_logo,
               :string,
               default: nil
  end
end

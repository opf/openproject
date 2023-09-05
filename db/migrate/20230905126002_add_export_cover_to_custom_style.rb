class AddExportCoverToCustomStyle < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_styles,
               :export_cover,
               :string,
               default: nil
  end
end

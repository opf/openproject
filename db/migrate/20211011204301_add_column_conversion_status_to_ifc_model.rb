class AddColumnConversionStatusToIfcModel < ActiveRecord::Migration[6.1]
  def change
    add_column(:ifc_models, :conversion_status, :integer, default: 0)
    add_column(:ifc_models, :conversion_error_message, :text)
  end
end

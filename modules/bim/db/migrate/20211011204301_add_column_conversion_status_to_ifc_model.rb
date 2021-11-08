class AddColumnConversionStatusToIfcModel < ActiveRecord::Migration[6.1]
  def up
    add_column(:ifc_models, :conversion_status, :integer, default: 0) # default "pending"
    add_column(:ifc_models, :conversion_error_message, :text)

    converted_models = ::Bim::IfcModels::IfcModel
                         .joins(:attachments)
                         .where("attachments.description = 'xkt'")

    not_converted_models = ::Bim::IfcModels::IfcModel
                             .where
                             .not(id: converted_models)

    converted_models.update_all(conversion_status: 2) # 2 == processed
    not_converted_models.update_all(conversion_status: 3) # 3 == error
  end

  def down
    remove_column(:ifc_models, :conversion_status)
    remove_column(:ifc_models, :conversion_error_message)
  end
end

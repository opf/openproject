class AddColumnConversionStatusToIfcModel < ActiveRecord::Migration[6.1]
  def up
    add_column(:ifc_models, :conversion_status, :integer, default: 0)
    add_column(:ifc_models, :conversion_error_message, :text)

    # Set IfcModels having a XKT file as "processed"
    ::Bim::IfcModels::IfcModel
      .joins(:attachments)
      .where("attachments.description = 'xkt'")
      .update_all(conversion_status: 2) # 2 == processed

    # Set IfcModels not having a XKT file as conversion_status "error"
    processed_model_ids = ::Bim::IfcModels::IfcModel
      .joins(:attachments)
      .where("attachments.description = 'xkt'")
      .pluck(:id)

    ::Bim::IfcModels::IfcModel.where("id NOT IN (?)", processed_model_ids).update_all(conversion_status: 3) # 3 == error
  end

  def down
    remove_column(:ifc_models,:conversion_status)
    remove_column(:ifc_models,:conversion_error_message)
  end
end

module IfcModelsHelper
  def provision_gon_for_ifc_model(all_models, shown_models)
    all_converted_models = converted_ifc_models(all_models)

    gon.ifc_models = {
      models: gon_ifc_model_models(all_converted_models),
      shown_models: gon_ifc_shown_models(all_converted_models, shown_models),
      projects: [{id: @project.identifier, name: @project.name}],
      xkt_attachment_ids: gon_ifc_model_xkt_attachment_ids(all_converted_models),
      metadata_attachment_ids: gon_ifc_model_metadata_attachment_ids(all_converted_models),
      permissions: {
        manage_ifc_models: User.current.allowed_to?(:manage_ifc_models, @project),
        manage_bcf: User.current.allowed_to?(:manage_bcf, @project),
      }
    }
  end

  def converted_ifc_models(ifc_models)
    ifc_models.select(&:converted?)
  end

  def gon_ifc_model_models(all_models)
    all_converted_models = converted_ifc_models(all_models)

    all_converted_models.map do |ifc_model|
      {
        id: ifc_model.id,
        name: ifc_model.title,
        default: ifc_model.is_default,
        saoEnabled: ifc_model.is_default
      }
    end
  end

  def gon_ifc_shown_models(all_models, shown_models)
    if shown_models.empty?
      return all_models.select(&:is_default).map(&:id)
    end

    converted_ifc_models(all_models)
      .select { |model| shown_models.include?(model.id) }
      .map(&:id)
  end

  def gon_ifc_model_xkt_attachment_ids(models)
    Hash[models.map { |model| [model.id, model.xkt_attachment.id] }]
  end

  def gon_ifc_model_metadata_attachment_ids(models)
    Hash[
      models.map do |model|
        [model.id,
         model.metadata_attachment.id]
      end
    ]
  end
end

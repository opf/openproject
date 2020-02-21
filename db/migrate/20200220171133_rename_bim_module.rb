class RenameBimModule < ActiveRecord::Migration[6.0]
  def up
    projects_with_bcf = EnabledModule.where(name: 'bcf').pluck(:project_id)
    # Delete all bcf to avoid duplicates
    EnabledModule.where(name: 'bcf').delete_all
    EnabledModule.where(name: 'ifc_models').update_all(name: 'bim')

    # Re-enable bim if ifc_models was not active but bcf was
    Project.where(id: projects_with_bcf).includes(:enabled_modules).each do |project|
      project.enabled_modules.create(name: 'bim') unless project.enabled_module_names.include?('bim')
    end

    # Rename attachments container
    Attachment.where(container_type: 'Bcf::Viewpoint').update_all(container_type: 'Bim::Bcf::Viewpoint')
    Attachment.where(container_type: 'IFCModels::IFCModel').update_all(container_type: 'Bim::IfcModels::IfcModel')
  end

  def down
    # We cannot now which module was active, so enable BCF
    EnabledModule.where(name: 'bim').update_all(name: 'bcf')

    # Rename attachments container
    Attachment.where(container_type: 'Bim::Bcf::Viewpoint').update_all(container_type: 'Bcf::Viewpoint')
    Attachment.where(container_type: 'Bim::IfcModel::IfcModel').update_all(container_type: 'IFCModels::IFCModel')
  end
end

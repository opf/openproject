class RenameBimModule < ActiveRecord::Migration[6.0]
  def up
    projects_with_bcf = EnabledModule.where(name: 'bcf').pluck(:project_id)
    EnabledModule.where(name: 'ifc_models').update_all(name: 'bim')

    # Re-enable bim if ifc_models was not active
    Project.where(id: projects_with_bcf).includes(:enabled_modules).each do |project|
      project.enabled_module_names << 'bim' unless project.enabled_module_names.include?('bim')
    end
  end

  def down
    # We cannot now which module was active, so enable BCF
    EnabledModule.where(name: 'bim').update_all(name: 'bcf')
  end
end

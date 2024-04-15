class FixUntranslatedWorkPackageRoles < ActiveRecord::Migration[7.1]
  def up
    seed_work_package_roles_data.each_value do |work_package_role_data|
      work_package_role = WorkPackageRole.find_by(builtin: work_package_role_data[:builtin])
      work_package_role&.update(name: work_package_role_data[:name])
    end
  end

  def seed_work_package_roles_data
    seed_data = RootSeeder.new.translated_seed_data_for("work_package_roles", "modules_permissions")
    seeder = BasicData::WorkPackageRoleSeeder.new(seed_data)
    seeder.mapped_models_data
  end
end

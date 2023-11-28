class AddWorkPackageRoles < ActiveRecord::Migration[7.0]
  def up
    # This is how the role was seeded in the first iteration of seeds
    editor_role = WorkPackageRole.find_by(builtin: Role::NON_BUILTIN, name: 'Work Package Editor')
    # If we couldn't find a WP from the first iteration of the seeds, find it by the builtin
    editor_role ||= WorkPackageRole.find_or_initialize_by(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR)

    editor_role.update!(
      builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR,
      name: 'Work package editor',
      permissions: %i[
        view_work_packages
        edit_work_packages
        work_package_assigned
        add_work_package_notes
        edit_own_work_package_notes
        manage_work_package_relations
        copy_work_packages
        export_work_packages
      ]
    )

    # This is how the role was seeded in the first iteration of seeds
    commenter_role = WorkPackageRole.find_by(builtin: Role::NON_BUILTIN, name: 'Work Package Commenter')
    # If we couldn't find a WP from the first iteration of the seeds, find it by the builtin
    commenter_role ||= WorkPackageRole.find_or_initialize_by(builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER)
    commenter_role.update!(
      builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER,
      name: 'Work package commenter',
      permissions: %i[
        view_work_packages
        work_package_assigned
        add_work_package_notes
        edit_own_work_package_notes
        export_work_packages
      ]
    )

    # This is how the role was seeded in the first iteration of seeds
    viewer_role = WorkPackageRole.find_by(builtin: Role::NON_BUILTIN, name: 'Work Package Viewer')
    # If we couldn't find a WP from the first iteration of the seeds, find it by the builtin
    viewer_role ||= WorkPackageRole.find_or_initialize_by(builtin: Role::BUILTIN_WORK_PACKAGE_VIEWER)
    # Set up attributes
    viewer_role.update!(
      builtin: Role::BUILTIN_WORK_PACKAGE_VIEWER,
      name: 'Work package viewer',
      permissions: %i[
        view_work_packages
        export_work_packages
      ]
    )
  end
end

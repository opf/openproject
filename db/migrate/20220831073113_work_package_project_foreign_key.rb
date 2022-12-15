class WorkPackageProjectForeignKey < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        cleanup_invalid_work_packages
      end
    end

    add_foreign_key :work_packages, :projects
  end

  private

  def cleanup_invalid_work_packages
    WorkPackage
      .where.not(project_id: Project.select(:id))
      .find_each do |work_package|
      WorkPackages::DeleteService
        .new(user: User.system, model: work_package)
        .call
        .on_success { Rails.logger.info "Deleted stale work package #{work_package.inspect}" }
        .on_failure { Rails.logger.error "Failed to delete stale work package #{work_package.inspect}" }
    rescue ::ActiveRecord::RecordNotFound
      # raised by #reload if work package no longer exists
      # nothing to do, work package was already deleted (eg. by a parent)
    end
  end
end

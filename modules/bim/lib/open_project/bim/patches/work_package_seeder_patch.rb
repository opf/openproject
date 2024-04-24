module OpenProject::Bim::Patches::WorkPackageSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def create_or_update_work_package(attributes)
      uuid = attributes["bcf_issue_uuid"]
      if uuid
        time_tracking_attributes = time_tracking_attributes(attributes)

        work_package = find_bcf_issue(uuid)
        work_package.update_columns(created_at: Time.current,
                                    author_id: admin_user.id,
                                    assigned_to_id: find_principal(attributes["assigned_to"]).id,
                                    start_date: time_tracking_attributes[:start_date],
                                    due_date: time_tracking_attributes[:due_date],
                                    duration: time_tracking_attributes[:duration],
                                    ignore_non_working_days: time_tracking_attributes[:ignore_non_working_days])

        update_parent(work_package, attributes)
      else
        create_work_package(attributes)
      end
    end

    def update_parent(work_package, attributes)
      return unless attributes["parent"]

      parent = find_work_package(attributes["parent"])
      return if parent.nil?

      work_package.parent = parent
      work_package.save!
    end

    def find_bcf_issue(uuid)
      WorkPackage
        .joins(:bcf_issue)
        .where(project_id: project.id, "bcf_issues.uuid": uuid)
        .references(:bcf_issue).first
    end
  end
end

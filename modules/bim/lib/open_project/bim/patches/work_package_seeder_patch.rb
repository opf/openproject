module OpenProject::Bim::Patches::WorkPackageSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def create_or_update_work_package(attributes)
      uuid = attributes[:bcf_issue_uuid]
      if uuid

        start_date = calculate_start_date(attributes[:start])
        due_date = calculate_due_date(start_date, attributes[:duration])

        work_package = find_bcf_issue(uuid)

        work_package.update_columns(created_at: Time.now,
                                    author_id: user.id,
                                    assigned_to_id: find_assignee_id(attributes[:assigned_to]),
                                    start_date: start_date,
                                    due_date: due_date)

        update_parent(work_package, attributes)
      else
        create_work_package(attributes)
      end
    end

    def update_parent(work_package, attributes)
      return unless attributes[:parent]

      parent = WorkPackage.find_by(subject: attributes[:parent])
      return if parent.nil?

      work_package.parent = parent
      work_package.save!
    end

    def find_bcf_issue(uuid)
      WorkPackage
        .joins(:bcf_issue)
        .where(project_id: project.id, 'bcf_issues.uuid': uuid)
        .references(:bcf_issue).first
    end

    def find_assignee_id(name)
      return nil unless name.present?

      Principal.find_by(lastname: name).try(:id)
    end
  end
end


# Moves/copies an work_package to a new project and type
# Returns the moved/copied work_package on success, false on failure

class MoveWorkPackageService
  attr_accessor :work_package,
                :user

  def initialize(work_package, user)
    self.work_package = work_package
    self.user = user
  end

  def call(new_project, new_type = nil, options = {})
    if options[:no_transaction]
      move_to_project_without_transaction(new_project, new_type, options)
    else
      WorkPackage.transaction do
        move_to_project_without_transaction(new_project, new_type, options) ||
          raise(ActiveRecord::Rollback)
      end || false
    end
  end

  private

  def move_to_project_without_transaction(new_project, new_type = nil, options = {})
    work_package = options[:copy] ? WorkPackage.new.copy_from(self.work_package) : self.work_package

    if new_project &&
       work_package.project_id != new_project.id &&
       WorkPackage.allowed_target_projects_on_move(User.current).where(id: new_project.id).exists?

      work_package.delete_relations(work_package)
      # work_package is moved to another project
      # reassign to the category with same name if any
      new_category = if work_package.category.nil?
                       nil
                     else
                       new_project.categories.find_by_name(work_package.category.name)
                     end
      work_package.category = new_category
      # Keep the fixed_version if it's still valid in the new_project
      unless new_project.shared_versions.include?(work_package.fixed_version)
        work_package.fixed_version = nil
      end

      work_package.project = new_project

      enforce_cross_project_settings(work_package)
    end
    if new_type
      work_package.type = new_type
      work_package.reset_custom_values!
    end
    # Allow bulk setting of attributes on the work_package
    if options[:attributes]
      # before setting the attributes, we need to remove the move-related fields
      work_package.attributes =
        options[:attributes].except(:copy, :new_project_id, :new_type_id, :follow, :ids)
          .reject { |_key, value| value.blank? }
    end # FIXME this eliminates the case, where values shall be bulk-assigned to null,
    # but this needs to work together with the permit
    if options[:copy]
      work_package.author = User.current
      work_package.custom_field_values =
        self.work_package.custom_field_values.inject({}) do |h, v|
          h[v.custom_field_id] = v.value
          h
        end
      work_package.status = if options[:attributes] && options[:attributes][:status_id].present?
                              Status.find_by_id(options[:attributes][:status_id])
                            else
                              self.work_package.status
                            end
    else
      work_package.add_journal User.current, options[:journal_note] if options[:journal_note]
    end

    if work_package.save
      if options[:copy]
        create_and_save_journal_note work_package, options[:journal_note]
      else
        # Manually update project_id on related time entries
        TimeEntry.update_all("project_id = #{new_project.id}", work_package_id: work_package.id)

        work_package.children.each do |child|
          child_service = self.class.new(child, user)
          unless child_service.call(new_project, nil, options.merge(no_transaction: true))
            # Move failed and transaction was rollback'd
            return false
          end
        end
      end
    else
      return false
    end
    work_package
  end

  def enforce_cross_project_settings(work_package)
    parent_in_project =
      work_package.parent.nil? || work_package.parent.project == work_package.project

    work_package.parent_id =
      nil unless Setting.cross_project_work_package_relations? || parent_in_project
  end

  def create_and_save_journal_note(work_package, journal_note)
    if work_package && journal_note
      work_package.add_journal User.current, journal_note
      work_package.save!
    end
  end
end

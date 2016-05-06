
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
      move_without_transaction(new_project, new_type, options)
    else
      WorkPackage.transaction do
        move_without_transaction(new_project, new_type, options) ||
          raise(ActiveRecord::Rollback)
      end || false
    end
  end

  private

  def move_without_transaction(new_project, new_type = nil, options = {})
    attributes = options[:attributes] || {}

    modified_work_package = copy_or_move(options[:copy], new_project, new_type, attributes)

    if options[:copy]
      return false unless copy(modified_work_package, attributes, options)
    else
      return false unless move(modified_work_package, new_project, options)
    end

    modified_work_package
  end

  def copy_or_move(make_copy, new_project, new_type, attributes)
    modified_work_package = if make_copy
                              WorkPackage.new.copy_from(work_package)
                            else
                              work_package
                            end

    move_to_project(modified_work_package, new_project)

    move_to_type(modified_work_package, new_type)

    # Reset cached custom values after project/type change
    modified_work_package.reset_custom_values!

    bulk_assign_attributes(modified_work_package, attributes)

    modified_work_package
  end

  def copy(modified_work_package, attributes, options)
    set_default_values_on_copy(modified_work_package, attributes)

    return false unless modified_work_package.save

    create_and_save_journal_note modified_work_package, options[:journal_note]

    true
  end

  def move(modified_work_package, new_project, options)
    if options[:journal_note]
      modified_work_package.add_journal user, options[:journal_note]
    end

    return false unless modified_work_package.save

    move_time_entries(modified_work_package, new_project)

    return false unless move_children(modified_work_package, new_project, options)

    true
  end

  def move_to_project(work_package, new_project)
    if new_project &&
       work_package.project_id != new_project.id &&
       allowed_to_move_to_project?(new_project)

      delete_relations(work_package)

      reassign_category(work_package, new_project)

      # Keep the fixed_version if it's still valid in the new_project
      unless new_project.shared_versions.include?(work_package.fixed_version)
        work_package.fixed_version = nil
      end

      work_package.project = new_project

      enforce_cross_project_settings(work_package)
    end
  end

  def move_to_type(work_package, new_type)
    if new_type
      work_package.type = new_type
    end
  end

  def bulk_assign_attributes(work_package, attributes)
    # Allow bulk setting of attributes on the work_package
    if attributes
      # before setting the attributes, we need to remove the move-related fields
      work_package.attributes =
        attributes.except(:copy, :new_project_id, :new_type_id, :follow, :ids)
          .reject { |_key, value| value.blank? }
    end # FIXME this eliminates the case, where values shall be bulk-assigned to null,
    # but this needs to work together with the permit
  end

  def set_default_values_on_copy(work_package, attributes)
    work_package.author = user

    assign_status_or_default(work_package, attributes[:status_id])
  end

  def move_children(work_package, new_project, options)
    work_package.children.each do |child|
      child_service = self.class.new(child, user)
      unless child_service.call(new_project, nil, options.merge(no_transaction: true))
        # Move failed and transaction was rollback'd
        return false
      end
    end

    true
  end

  def move_time_entries(work_package, new_project)
    # Manually update project_id on related time entries
    TimeEntry.where(work_package_id: work_package.id).update_all("project_id = #{new_project.id}")
  end

  def enforce_cross_project_settings(work_package)
    parent_in_project =
      work_package.parent.nil? || work_package.parent.project == work_package.project

    work_package.parent_id =
      nil unless Setting.cross_project_work_package_relations? || parent_in_project
  end

  def create_and_save_journal_note(work_package, journal_note)
    if journal_note
      work_package.add_journal user, journal_note
      work_package.save!
    end
  end

  def allowed_to_move_to_project?(new_project)
    WorkPackage
      .allowed_target_projects_on_move(user)
      .where(id: new_project.id)
      .exists?
  end

  def reassign_category(work_package, new_project)
    # work_package is moved to another project
    # reassign to the category with same name if any
    new_category = if work_package.category.nil?
                     nil
                   else
                     new_project.categories.find_by(name: work_package.category.name)
                   end
    work_package.category = new_category
  end

  def assign_status_or_default(work_package, status_id)
    status = if status_id.present?
               Status.find_by(id: status_id)
             else
               self.work_package.status
             end

    work_package.status = status
  end

  def delete_relations(work_package)
    unless Setting.cross_project_work_package_relations?
      work_package.relations_from.clear
      work_package.relations_to.clear
    end
  end
end

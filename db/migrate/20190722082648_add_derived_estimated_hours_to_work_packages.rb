class AddDerivedEstimatedHoursToWorkPackages < ActiveRecord::Migration[5.2]
  class WorkPackageWithRelations < ActiveRecord::Base
    self.table_name = "work_packages"

    scope :with_children, ->(*args) do
      rel = "relations"
      wp = "work_packages"

      query = "EXISTS (SELECT 1 FROM #{rel} WHERE #{rel}.from_id = #{wp}.id AND #{rel}.hierarchy > 0 LIMIT 1)"

      where(query)
    end
  end

  def change
    add_column :work_packages, :derived_estimated_hours, :float
    add_column :work_package_journals, :derived_estimated_hours, :float

    reversible do |change|
      change.up do
        WorkPackage.transaction do
          migrate_to_derived_estimated_hours!
        end
      end
    end
  end

  # Before this migration all work packages who have children had their
  # estimated hours set based on their children through the UpdateAncestorsService.
  #
  # We move this value to the derived_estimated_hours column and clear
  # the estimated_hours column. In the future users can estimte the time
  # for parent work pacages separately there while the UpdateAncestorsService
  # only touches the derived_estimated_hours column.
  def migrate_to_derived_estimated_hours!
    last_id = Journal.order(id: :desc).limit(1).pluck(:id).first || 0
    wp_journals = "work_package_journals"
    work_packages = WorkPackageWithRelations.with_children

    work_packages.update_all("derived_estimated_hours = estimated_hours, estimated_hours = NULL")

    create_journals_for work_packages
    create_work_package_journals last_id: last_id
  end

  ##
  # Creates a new journal for each work package with the next version.
  # The respective work_package journal is created in a separate step.
  def create_journals_for(work_packages, author: journal_author, notes: journal_notes)
    WorkPackage.connection.execute("
      INSERT INTO #{Journal.table_name} (journable_type, journable_id, user_id, notes, created_at, version, activity_type)
      SELECT
        'WorkPackage',
        parents.id,
        #{author.id},
        '#{notes}',
        NOW(),
        (SELECT MAX(version) FROM journals WHERE journable_id = parents.id AND journable_type = 'WorkPackage') + 1,
        'work_packages'
      FROM (
        #{work_packages.select(:id).to_sql}
      ) AS parents
    ")
  end

  def journal_author
    @journal_author ||= User.system
  end

  def journal_notes
    "_'Estimated hours' changed to 'Derived estimated hours'_"
  end

  ##
  # Creates work package journals for the move of estimated_hours to derived_estimated_hours.
  #
  # For each newly created journal (see above) it inserts the respective work package's
  # current estimated_hours (deleted) and derived estimated hours (previously estimated hours).
  # All other attributes of the work package journal entry are copied from the previous
  # work package journal entry (i.e. the values are not changed).
  #
  # @param last_id [Integer] The ID of the last journal before the journals for the migration were created.
  def create_work_package_journals(last_id:)
    journals = "journals"
    wp_journals = "work_package_journals"
    work_packages = "work_packages"

    WorkPackage.connection.execute("
      INSERT INTO #{WorkPackageJournal.table_name} (
        journal_id, type_id, project_id, subject, description, due_date, category_id, status_id,
        assigned_to_id, priority_id, fixed_version_id, author_id, done_ratio,
        start_date, parent_id, responsible_id, cost_object_id, story_points, remaining_hours,
        estimated_hours, derived_estimated_hours
      )
      SELECT *
      FROM (
        SELECT
          #{journals}.id, #{wp_journals}.type_id, #{wp_journals}.project_id, #{wp_journals}.subject,
          #{wp_journals}.description, #{wp_journals}.due_date, #{wp_journals}.category_id, #{wp_journals}.status_id,
          #{wp_journals}.assigned_to_id, #{wp_journals}.priority_id, #{wp_journals}.fixed_version_id, #{wp_journals}.author_id,
          #{wp_journals}.done_ratio, #{wp_journals}.start_date, #{wp_journals}.parent_id, #{wp_journals}.responsible_id,
          #{wp_journals}.cost_object_id, #{wp_journals}.story_points, #{wp_journals}.remaining_hours,
          #{work_packages}.estimated_hours, #{work_packages}.derived_estimated_hours
        FROM #{journals} -- take the journal ID from here (ID of newly created journals from above)
          LEFT JOIN #{work_packages} -- take the current (derived) estimated hours from here
          ON #{work_packages}.id = #{journals}.journable_id AND #{journals}.journable_type = 'WorkPackage'
          LEFT JOIN #{wp_journals} -- keep everything else the same
          ON #{wp_journals}.journal_id = (
            SELECT MAX(id)
            FROM #{journals}
            WHERE journable_id = #{work_packages}.id AND journable_type = 'WorkPackage' AND #{journals}.id <= #{last_id}
            -- we are selecting the latest previous (hence <= last_id) work package journal here to copy its values
          )
        WHERE #{journals}.id > #{last_id} -- make sure to only create entries for the newly created journals
      ) AS results
    ")
  end
end

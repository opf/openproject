#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/utils'

class PlanningElementDataToWorkPackages < ActiveRecord::Migration[4.2]
  include Migration::Utils

  def up
    add_new_id_column

    return if skip_on_no_planning_elements

    say_with_time 'Inserting planning elements into the work packages table' do
      add_planning_elements_to_work_packages
    end

    say_with_time 'Rebuilding the nested set attributes on the newly inserted work packages' do
      rebuild_nested_set
    end
  end

  def down
    say_with_time 'Removing work packages that where planning elements' do
      remove_planning_elements_from_work_packages
    end

    remove_new_id_column
  end

  private

  def add_new_id_column
    add_column :legacy_planning_elements, :new_id, :integer
  end

  def remove_new_id_column
    remove_column :legacy_planning_elements, :new_id
  end

  # Appends the planning elements stored in
  # legacy_planning_elements to the work_packages table.
  #
  # Some values are reconstructed from other tables and some are set
  # with default values.
  def add_planning_elements_to_work_packages
    default_status_id = get_default_status_id
    default_priority_id = get_default_priority_id

    with_temporary_legacy_id_column do
      insert_legacy_planning_elements_entries_to_work_packages(default_status_id, default_priority_id)

      update_legacy_planning_elements_with_new_id
    end
  end

  # Sets the nested set attributes parent_id, root_id, lft and rgt value
  # to their now correct values.
  def rebuild_nested_set
    update_parent_id

    set_root_id

    set_lft_and_rgt
  end

  def get_default_status_id
    default_status = select_one <<-SQL
      SELECT id
      FROM #{db_statuses_table}
      WHERE is_default = true OR position = 1
      ORDER BY is_default DESC
      LIMIT 1
    SQL

    default_status['id']
  end

  def get_default_priority_id
    default_priority = select_one <<-SQL
      SELECT id
      FROM #{db_enumerations_table}
      WHERE #{db_column('is_default')} = #{quoted_true}
      AND #{db_column('type')} = #{quote('IssuePriority')}
      LIMIT 1
    SQL

    default_priority['id']
  end

  # Apends all entries from the legacy_planning_elements table to
  # the work_packages table.
  #
  # Take most of the values from legacy_planning_elements.
  # But take:
  # * what was provided for status_id and priority_id
  # * the type_id value from the legacy_planning_element_types table that got
  #   an updated id by 20130916123916_planning_element_types_data_to_types.rb
  # * the author_id from the user_id column of the first journal
  #   (legacy_journals)
  # * the lock_version from the maximum value of the version column of all
  #   a planning_element's journals
  #
  # In case a legacy planning element did not have a planning_element_type_id
  # the new type_id will be 0. This will have to be fixed. The plan is to do this
  # via seed. Look there and you will find the fix if this comment is still up to date.
  #
  # This method will create a false parent_id. The parent_id column is
  # still set to the id, the now work package has in the legacy_planning_elements
  # table.
  def insert_legacy_planning_elements_entries_to_work_packages(default_status_id, default_priority_id)
    insert <<-SQL
      INSERT INTO #{db_work_packages_table}
        (
          subject,
          description,
          project_id,
          responsible_id,
          type_id,
          start_date,
          due_date,
          status_id,
          priority_id,
          author_id,
          created_at,
          updated_at,
          deleted_at,
          parent_id,
          lock_version,
          legacy_planning_element_id
        )
      SELECT
        #{db_planning_elements_table}.#{db_column('name')},
        #{db_planning_elements_table}.#{db_column('description')},
        #{db_planning_elements_table}.#{db_column('project_id')},
        #{db_planning_elements_table}.#{db_column('responsible_id')},
        COALESCE(#{db_planning_element_types_table}.#{db_column('new_id')}, 0),
        #{db_planning_elements_table}.#{db_column('start_date')},
        #{db_planning_elements_table}.#{db_column('end_date')},
        #{default_status_id} AS status_id,
        #{default_priority_id} AS priority_id,
        #{db_journals_table}.#{db_column('user_id')} AS author_id,
        #{db_planning_elements_table}.#{db_column('created_at')},
        #{db_planning_elements_table}.#{db_column('updated_at')},
        #{db_planning_elements_table}.#{db_column('deleted_at')},
        #{db_planning_elements_table}.#{db_column('parent_id')},
        MAX(version_journals.#{db_column('version')}) AS lock_version,
        #{db_planning_elements_table}.#{db_column('id')}
      FROM #{db_planning_elements_table}
      LEFT JOIN #{db_planning_element_types_table}
        ON #{db_planning_elements_table}.#{db_column('planning_element_type_id')} = #{db_planning_element_types_table}.#{db_column('id')}
      LEFT JOIN #{db_journals_table}
        ON #{db_journals_table}.#{db_column('journaled_id')} = #{db_planning_elements_table}.#{db_column('id')}
        AND #{db_journals_table}.#{db_column('version')} = 1
        AND #{db_journals_table}.#{db_column('type')} = #{quote('Timelines_PlanningElementJournal')}
      LEFT JOIN #{db_journals_table} AS version_journals
        ON version_journals.#{db_column('journaled_id')} = #{db_planning_elements_table}.#{db_column('id')}
        AND version_journals.#{db_column('type')} = #{quote('Timelines_PlanningElementJournal')}
      GROUP BY
        #{db_journals_table}.#{db_column('version')},
        #{db_planning_elements_table}.#{db_column('name')},
        #{db_planning_elements_table}.#{db_column('description')},
        #{db_planning_elements_table}.#{db_column('project_id')},
        #{db_planning_elements_table}.#{db_column('responsible_id')},
        #{db_planning_element_types_table}.#{db_column('new_id')},
        #{db_planning_elements_table}.#{db_column('start_date')},
        #{db_planning_elements_table}.#{db_column('end_date')},
        #{db_journals_table}.#{db_column('user_id')},
        #{db_planning_elements_table}.#{db_column('created_at')},
        #{db_planning_elements_table}.#{db_column('updated_at')},
        #{db_planning_elements_table}.#{db_column('deleted_at')},
        #{db_planning_elements_table}.#{db_column('parent_id')},
        #{db_planning_elements_table}.#{db_column('id')}
    SQL
  end

  # Adds a column to the work packages table and removes it
  # once the block is executed.
  def with_temporary_legacy_id_column
    add_column :work_packages, :legacy_planning_element_id, :integer

    yield

    remove_column :work_packages, :legacy_planning_element_id
  end

  def update_legacy_planning_elements_with_new_id
    update <<-SQL
      UPDATE #{db_planning_elements_table}
      SET new_id = (SELECT #{db_work_packages_table}.#{db_column('id')}
                    FROM #{db_work_packages_table}
                    WHERE #{db_work_packages_table}.#{db_column('legacy_planning_element_id')} = #{db_planning_elements_table}.#{db_column('id')})
    SQL
  end

  # Set the parent_id column of every work package that used to be a
  # planning element (has a corresponding entry in the legacy_planning_elements
  # table) to the new id of the parent work package.
  def update_parent_id
    update <<-SQL
      UPDATE #{db_work_packages_table}
      SET parent_id = (SELECT #{db_planning_elements_table}.#{db_column('new_id')}
                       FROM #{db_planning_elements_table}
                       WHERE #{db_planning_elements_table}.#{db_column('id')} = #{db_work_packages_table}.#{db_column('parent_id')})
      WHERE EXISTS (SELECT *
                    FROM #{db_planning_elements_table}
                    WHERE #{db_work_packages_table}.#{db_column('id')} = #{db_planning_elements_table}.#{db_column('new_id')})
    SQL
  end

  def set_root_id
    set_root_id_for_non_children

    set_root_id_for_children
  end

  # Set the root_id column of every work package that used to be a planning
  # element (has a corresponding entry in the legacy_planning_elements
  # table) and that does not have a parent_id to it's id column value.
  def set_root_id_for_non_children
    update <<-SQL
      UPDATE #{db_work_packages_table}
      SET #{db_column('root_id')} = #{db_work_packages_table}.#{db_column('id')}
      WHERE EXISTS (SELECT *
                    FROM #{db_planning_elements_table}
                    WHERE #{db_work_packages_table}.#{db_column('id')} = #{db_planning_elements_table}.#{db_column('new_id')})
      AND #{db_work_packages_table}.#{db_column('parent_id')} IS NULL
    SQL
  end

  # Set the root_id column of every work package that used to be a planning
  # element (has a corresponding entry in the legacy_planning_elements
  # table) and that does have a parent_id to the new id of the former planning element
  # that is the last element in the work package's ancestor chain.
  #
  # The approach here is top-down. Each entry who's root_id is NULL receives
  # the root_id of it's parent's root_id.
  # If the parent's root_id is set (e.g. 3029), this value is set to be the entry's
  # root_id.
  # If the parent's root_id is not set (i.e. NULL), this value is also set to be the
  # entry's root_id. This does no harm.
  # This is than repeated until no more entries without a root_id exist, i.e. are updated.
  #
  # Expects the root_id column of every work package that does not
  # need to be addressed to be set, e.g. by using
  # set_root_id_for_children
  def set_root_id_for_children
    num_updated = 1

    while num_updated != 0
      num_updated = update set_root_id_for_children_db_statement
    end
  end

  def set_root_id_for_children_db_statement
    if mysql?

      <<-SQL
        UPDATE #{db_work_packages_table} AS child
          JOIN #{db_work_packages_table} AS parent
            ON (child.#{db_column('parent_id')} = parent.#{db_column('id')})
        SET child.#{db_column('root_id')} = parent.#{db_column('id')}
        WHERE child.#{db_column('root_id')} IS NULL
      SQL

    else

      <<-SQL
        UPDATE #{db_work_packages_table}
        SET #{db_column('root_id')} = (SELECT parent.#{db_column('root_id')}
                                       FROM #{db_work_packages_table} AS parent
                                       WHERE parent.#{db_column('id')} = #{db_work_packages_table}.#{db_column('parent_id')})
        WHERE #{db_work_packages_table}.#{db_column('root_id')} IS NULL
      SQL

    end
  end

  # Sets the lft and rgt columns of the newly added work packages
  #
  # This employs a method of WorkPackage, i.e. of a patch applied to
  # awesome_nested_set which is included by WorkPackage.
  #
  # The alternative would be to copy over the code.
  def set_lft_and_rgt
    WorkPackage.selectively_rebuild_silently!
  end

  # Removes all work packages that where planning elements (have a
  # corresponding entry in the legacy_planning_elements table)
  def remove_planning_elements_from_work_packages
    delete <<-SQL
      DELETE FROM #{db_work_packages_table}
      WHERE
        id IN (SELECT #{db_column('new_id')}
               FROM #{db_planning_elements_table})
    SQL
  end

  def skip_on_no_planning_elements
    planning_element = suppress_messages {
      select_one <<-SQL
        SELECT #{db_column('id')}
        FROM #{db_planning_elements_table}
        LIMIT 1
      SQL
    }

    if planning_element.present?
      false
    else
      say 'There are no legacy planning elements to migrate... skipping.'

      true
    end
  end

  def db_statuses_table
    @db_statuses_table ||= quote_table_name('issue_statuses')
  end

  def db_enumerations_table
    @db_enumerations_table ||= quote_table_name('enumerations')
  end

  def db_work_packages_table
    @db_work_packages_table ||= quote_table_name('work_packages')
  end

  def db_planning_elements_table
    @db_planning_elements_table ||= quote_table_name('legacy_planning_elements')
  end

  def db_planning_element_types_table
    @db_planning_element_types_table ||= quote_table_name('legacy_planning_element_types')
  end

  def db_journals_table
    @db_journals_table ||= quote_table_name('legacy_journals')
  end

  def db_column(name)
    quote_column_name(name)
  end

  def say_with_time(message)
    super do
      suppress_messages do
        yield
      end
    end
  end
end

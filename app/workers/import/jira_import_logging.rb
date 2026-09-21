# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  module JiraImportLogging
    JIRA_OBJECT_TYPES = %i[project attachment comment issue user customField status issueType priority].freeze

    # Marks an optional keyword as "not passed by this call" so with_jira_log_tags can tell that
    # apart from an explicit nil and skip re-emitting it, letting nested calls inherit it from an
    # outer with_jira_log_tags block instead of repeating it.
    NOT_GIVEN = Object.new.freeze
    private_constant :NOT_GIVEN

    # Wraps the block in Rails.logger.tagged with the tags every Jira importer log message is
    # expected to carry, so each message can be traced back to the run, the GoodJob execution and
    # batch it happened in, and the Jira object it was about.
    #
    # Rails.logger.tagged only ever appends tags, it never replaces one already pushed by an
    # enclosing call. So when nesting with_jira_log_tags inside another one of its own blocks,
    # only pass the keywords that are actually new at that point (e.g. jira_object_id_or_name once
    # it becomes known) and leave the rest out - they're already active from the outer call and
    # repeating them would just print the same tag twice. This includes jira_import_id (and the
    # run_id/good_job_id tags derived from it): the outermost call in a chain must pass it since it
    # has no reliable derivation (e.g. a job's first perform argument) across every Jira import
    # job, but any call nested inside one that already tagged it should leave it out too.
    #
    # jira_object_type must be one of JIRA_OBJECT_TYPES when given; omit it (rather than passing
    # nil) for messages about the run as a whole rather than one Jira object, e.g. a job's
    # start/finish.
    def with_jira_log_tags(jira_import_id: NOT_GIVEN, jira_object_type: NOT_GIVEN, jira_project_id: NOT_GIVEN,
                           jira_issue_key: NOT_GIVEN, jira_object_id_or_name: NOT_GIVEN, &)
      validate_jira_object_type!(jira_object_type)

      already_tagged = jira_import_id_tagged?
      if jira_import_id == NOT_GIVEN && !already_tagged
        raise ArgumentError, "jira_import_id must be given unless an enclosing with_jira_log_tags call already set it"
      end

      tags = jira_log_tags(already_tagged:, jira_import_id:, jira_object_type:, jira_project_id:, jira_issue_key:,
                           jira_object_id_or_name:)
      Rails.logger.tagged(*tags, &)
    end

    private

    # A false/nil jira_object_type (e.g. a hash lookup that missed) is treated the same as not
    # having passed it at all: nothing to validate, and no tag emitted for it.
    def validate_jira_object_type!(jira_object_type)
      return unless jira_object_type && jira_object_type != NOT_GIVEN
      return if JIRA_OBJECT_TYPES.include?(jira_object_type.to_sym)

      raise ArgumentError, "invalid jira_object_type: #{jira_object_type.inspect}"
    end

    def jira_log_tags(already_tagged:, jira_import_id:, jira_object_type:, jira_project_id:, jira_issue_key:,
                      jira_object_id_or_name:)
      tags = []
      unless already_tagged
        tags << "run_id:#{jira_import_run_id}"
        tags << "good_job_id:#{job_id}"
      end
      tags << "jira_import_id:#{jira_import_id}" unless jira_import_id == NOT_GIVEN
      tags << "jira_project_id:#{jira_project_id}" unless jira_project_id == NOT_GIVEN
      tags << "jira_issue_key:#{jira_issue_key}" unless jira_issue_key == NOT_GIVEN
      tags << "jira_object_type:#{jira_object_type}" if jira_object_type && jira_object_type != NOT_GIVEN
      tags << "jira_object_id_or_name:#{jira_object_id_or_name}" unless jira_object_id_or_name == NOT_GIVEN
      tags
    end

    # The GoodJob batch id of the staged import run this job belongs to, if any (jobs enqueued
    # outside of Import::JiraStagedImportJob's batch, e.g. instance/projects meta data fetching,
    # revert and finalize, have no batch and this is nil).
    def jira_import_run_id
      GoodJob::Job.where(id: job_id).pick(:batch_id)
    end

    def jira_import_id_tagged?
      Rails.logger.formatter.current_tags.any? { |tag| tag.start_with?("jira_import_id:") }
    end
  end
end

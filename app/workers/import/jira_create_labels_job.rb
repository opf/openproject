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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  class JiraCreateLabelsJob < ApplicationJob
    include Import::JiraOpenProjectReferenceCreation
    include Import::JiraJobUtils

    DISTINCT_LABEL_NAMES = Arel.sql("DISTINCT jsonb_array_elements_text(payload -> 'fields' -> 'labels')")

    def text
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title")
    end

    def perform(jira_import_id)
      tagged_log("jira_import_id:#{jira_import_id}", "jira_object_type:label") do
        Rails.logger.debug "Creating labels started"
        @jira_import = Import::JiraImport.find(jira_import_id)
        @system_user = User.system

        jira_label_names.each do |name|
          Rails.logger.tagged("jira_object_id_or_name:#{name}") { create_label(name) }
        end
        Rails.logger.debug "Creating labels finished"
      end
    end

    private

    def jira_label_names
      Import::JiraIssue
        .where(jira_import_id: @jira_import.id)
        .where("jsonb_typeof(payload -> 'fields' -> 'labels') = 'array'")
        .pluck(DISTINCT_LABEL_NAMES)
        .filter_map { it.to_s.squish.presence }
        .uniq(&:downcase)
    end

    def create_label(name)
      Rails.logger.debug "Creating label"
      ApplicationRecord.transaction do
        service_call = Labels::CreateService.new(user: @system_user).call(name:)
        next reference_existing_label(name) if name_taken?(service_call)

        if service_call.failure?
          Rails.logger.error service_call.message
          raise service_call.message
        end

        create_reference!(op_leg: service_call.result, jira_leg: nil, jira_import: @jira_import, uses_existing: false)
      end
    end

    def name_taken?(service_call)
      service_call.errors.symbols_for(:name).include?(:taken)
    end

    def reference_existing_label(name)
      Rails.logger.debug "Found existing label"
      label = Label.named(name).first!
      return if referenced?(label)

      create_reference!(op_leg: label, jira_leg: nil, jira_import: @jira_import, uses_existing: true)
    end

    def referenced?(label)
      Import::JiraOpenProjectReference.exists?(jira_import_id: @jira_import.id,
                                               op_entity_class: label.class.to_s,
                                               op_entity_id: label.id)
    end
  end
end

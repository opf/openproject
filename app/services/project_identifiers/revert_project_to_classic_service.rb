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

module ProjectIdentifiers
  # Reverts a single project back to classic identifier mode by restoring its
  # project identifier to the most-recent classic-format slug from FriendlyId
  # history. If no classic slug exists (e.g. the project was created in semantic
  # mode), a new classic identifier is generated via Project.suggest_identifier.
  #
  # WP sequence_number/identifier, WorkPackageSemanticAlias rows, and
  # wp_sequence_counter are intentionally left intact so that a back-switch to
  # semantic mode can resume without data loss.
  class RevertProjectToClassicService
    def initialize(project)
      @project = project
    end

    def call
      restore_classic_identifier
    end

    private

    attr_reader :project

    def restore_classic_identifier
      classic_id = identifier_generator.restore_identifier(project) ||
                   identifier_generator.suggest_identifier(project.name)
      save_identifier!(classic_id)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      handle_update_failure(classic_id, e)
    end

    def handle_update_failure(classic_id, error)
      Rails.logger.warn "#{self.class}: Could not set identifier '#{classic_id}' for project #{project.id}; " \
                        "falling back to a random identifier. (#{error.message})"
      save_identifier!("project-#{SecureRandom.alphanumeric(5).downcase}")
    end

    def save_identifier!(identifier)
      # Suppress notifications: this is a background system operation, not a user edit.
      Journal::NotificationConfiguration.with(false) do
        project.update!(identifier:)
      end
    end

    def identifier_generator
      @identifier_generator ||= ProjectIdentifiers::ClassicIdentifierSuggestionGenerator.new
    end
  end
end

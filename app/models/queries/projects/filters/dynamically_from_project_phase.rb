# frozen_string_literal: true

# -- copyright
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
# ++

module Queries::Projects::Filters::DynamicallyFromProjectPhase
  extend ActiveSupport::Concern

  included do
    private

    attr_accessor :project_phase_definition
  end

  class_methods do
    def all_for(context = nil)
      all_phase_definitions
        .flat_map do |phase|
        create_from_phase(phase, context)
      rescue ::Queries::Filters::InvalidError
        Rails.logger.error "Failed to map phase definition filter for #{phase.name} (CF##{phase.id})."
        nil
      end
    end

    def create!(name:, **options)
      project_phase_definition = find_by_accessor(name)
      raise ::Queries::Filters::InvalidError if project_phase_definition.nil?

      new(name, options.merge(project_phase_definition:))
    end

    def key
      raise SubclassResponsibilityError
    end

    private

    def all_phase_definitions
      key = %w[Queries::Projects::Filters::DynamicallyFromProjectPhase all_phase_definitions]

      RequestStore.fetch(key) { Project::PhaseDefinition.all.to_a }
    end

    def find_by_accessor(name)
      match = name.match key

      if match.present? && match[:id].to_i > 0
        all_phase_definitions
          .detect { |definition| accessor_matches?(definition, match) }
      end
    end

    def create_from_phase(_phase, _context)
      raise SubclassResponsibilityError
    end

    def accessor_matches?(definition, match)
      definition.id == match[:id].to_i
    end
  end

  def initialize(name, options = {})
    @project_phase_definition = options[:project_phase_definition]

    super
  end
end

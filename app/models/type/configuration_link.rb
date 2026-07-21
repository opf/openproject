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

# A single reuse link: a type borrows one configuration aspect from a source type.
# Absence of a row for (type, aspect) means the type owns that aspect (Independent).
class Type
  class ConfigurationLink < ApplicationRecord
    ASPECTS = [
      PDF_EXPORT = "pdf_export",
      DEFAULTS = "defaults",
      WORKFLOWS = "workflows",
      AUTOMATIONS = "automations",
      PROJECTS = "projects",
      FORM_CONFIGURATION = "form_configuration"
    ].freeze

    # Aspects a new sub-type links to its parent on creation. The remaining aspects
    # start Independent until their linked behaviour is implemented.
    DEFAULT_PARENT_LINK_ASPECTS = [PDF_EXPORT, DEFAULTS].freeze

    belongs_to :type, optional: false
    belongs_to :source, class_name: "Type", optional: false

    enum :aspect, ASPECTS.index_with(&:itself), validate: true

    validates :type_id, uniqueness: { scope: :aspect }
    validate :source_would_not_create_cycle

    private

    # Rejects a link whose source chain already reaches this type, so the per-aspect
    # source graph stays acyclic. A self-link is the degenerate 1-cycle and is caught here.
    def source_would_not_create_cycle
      return if source_id.blank?

      # `seen` tolerates cyclic rows created before this validation existed (legacy
      # FND-129 data): it lets the walk terminate instead of hanging on such data.
      node = source
      seen = Set.new
      while node && seen.add?(node.id)
        return errors.add(:source_id, :would_create_cycle) if node.id == type_id

        node = node.source_for(aspect)
      end
    end
  end
end

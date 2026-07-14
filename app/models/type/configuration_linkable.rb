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

# Reuse of a type's configuration aspects (PDF export, subject patterns) from a
# source type. Mode is derived from link presence: a link means Linked, its
# absence means Independent. This is the shared seam FND-101/102 extend with
# further aspects, and the deferred resolution/copy/cycle work builds on top of.
class Type
  module ConfigurationLinkable
    extend ActiveSupport::Concern

    included do
      has_many :configuration_links,
               class_name: "Type::ConfigurationLink",
               dependent: :destroy
      has_many :dependent_configuration_links,
               class_name: "Type::ConfigurationLink",
               foreign_key: :source_id,
               inverse_of: :source,
               dependent: :restrict_with_error

      # A sub-type defaults to Linked-to-parent for the aspects whose linked
      # behaviour is implemented; see DEFAULT_PARENT_LINK_ASPECTS.
      after_create :link_default_aspects_to_parent, if: :subtype?
    end

    def linked?(aspect)
      configuration_links.exists?(aspect:)
    end

    def source_for(aspect)
      configuration_links.find_by(aspect:)&.source
    end

    def link!(aspect, source:)
      configuration_links.find_or_initialize_by(aspect:).update!(source:)
    end

    # Switch an aspect to Independent. When a source is given, its resolved
    # configuration is copied onto this type once (adopt) before the link is severed.
    def make_independent!(aspect, source: nil)
      copy_configuration_from(source, aspect) if source && source != self
      configuration_links.where(aspect:).destroy_all
    end

    # Walks the link chain to the type that actually owns the aspect (Independent).
    # The visited-set guard keeps it terminating even before transitive cycle
    # prevention lands.
    #
    # Guarded by the subtypes feature flag: with the flag off, links are ignored
    # and every type resolves to its own stored configuration.
    def effective_source_for(aspect)
      return self unless OpenProject::FeatureDecisions.subtypes_active?

      node = self
      seen = Set.new
      node = node.source_for(aspect) while node.linked?(aspect) && seen.add?(node.id)
      node
    end

    def effective_patterns
      effective_source_for(Type::ConfigurationLink::PATTERNS).patterns
    end

    def effective_pdf_export_templates
      effective_source_for(Type::ConfigurationLink::PDF_EXPORT).pdf_export_templates
    end

    # One-time adoption: copy the source's resolved configuration for one aspect
    # onto this type. Used when switching to Independent from a chosen source.
    # deep_dup keeps the copy from aliasing the source's stored value.
    def copy_configuration_from(source, aspect)
      owner = source.effective_source_for(aspect)
      case aspect
      when Type::ConfigurationLink::PATTERNS
        update!(patterns: owner.patterns.deep_dup)
      when Type::ConfigurationLink::PDF_EXPORT
        update!(pdf_export_templates_config: owner.pdf_export_templates_config.deep_dup)
      end
    end

    private

    def link_default_aspects_to_parent
      Type::ConfigurationLink::DEFAULT_PARENT_LINK_ASPECTS.each { |aspect| link!(aspect, source: parent) }
    end
  end
end

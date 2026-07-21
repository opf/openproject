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

    prepended do
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

    # Walks the link chain to the type that actually owns the aspect (Independent).
    # The visited-set guard tolerates cyclic rows created before write-time cycle
    # prevention (FND-133) existed, keeping resolution terminating.
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

    # Readers of linked aspects resolve through the link, so plain `type.patterns`
    # is always the configuration in force. Separate `effective_*` readers only stay
    # correct while every caller remembers they exist, and a root type behaves the
    # same either way — so a missed call site still passes its tests.
    #
    # Writers stay untouched: assigning always writes this type's own row.
    def patterns
      source = inherited_configuration_source(Type::ConfigurationLink::DEFAULTS)
      return super if source.nil?

      source.patterns
    end

    def description
      source = inherited_configuration_source(Type::ConfigurationLink::DEFAULTS)
      return super if source.nil?

      source.description
    end

    def artefact_export_mode
      source = inherited_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.artefact_export_mode
    end

    # Resolved here rather than on #pdf_export_templates so that the object handed out
    # always wraps the receiving type: it is a mutator as much as a reader, and
    # returning the source's would let a linked sub-type write the source's config.
    def export_templates_disabled
      source = inherited_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_disabled
    end

    def export_templates_order
      source = inherited_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_order
    end

    private

    # The type an aspect is inherited from, or nil when this type owns it. The nil is
    # what keeps the readers above from recursing: effective_source_for returns self
    # both for an unlinked aspect and while the subtypes flag is off.
    def inherited_configuration_source(aspect)
      source = effective_source_for(aspect)

      source unless source == self
    end

    def link_default_aspects_to_parent
      Type::ConfigurationLink::DEFAULT_PARENT_LINK_ASPECTS.each { |aspect| link!(aspect, source: parent) }
    end
  end
end

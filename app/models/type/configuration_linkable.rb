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

      # A variant defaults to Linked-to-parent for every configuration aspect.
      after_create :link_all_aspects_to_parent, if: :variant?
    end

    class_methods do
      # SQL for the single owning (terminal) type id of the aspect's link chain
      # starting at `type_id`. Recurses through type_configuration_links until a type
      # that isn't linked for the aspect (the owner). The `path` array is a cycle
      # guard tolerating rows that predate write-time cycle prevention (FND-133); a
      # pure cycle owns nothing and yields no row.
      #
      # Fully sanitized, so it can be inlined as a scalar subquery: it lets a query
      # resolve a linked type's effective owner without a separate round-trip.
      def effective_source_id_subquery(type_id, aspect)
        sanitize_sql_array([<<~SQL.squish, { type_id:, aspect: }])
          WITH RECURSIVE link_chain(node_id, path) AS (
            SELECT CAST(:type_id AS bigint), ARRAY[CAST(:type_id AS bigint)]
            UNION ALL
            SELECT l.source_id, cl.path || l.source_id
            FROM link_chain cl
            JOIN type_configuration_links l ON l.type_id = cl.node_id AND l.aspect = :aspect
            WHERE NOT l.source_id = ANY(cl.path)
          )
          SELECT cl.node_id FROM link_chain cl
          WHERE NOT EXISTS (
            SELECT 1 FROM type_configuration_links l2
            WHERE l2.type_id = cl.node_id AND l2.aspect = :aspect
          )
          LIMIT 1
        SQL
      end
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

    # Resolves the link chain to the type that actually owns the aspect (Independent),
    # in a single recursive query (see .effective_source_id_subquery). Returns `self`
    # unchanged when this type owns the aspect, so callers keep object identity in the
    # common case and avoid a reload.
    #
    # Guarded by the type_variants feature flag: with the flag off, links are ignored
    # and every type resolves to its own stored configuration. A new record has no
    # persisted links, so it owns every aspect.
    def effective_source_for(aspect)
      return self unless OpenProject::FeatureDecisions.type_variants_active?
      return self if new_record?

      terminal_id = self.class.connection.select_value(self.class.effective_source_id_subquery(id, aspect))
      return self if terminal_id.blank?

      terminal_id = terminal_id.to_i
      return self if terminal_id == id

      self.class.find(terminal_id)
    end

    # Readers of linked aspects resolve through the link, so a plain `type.patterns`
    # is always the configuration in force. Resolving in the reader rather than behind
    # a separate opt-in method is deliberate: a caller can't silently read its own value
    # by forgetting to opt in — a slip a root type would mask, since it reads the same
    # either way.
    #
    # Writers stay untouched: assigning always writes this type's own row.
    def patterns
      source = linked_configuration_source(Type::ConfigurationLink::DEFAULTS)
      return super if source.nil?

      source.patterns
    end

    def description
      source = linked_configuration_source(Type::ConfigurationLink::DEFAULTS)
      return super if source.nil?

      source.description
    end

    def artefact_export_mode
      source = linked_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.artefact_export_mode
    end

    # Resolved here rather than on #pdf_export_templates so that the object handed out
    # always wraps the receiving type: it is a mutator as much as a reader, and
    # returning the source's would let a linked variant write the source's config.
    def export_templates_disabled
      source = linked_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_disabled
    end

    def export_templates_order
      source = linked_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_order
    end

    # Follows the reader-override pattern above, but yields this type's own groups
    # while a change is pending: the switch-to-Independent copy assigns groups and
    # reads them back to sync active custom fields while the link still exists
    # (CopyConfiguration::FormConfigurationService), and must see what it just set.
    def attribute_groups
      source = linked_configuration_source(Type::ConfigurationLink::FORM_CONFIGURATION)
      return super if source.nil? || attribute_groups_changed?

      source.attribute_groups
    end

    # custom_fields resolves through the form source. Beware of reader-driven mutation:
    # currently, the only one is Jira import's `custom_fields <<`, but it runs on
    # a FORM_CONFIGURATION-independent type, so it reaches super.
    def custom_fields
      source = linked_configuration_source(Type::ConfigurationLink::FORM_CONFIGURATION)
      return super if source.nil?

      source.custom_fields
    end

    private

    # The type an aspect is linked to, or nil when this type owns it. The nil is
    # what keeps the readers above from recursing: effective_source_for returns self
    # both for an unlinked aspect and while the variants flag is off.
    def linked_configuration_source(aspect)
      source = effective_source_for(aspect)

      source unless source == self
    end

    # True when a lookup should resolve `aspect` through the link chain in SQL
    # rather than reading this type's own rows: variants on and the type persisted.
    def resolve_aspect_in_sql?
      !new_record? && OpenProject::FeatureDecisions.type_variants_active?
    end

    # `aspect`'s owning type id as an inlinable subquery, for a lookup that filters
    # on type_id (`type_id IN (…)`): it resolves a linked type's effective source in
    # the same query instead of a preceding resolution round-trip.
    def effective_source_id_ref(aspect)
      Arel.sql("(#{self.class.effective_source_id_subquery(id, aspect)})")
    end

    def link_all_aspects_to_parent
      Type::ConfigurationLink::ASPECTS.each { |aspect| link!(aspect, source: parent) }
    end
  end
end

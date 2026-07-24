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

      # A variant defaults to Linked-to-parent for the aspects whose linked
      # behaviour is implemented; see DEFAULT_PARENT_LINK_ASPECTS.
      after_create :link_default_aspects_to_parent, if: :variant?
    end

    class_methods do
      # The id of the type that owns +aspect+, starting from +type_id+: the terminal
      # of the link chain (the Independent type). Resolved in one recursive query that
      # walks type_configuration_links through the (type_id, aspect) index, so the cost
      # is independent of both chain depth and table size. The +path+ array guards
      # against legacy cyclic rows predating write-time cycle prevention (FND-133); a
      # pure cycle yields no row, meaning the type owns the aspect, so we return +type_id+.
      #
      # This method is the ONLY place the recursive SQL lives. Callers get a plain id
      # back and filter with an ordinary `where(type_id: …)`, so the query never leaks
      # into the rest of the code base as Arel or inlined subqueries.
      def effective_source_id(type_id, aspect)
        return type_id unless type_id && OpenProject::FeatureDecisions.type_variants_active?

        sql = sanitize_sql_array([<<~SQL.squish, { type_id:, aspect: }])
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
        connection.select_value(sql)&.to_i || type_id
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

    # This type's effective owner id for +aspect+ (see .effective_source_id). A new
    # record has no persisted links, so it owns every aspect.
    def effective_source_id_for(aspect)
      return id if new_record?

      self.class.effective_source_id(id, aspect)
    end

    # The type that actually owns +aspect+, resolved through the link chain. Returns
    # +self+ when this type owns it, so callers keep object identity without a reload.
    # With the type_variants flag off, links are ignored and every type owns its own
    # stored configuration.
    def effective_source_for(aspect)
      owner_id = effective_source_id_for(aspect)
      owner_id == id ? self : self.class.find(owner_id)
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

    # True when a read should resolve +aspect+ through the link chain rather than
    # return this type's own association: variants on and the type persisted. The
    # negative case returns the association itself, which stays eager-loadable.
    def resolve_linked_aspect?
      !new_record? && OpenProject::FeatureDecisions.type_variants_active?
    end

    def link_default_aspects_to_parent
      Type::ConfigurationLink::DEFAULT_PARENT_LINK_ASPECTS.each { |aspect| link!(aspect, source: parent) }
    end
  end
end

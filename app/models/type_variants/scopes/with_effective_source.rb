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

module TypeVariants::Scopes
  module WithEffectiveSource
    extend ActiveSupport::Concern

    # The column TypeVariants::Scopes::WithEffectiveConfiguration selects per aspect. The
    # preloading reads the aspects back off the loaded records instead of being told them,
    # so chaining the scope for several aspects resolves all of them.
    PRELOADED_SOURCE_ID = /\Aeffective_source_id_(?<aspect>.+)\z/

    module Preloading
      def exec_queries(&)
        super.tap { |records| TypeVariant.preload_effective_sources(records) }
      end
    end

    class_methods do
      # Everything .with_effective_configuration resolves, plus the owning TypeVariant objects
      # themselves, so TypeVariant#effective_source_for needs no lookup of its own.
      #
      # Kept separate from .with_effective_configuration because resolving the ids is
      # useful on its own — TypeVariant::FormConfigurationSql only ever needs those, and should not
      # pay for instantiating type_variants it will not touch.
      def with_effective_source(aspect)
        with_effective_configuration(aspect).extending(Preloading)
      end

      # Assigns each record the type owning every aspect preloaded on it, in at most one
      # additional query — and in none at all when the records already contain their own
      # sources, which is the usual case for a relation spanning the whole table.
      def preload_effective_sources(records) # :nodoc:
        aspects = preloaded_aspects(records)
        return if aspects.empty?

        sources = resolved_sources(records, aspects)

        records.each do |record|
          aspects.each do |aspect|
            source = sources[record.effective_source_id(aspect)]
            record.assign_effective_source(aspect, source) if source
          end
        end
      end

      private

      def resolved_sources(records, aspects)
        loaded = records.index_by(&:id)
        source_ids = records.flat_map do |record|
          aspects.map { |aspect| record.effective_source_id(aspect) }
        end
        missing = source_ids.uniq - loaded.keys
        return loaded if missing.empty?

        # unscoped so neither the default order nor an enclosing scope can drop a source.
        loaded.merge(unscoped.where(id: missing).index_by(&:id))
      end

      def preloaded_aspects(records)
        return [] if records.empty?

        records.first.attribute_names.filter_map do |name|
          PRELOADED_SOURCE_ID.match(name)&.[](:aspect)
        end
      end
    end
  end
end

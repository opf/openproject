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

# A variant that owned an aspect (no '<aspect>_source_id') stays independent. A variant that
# inherited one - from any source, base or otherwise - is linked to its own base instead, dropping
# the old model's arbitrary inheritance in favour of parent-only links.
class AddLinkedAspectsToTypeVariants < ActiveRecord::Migration[8.1]
  ASPECTS = %w[pdf_export defaults form_configuration project_attributes].freeze

  def up
    add_column :type_variants, :linked_aspects, :text, array: true, null: false, default: []

    ASPECTS.each { |aspect| link_inheriting_variants(aspect) }
  end

  def down
    remove_column :type_variants, :linked_aspects
  end

  private

  def link_inheriting_variants(aspect)
    execute(<<~SQL.squish)
      UPDATE type_variants
      SET linked_aspects = array_append(linked_aspects, '#{aspect}')
      WHERE NOT is_default_variant
        AND #{aspect}_source_id IS NOT NULL
    SQL
  end
end

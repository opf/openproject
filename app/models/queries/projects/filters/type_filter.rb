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

class Queries::Projects::Filters::TypeFilter < Queries::Projects::Filters::Base
  # Any family member is a valid value, not just the roots offered by
  # #autocomplete_options: the project field on the global create form filters by
  # the root before a project is picked and by the resolved variant afterwards.
  def allowed_values
    @allowed_values ||= Type.pluck(:name, :id)
  end

  def joins
    :types
  end

  # A project activates a single member of a type family, which may be a variant
  # while the value filtered for is its root. Matching the whole family keeps
  # variants transparent, e.g. for the project field on the global create form.
  def where
    operator_strategy.sql_for_field(expanded_values, Type.table_name, :id)
  end

  def type
    :list
  end

  def autocomplete_options
    {
      component: "opce-autocompleter",
      bindValue: "id",
      bindLabel: "name",
      hideSelected: true,
      defaultData: false,
      items: selectable_items,
      model: selected_items
    }
  end

  def self.key
    :type_id
  end

  private

  def expanded_values
    Type.family_ids(values).presence || values
  end

  # Only roots are offered as variants are collapsed into them, and filtering for
  # a root matches its variants anyway.
  def selectable_items
    Type.roots.pluck(:name, :id).map { |name, id| { name:, id: } }
  end

  # Reads #name so a value naming a variant is labelled with the name of its root,
  # which is loaded along with it. #preload rather than #includes so no caller can
  # turn this into a self-join of types (see WorkPackages::BaseContract#assignable_types).
  def selected_items
    Type.where(id: values).preload(:parent).map { |type| { name: type.name, id: type.id } }
  end
end

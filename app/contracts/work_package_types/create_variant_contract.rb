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

module WorkPackageTypes
  # A named variant's own attributes. Everything else about it is configuration, which the
  # aspect tabs and their services own.
  class CreateVariantContract < ::ModelContract
    include AuthorizesVariantAuthoring

    def self.model = TypeVariant

    attribute :variant_name

    # The owner an :error_unauthorized is raised over, so it has to be writable for the rule in
    # AuthorizesVariantAuthoring to be the one that decides.
    attribute :project_id

    # Set by CreateVariantService rather than by whoever calls it: a new variant belongs to the
    # type it was added to and starts out Linked to that type's base configuration.
    attribute :type_id
    TypeVariant::ASPECTS.each { |aspect| attribute :"#{aspect}_source_id" }
  end
end

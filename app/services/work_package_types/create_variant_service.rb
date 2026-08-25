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
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  # Adds a named variant to a type.
  #
  # It starts out Linked to the type's base variant for every aspect, which is what makes it a
  # variation of that configuration rather than an empty one. Each aspect goes Independent
  # later, when someone edits it.
  # Pass +project+ to make the variant that project's own. Whether the user may is
  # CreateVariantContract's business.
  class CreateVariantService < ::BaseServices::Create
    def initialize(user:, type:, contract_class: nil, contract_options: {})
      @type = type
      super(user:, contract_class:, contract_options:)
    end

    protected

    attr_reader :type

    def instance_class = TypeVariant

    def instance(_params)
      type.variants.new.tap do |variant|
        TypeVariant::ASPECTS.each { |aspect| variant.public_send(:"#{aspect}_source=", type.default_variant) }
      end
    end

    def default_contract_class = CreateVariantContract
  end
end

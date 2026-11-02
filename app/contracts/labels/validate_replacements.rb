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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Labels
  module ValidateReplacements
    extend ActiveSupport::Concern

    included do
      validate :validate_label_name_replacements
    end

    private

    def validate_label_name_replacements
      return if model.label_name_replacements.blank?
      return unless writable?(:labels)

      if model.label_name_replacements.size > Labelable::MAX_LABEL_NAMES_PER_SAVE
        errors.add(:labels, :too_many, count: Labelable::MAX_LABEL_NAMES_PER_SAVE)
        return
      end

      label_name_error_details.each { errors.add(:labels, it[:error], **it.except(:error)) }
    end

    def label_name_error_details
      names_to_create = label_names_to_create
      return [] if names_to_create.empty?

      authorization = label_creation_authorization_errors(names_to_create.first)
      (authorization + names_to_create.flat_map { label_name_errors(it) }).uniq
    end

    def label_names_to_create
      existing_names = Label.named_any(model.label_name_replacements).pluck(:name).to_set(&:downcase)
      model.label_name_replacements.reject { existing_names.include?(it.downcase) }
    end

    def label_creation_authorization_errors(name)
      contract = Labels::CreateContract.new(Label.new(name:), user)
      contract.validate
      contract.errors.details[:base]
    end

    def label_name_errors(name)
      label = Label.new(name:)
      label.valid?
      label.errors.details[:name]
    end
  end
end

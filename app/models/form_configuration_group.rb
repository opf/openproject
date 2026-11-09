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

class FormConfigurationGroup < ApplicationRecord
  belongs_to :form_configuration, inverse_of: :form_groups
  belongs_to :query, optional: true, dependent: :destroy
  has_many :members,
           -> { order(:position) },
           class_name: "FormConfigurationAttribute",
           foreign_key: :form_configuration_group_id,
           inverse_of: :group,
           dependent: :restrict_with_exception

  enum :kind, { attribute: "attribute", query: "query" }, prefix: true, validate: true

  acts_as_list scope: :form_configuration
  include Lists::MoveAfterAnchor

  validates :label, presence: true, if: -> { default_key.blank? }
  validates :query, presence: true, if: :kind_query?
  validates :query, absence: true, if: :kind_attribute?
  validates :default_key, uniqueness: { scope: :form_configuration_id }, allow_nil: true
  validates :query_id, uniqueness: true, allow_nil: true

  def translated_label
    return label if label.present?

    translation_key = TypeVariant.default_groups[default_key&.to_sym]
    translation_key ? I18n.t(translation_key) : default_key.to_s
  end
end

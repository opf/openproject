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

module AI
  class TextTransformAction < ApplicationRecord
    SORTABLE_LIST_TYPE = "text_transform_action"

    acts_as_list
    include Lists::MoveAfterAnchor

    has_many :text_transform_action_types,
             class_name: "AI::TextTransformActionType",
             foreign_key: :ai_text_transform_action_id,
             inverse_of: :text_transform_action,
             dependent: :destroy
    has_many :types, through: :text_transform_action_types

    enum :usage_scope, {
      everywhere: "everywhere",
      all_work_package_types: "all_work_package_types",
      specific_work_package_types: "specific_work_package_types"
    }, default: "everywhere", validate: true

    validates :label, presence: true, length: { maximum: 255 }
    validates :prompt, presence: true
    validates :types, presence: true, if: :specific_work_package_types?
    validates :injects_type_template, absence: true, if: :everywhere?

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position, :id) }
  end
end

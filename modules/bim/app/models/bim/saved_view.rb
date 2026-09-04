# frozen_string_literal: true

# -- copyright
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
# ++

module Bim
  class SavedView < ApplicationRecord
    self.table_name = 'bim_saved_views'

    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user, optional: true

    validates :name, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { scope: :ifc_model_id }
    validates :camera_eye, presence: true
    validates :camera_look, presence: true
    validates :camera_up, presence: true
    validates :projection, inclusion: { in: %w[perspective orthogonal] }

    validate :validate_camera_vectors

    scope :public_views, -> { where(is_public: true) }
    scope :private_views, -> { where(is_public: false) }
    scope :for_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }

    # Helper method to get camera position as array
    def camera_position
      {
        eye: camera_eye,
        look: camera_look,
        up: camera_up,
        projection: projection
      }
    end

    # Set camera position from hash
    def camera_position=(position)
      self.camera_eye = position[:eye] || position['eye']
      self.camera_look = position[:look] || position['look']
      self.camera_up = position[:up] || position['up']
      self.projection = position[:projection] || position['projection'] || 'perspective'
    end

    private

    def validate_camera_vectors
      validate_vector(:camera_eye, 'Camera eye')
      validate_vector(:camera_look, 'Camera look')
      validate_vector(:camera_up, 'Camera up')
    end

    def validate_vector(attribute, label)
      vector = send(attribute)
      return if vector.blank?

      unless vector.is_a?(Array) && vector.length == 3 && vector.all? { |v| v.is_a?(Numeric) }
        errors.add(attribute, "#{label} must be an array of 3 numeric values")
      end
    end
  end
end

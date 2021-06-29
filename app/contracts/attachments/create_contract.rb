#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Attachments
  class CreateContract < ::ModelContract
    attribute :file
    attribute :filename
    attribute :filesize
    attribute :digest
    attribute :description
    attribute :content_type
    attribute :container
    attribute :author

    validate :validate_attachments_addable
    validate :validate_container_addable
    validate :validate_author

    private

    def validate_attachments_addable
      if Redmine::Acts::Attachable.attachables.none?(&:attachments_addable?)
        errors.add(:base, :error_unauthorized)
      end
    end

    def validate_author
      unless model.author == user
        errors.add(:author, :invalid)
      end
    end

    def validate_container_addable
      return unless model.container

      errors.add(:base, :error_unauthorized) unless model.container.attachments_addable?(user)
    end
  end
end

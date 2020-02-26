#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Bim
  module IfcModels
    class BaseContract < ::ModelContract
      delegate :project,
               :new_record?,
               to: :model

      attribute :title
      attribute :is_default
      attribute :project

      def self.model
        ::Bim::IfcModels::IfcModel
      end

      def validate
        user_allowed_to_manage
        user_is_uploader
        ifc_attachment_existent
        ifc_attachment_is_ifc
        uploader_is_ifc_attachment_author

        super
      end

      def user_allowed_to_manage
        if model.project && !user.allowed_to?(:manage_ifc_models, model.project)
          errors.add :base, :error_unauthorized
        end
      end

      def user_is_uploader
        if model.uploader_id_changed? && model.uploader != user
          errors.add :uploader_id, :invalid
        end
      end

      def ifc_attachment_existent
        errors.add :base, :ifc_attachment_missing unless model.ifc_attachment
      end

      def ifc_attachment_is_ifc
        return unless model.ifc_attachment&.new_record?

        firstline = File.open(model.ifc_attachment.file.file.path, &:readline)

        begin
          unless firstline.match?(/^ISO-10303-21;/)
            errors.add :base, :invalid_ifc_file
          end
        rescue ArgumentError
          errors.add :base, :invalid_ifc_file
        end
      end

      def uploader_is_ifc_attachment_author
        errors.add :uploader_id, :invalid if model.ifc_attachment && model.uploader != model.ifc_attachment.author
      end
    end
  end
end

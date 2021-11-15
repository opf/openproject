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
# See COPYRIGHT and LICENSE files for more details.
#++

module Bim
  module IfcModels
    class SetAttributesService < ::BaseServices::SetAttributes
      protected

      def set_attributes(params)
        model.project = params[:project] if params.key?(:project)
        set_ifc_attachment(params.delete(:ifc_attachment))

        super

        model.change_by_system do
          model.uploader = model.ifc_attachment&.author
        end
      end

      def set_default_attributes(_params)
        set_title
      end

      def validate_and_result
        super.tap do |call|
          # map errors on attachments to better display them
          if call.errors[:attachments].any?
            model.ifc_attachment.errors.details.each do |_, errors|
              errors.each do |error|
                call.errors.add(:attachments, error[:error], **error.except(:error))
              end
            end
          end
        end
      end

      def set_title
        model.title ||= model.ifc_attachment&.file&.filename&.gsub(/\.\w+$/, '')
      end

      def set_ifc_attachment(ifc_attachment)
        return unless ifc_attachment

        model.attachments.each(&:mark_for_destruction)

        if ifc_attachment.is_a?(Attachment)
          ifc_attachment.description = "ifc"
          ifc_attachment.save! unless ifc_attachment.new_record?

          model.attachments << ifc_attachment
        else
          ::Attachments::BuildService
            .bypass_whitelist(user: user)
            .call(file: ifc_attachment, container: model, filename: ifc_attachment.original_filename, description: 'ifc')
        end
      end
    end
  end
end

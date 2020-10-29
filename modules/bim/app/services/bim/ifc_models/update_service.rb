#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#+

module Bim
  module IfcModels
    class UpdateService < ::BaseServices::Update
      protected

      def before_perform(params)
        super.tap do |call|
          @ifc_attachment_replaced = call.success? && model.ifc_attachment.new_record?
        end
      end

      def after_perform(call)
        if call.success?
          # As the attachments association does not have the autosave option, we need to remove the
          # attachments ourselves
          model.attachments.select(&:marked_for_destruction?).each(&:destroy)

          if @ifc_attachment_replaced
            IfcConversionJob.perform_later(call.result)
          end
        end

        call
      end
    end
  end
end

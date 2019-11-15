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

module IFCModels
  class UpdateService < ::BaseServices::Update
    protected

    attr_accessor :ifc_attachment

    def before_perform(params)
      self.ifc_attachment = params.delete('ifc_attachment')
      super(params)
    end

    def after_perform(call)
      call.success = replace_attachment(call)

      if @ifc_attachment_replaced && call.success?
        IFCConversionJob.perform_later(call.result)
      end

      call
    end

    ##
    # Replace the IFC attachment file after saving
    def replace_attachment(result)
      return unless result.success?

      model = result.result
      # Uploading an IFC file is optional
      if ifc_attachment && ifc_attachment.size.positive?
        model.ifc_attachment = ifc_attachment
        @ifc_attachment_replaced = true
      end

      if model.save
        true
      else
        result.errors.add(:ifc_attachment, t('ifc_models.could_not_save_file'))
        false
      end
    end
  end
end

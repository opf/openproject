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

module Attachments
  class SetPreparedAttributesService < SetAttributesService
    private

    def set_attributes(params)
      super

      set_prepared_attributes params
    end

    def set_prepared_attributes(params)
      # We need to do it like this because `file` is an uploader which expects a File (not a string)
      # to upload usually. But in this case the data has already been uploaded and we just point to it.
      model[:file] = pending_direct_upload_filename(params[:filename])

      # Explicitly set the filesize from metadata
      # as the provided file is not actually uploaded
      model.filesize = params[:filesize]

      model.extend(OpenProject::ChangedBySystem)
      model.change_by_system do
        model.status = :prepared
        # Set a preliminary content type as the file is not present
        # The content type will be updated by the FinishDirectUploadJob if necessary.
        model.content_type = params[:content_type].presence || OpenProject::ContentTypeDetector::SENSIBLE_DEFAULT
      end
    end

    # The name has to be in the same format as what Carrierwave will produce later on. If they are different,
    # Carrierwave will alter the name (both local and remote) whenever the attachment is saved with the remote
    # file loaded.
    def pending_direct_upload_filename(filename)
      CarrierWave::SanitizedFile.new(nil).send(:sanitize, filename)
    end
  end
end

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

class Attachments::PrepareUploadService < ::BaseServices::Create
  def instance(params)
    binding.pry
    super(params).tap do |attachment|
      # We need to do it like this because `file` is an uploader which expects a File (not a string)
      # to upload usually. But in this case the data has already been uploaded and we just point to it.
      attachment[:file] = pending_direct_upload_filename(params[:filename])

      attachment.extend(OpenProject::ChangedBySystem)
      attachment.change_by_system do
        attachment.downloads = -1
        attachment.content_type = params[:content_type] || 'application/octet-stream'
      end
    end
  end

  def persist(call)
    attachment = call.result

    if attachment.save
      attachment.reload # necessary so that the fog file uploader path is correct
      ServiceResult.new success: true, result: attachment
    else
      ServiceResult.new success: false, result: attachment
    end
  end

  private

  # The name has to be in the same format as what Carrierwave will produce later on. If they are different,
  # Carrierwave will alter the name (both local and remote) whenever the attachment is saved with the remote
  # file loaded.
  def pending_direct_upload_filename(filename)
    CarrierWave::SanitizedFile.new(nil).send(:sanitize, filename)
  end
end

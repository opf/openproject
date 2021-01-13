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

class Attachments::FinishDirectUploadJob < ApplicationJob
  queue_with_priority :high

  def perform(attachment_id)
    attachment = Attachment.pending_direct_uploads.where(id: attachment_id).first
    local_file = attachment && attachment.file.local_file

    if local_file.nil?
      return Rails.logger.error("File for attachment #{attachment_id} was not uploaded.")
    end

    begin
      attachment.downloads = 0
      attachment.set_file_size local_file unless attachment.filesize && attachment.filesize > 0
      attachment.set_content_type local_file unless attachment.content_type.present?
      attachment.set_digest local_file unless attachment.digest.present?

      attachment.save! if attachment.changed?
    ensure
      File.unlink(local_file.path) if File.exist?(local_file.path)
    end
  end
end

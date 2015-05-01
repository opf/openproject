#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# Goes through all attachments looking for ones whose 'file' column, which is the new column
# used by the carrierwave-based attachments, is not set.
#
# For every one of those attachments the migration then sets the 'file' column to
# whatever the value of the legacy column 'filename' is. If that one is empty too
# it falls back to the 'disk_filename' column. This one was not meant to be displayed
# to users but it's better than nothing, especially when trying to identify corrupt attachments.
#
# If *that* column is empty too, the attachment is broken beyond repair and will be dropped.
#
# Note: Just because the 'file' column is restored doesn't mean the actual file exists.
#       Rather the 'file' column being empty means precisely that the file is missing.
#       By still writing the filename into the file column the attachment can at least
#       be displayed, if not downloaded.
#
# Important: The migration is irreversible.
class PatchCorruptAttachments < ActiveRecord::Migration
  def up
    Attachment.all.each do |attachment|
      patch_attachment attachment
    end
  end

  def down
    puts "Won't revert this migration as it would mean breaking valid attachments. \
          We could break the attachments with missing files again by deleting their
          file column to restore the state before the migration. But that doesn't help.".squish
  end

  def patch_attachment(attachment)
    attributes = attachment.attributes
    if attributes['file'].blank?
      # fall back to disk filename if necessary
      file = attributes['filename'].presence || attributes['disk_filename'].presence

      if file
        attachment.update_column :file, file
        puts "updated attachment #{attachment.id}'s file column: #{file}"
      else
        # this really shouldn't happen - but just in case it does, it is more sensible
        # to just delete the attachment because it will just break things
        puts "could not patch #{attachment.inspect} - missing file name information - \
              it's hopeless ... deleting it".squish
        attachment.destroy
      end
    end
  end
end

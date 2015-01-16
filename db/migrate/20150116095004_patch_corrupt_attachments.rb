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
    puts "Can't revert this migration as it would mean breaking valid attachments. \
          Even if we wanted to do that we can't know which ones were broken before \
          to only break those again.".squish
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

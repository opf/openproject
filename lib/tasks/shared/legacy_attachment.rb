module Tasks
  module Shared
    ##
    # In the olden times (pre 4.1) files were all saved under the configured storage path,
    # most likely `files`, with a timestamp attached to their name to avoid conflicts.
    #
    # e.g. `files/140917231758_openshift-setup.txt`
    #
    # The new approach is using CarrierWave for attachments. There the files will be stored
    # some place else. Where is not material for this migration.
    # It could be another directory or S3.
    #
    # The migration does the following:
    #
    # * rename the legacy files - it strips off the timestamps
    # * assign the renamed file to the CarrierWave uploader - this moves the file to
    #   the new location
    #
    # The rollback does the opposite using the remaining legacy column `disk_filename`
    # of Attachment. Meaning it adds the timestamp again and puts the files back into
    # the configured attachment storage path.
    #
    # This assumes that the attachment storage path is the same as before the migration
    # to CarrierWave and also that the legacy columns `filename` and `disk_filename`
    # are still present.
    module LegacyAttachment
      module_function

      def migrate_attachment(attachment)
        file = legacy_file_name attachment.disk_filename
        new_file = strip_timestamp_from_filename(file)

        if File.readable? file
          FileUtils.move file, new_file
          attachment.file = File.open(new_file)
          attachment.filename = ''
          attachment.save!

          FileUtils.rm_f new_file

          File.readable? attachment.file.path
        else
          path = attachment.file.path
          if path && File.readable?(path)
            true # file has been migrated already
          else
            puts "Found corrupt attachment (#{attachment.id}) during migration: \
                  '#{file}' does not exist".squish
            false
          end
        end
      end

      def rollback_attachment(attachment)
        return unless attachment.file.path

        old_file = rolled_back_file_name attachment

        unless File.readable? old_file
          file = attachment.diskfile.path

          FileUtils.move file, old_file
          attachment.update_column :file, nil
          attachment.update_column :filename, Pathname(file).basename.to_s

          # keep original disk filename if it was preserved
          if attachment.disk_filename.blank?
            attachment.update_column :disk_filename, Pathname(old_file).basename.to_s
          end

          FileUtils.rmdir Pathname(file).dirname
        end
      end

      ##
      # Returns rolled back file name for an attachment.
      # If an attachment was created after the migration to CarrierWave it doesn't have an original
      # legacy name. Instead one will be generated. Not with a timestamp, however, but with a
      # random hex string as a prefix.
      #
      # This way new attachments won't be lost when rolling back to an old version of OpenProject.
      def rolled_back_file_name(attachment)
        if attachment.disk_filename.blank?
          uuid = SecureRandom.hex 4
          name = Pathname(attachment.diskfile.path).basename
          legacy_file_name "#{uuid}_#{name}"
        else
          legacy_file_name attachment.disk_filename
        end
      end

      def legacy_file_name(file_name)
        Pathname(OpenProject::Configuration.attachments_storage_path).join file_name
      end

      ##
      # This method strips the leading timestamp from a given file name and returns the plain,
      # original file name.
      def strip_timestamp_from_filename(file)
        Pathname(file).dirname + Pathname(file).basename.to_s.gsub(/^[^_]+_/, '')
      end
    end
  end
end

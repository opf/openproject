#-- encoding: UTF-8
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

namespace :attachments do
  desc 'Copies all attachments from the current to the given storage.'
  task :copy_to, [:to] => :environment do |task, args|
    if args.empty?
      puts 'rake attachments:copy_to[file|fog]'
      exit 1
    end

    storage_name = args[:to].to_sym
    current_uploader = OpenProject::Configuration.file_uploader
    target_uploader = OpenProject::Configuration.available_file_uploaders[storage_name]

    if target_uploader.nil?
      puts "unknown storage: #{args[:to]}"
      exit 1
    end

    if target_uploader == current_uploader
      puts "attachments already in #{target_uploader} storage"
      exit 1
    end

    if target_uploader == :fog && (
         OpenProject::Configuration.fog_credentials.empty? ||
         OpenProject::Configuration.fog_directory.nil?)
      puts 'the fog storage is not configured'
      exit 1
    end

    target_attachment = Class.new(Attachment) do
      def self.store_all!(attachments)
        attachments.each_with_index do |attachment, index|
          print "Copying attachment #{attachment.id} [#{index + 1}/#{attachments.size}] \
                 (#{attachment.file.path}) ... ".squish
          STDOUT.flush

          if store! attachment
            puts ' ok'
          else
            puts ' failed (missing file)'
          end
        end
      end

      ##
      # Given an attachment using the source uploader creates a TargetAttachment
      # which uses the destination uploader to store the original attachment's
      # file in the target location.
      def self.store!(attachment)
        return nil unless attachment.attributes['file'].present? &&
                          File.exists?(attachment.file.path)

        self.new.tap do |target|
          target.id = attachment.id
          target.file = attachment.file.local_file
          target.file.store!
        end
      end

      ##
      # Pretends to be a plain old Attachment in order not to break store paths.
      def self.to_s
        'attachment'
      end
    end

    attachments = Attachment.all

    puts "Copying #{attachments.size} attachments to #{storage_name}."
    puts

    target_attachment.mount_uploader :file, target_uploader
    target_attachment.store_all! attachments
  end
end

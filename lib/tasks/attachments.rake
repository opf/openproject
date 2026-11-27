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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

namespace :attachments do
  desc "Clear cached attachment files older than the defined setting (defaults to 2 hours)"
  task clear: [:environment] do
    Attachment.clean_cached_files!
  end

  desc "Prepare files for a CarrierWave application rollback. Stop all application and worker processes first."
  task prepare_carrierwave_rollback: :environment do
    Attachment.where.not(file_data: nil).find_each { |attachment| attachment.file.prepare_carrierwave_rollback! }
  end

  desc "Copies all attachments from the current to the given storage."
  task :copy_to, [:to] => :environment do |_task, args|
    if args.empty?
      puts "rake attachments:copy_to[file|fog]"
      exit 1
    end

    storage_name = args[:to].to_sym
    unless OpenProject::Configuration.available_file_uploaders.key?(storage_name)
      abort "Unknown or unconfigured attachment storage: #{storage_name}"
    end
    if storage_name == OpenProject::Configuration.attachments_storage.to_sym
      abort "Attachments already use #{storage_name} storage"
    end

    storage = AttachmentShrine.permanent_storage(storage_name)
    Attachment.find_each do |attachment|
      copied = attachment.file.copy_to_storage(storage)
      puts "Attachment #{attachment.id}: #{copied ? 'copied' : 'missing file'}"
    end
  end

  desc "Extract text content from attachment that were not extracted yet synchronously."
  task extract_fulltext_where_missing: :environment do
    Attachment.extract_fulltext_where_missing(run_now: true)
  end

  desc "Extract text content from attachment that were not extracted yet."
  task schedule_fulltext_extraction_where_missing: :environment do
    Attachment.extract_fulltext_where_missing(run_now: false)
  end

  desc 'Extracts fulltext of all attachments and provide it for attachment filter even if that attachment has been \
        extracted before.'
  task force_extract_fulltext: :environment do
    Attachment.force_extract_fulltext
  end
end

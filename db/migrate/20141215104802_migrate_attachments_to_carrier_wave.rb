#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'tasks/shared/legacy_attachment'

class MigrateAttachmentsToCarrierWave < ActiveRecord::Migration[4.2]
  def up
    add_column_if_missing :attachments, :file, :string

    count = Attachment.count

    puts "Migrating #{count} attachments to CarrierWave."
    puts 'Depending on your configuration this can take a while.
          Especially if files are uploaded to S3.'.squish

    Attachment.connection.schema_cache.clear!
    Attachment.reset_column_information # make sure new column is visible

    Attachment.all.each_with_index do |attachment, i|
      puts "Migrating attachment #{i + 1}/#{count} (#{attachment.disk_filename})"
      migrate_attachment attachment
    end

    puts 'Attachment migration complete.'
  end

  def down
    count = Attachment.count

    puts "Rolling back #{count} attachments from CarrierWave to legacy file-based storage."
    puts 'Depending on your configuration this can take a while.
          Especially if files are downloaded from S3.'.squish

    Attachment.all.each_with_index do |attachment, i|
      puts "Migrating attachment #{i + 1}/#{count} (#{attachment.file.path})"
      rollback_attachment attachment
    end

    remove_column :attachments, :file
  end

  ##
  # Adds a column to the a table unless the column already exists.
  def add_column_if_missing(table, column, type)
    add_column table, column, type unless column_exists?(table, column, type)
  end

  include Tasks::Shared::LegacyAttachment
end

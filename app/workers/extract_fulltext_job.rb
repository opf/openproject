#-- encoding: UTF-8
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

require 'text_extractor'

class ExtractFulltextJob < ApplicationJob
  def initialize(attachment_id)
    @attachment_id = attachment_id
  end

  def perform
    return unless attachment = find_attachment(@attachment_id)

    carrierwave_uploader = attachment.file

    text = TextExtractor::Resolver.new(carrierwave_uploader.local_file, attachment.content_type).text if attachment.readable?

    if OpenProject::Database.allows_tsv?
      attachment_filename = carrierwave_uploader.file.filename
      update_with_tsv(attachment.id, attachment_filename, text)
    else
      attachment.update(fulltext: text)
    end
  end

  private

  def update_with_tsv(id, filename, text)
    language = OpenProject::Configuration.main_content_language
    update_sql = <<-SQL
          UPDATE "attachments" SET
            fulltext = '%s',
            "fulltext_tsv" = to_tsvector('%s', '%s'),
            "file_tsv" = to_tsvector('%s', '%s')
          WHERE ID = %s;
    SQL

    ActiveRecord::Base.connection.execute ActiveRecord::Base.send(
      :sanitize_sql_array,
      [update_sql,
       text,
       language,
       OpenProject::FullTextSearch.normalize_text(text),
       language,
       OpenProject::FullTextSearch.normalize_filename(filename),
       id]
    )
  end

  def find_attachment(id)
    Attachment.find_by_id id
  end

end

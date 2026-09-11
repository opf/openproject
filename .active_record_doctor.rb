# frozen_string_literal: true

#-- copyright
# OpenProject is a project management system.
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
# See doc/COPYRIGHT.rdoc for more details.
#++

ActiveRecordDoctor.configure do
  global :ignore_tables, [
    "ar_internal_metadata",
    "schema_migrations",
    "active_storage_attachments",
    "active_storage_blobs",
    "active_storage_variant_records",
    "action_text_rich_texts"
  ]

  detector :undefined_table_references, ignore_models: [
    "ActionMailbox::InboundEmail",
    "ActionText::EncryptedRichText",
    "ActionText::RichText",
    "ActiveStorage::Attachment",
    "ActiveStorage::Blob",
    "ActiveStorage::VariantRecord",
    "ApplicationVersion",
    "Migrations::Attachments::CurrentWikiContent",
    "Action",
    "Capability",
    "Day",
    "TemporaryDocument"
  ]
  detector :missing_unique_indexes, ignore_models: [
    "Migrations::Attachments::CurrentWikiContent"
  ]
end

# frozen_string_literal: true

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

module Exports::PDF::Artefact::WikiPages
  def write_artefact_wiki_pages
    artefact_wiki_pages.each { write_artefact_wiki_page(it) }
  end

  def artefact_wiki_pages
    @artefact_wiki_pages ||= WorkPackage::PDFExport::WikiPagesResolver.new(
      submitted: options[:wiki_pages],
      configured: configured_wiki_pages,
      user: User.current
    ).call
  end

  def build_wiki_page_toc_entries
    artefact_wiki_pages.map { toc_entry(wiki_page_toc_key(it), it.title) }
  end

  # Configuring a wiki page grants its content, images included, to everyone who can
  # export the artefact.
  def attachment_visible?(attachment)
    super || artefact_wiki_page_attachment?(attachment)
  end

  private

  def configured_wiki_pages
    work_package.type_variant.pdf_export_templates.settings_for(
      WorkPackages::Exports::Generate::Templates::ArtefactSettingsComponent::TEMPLATE_ID
    )[:wiki_pages]
  end

  def write_artefact_wiki_page(wiki_page)
    write_optional_page_break
    record_toc_page!(wiki_page_toc_key(wiki_page))
    with_margin(styles.section_margins) do
      write_section_title(wiki_page.title)
      write_artefact_wiki_page_text(wiki_page)
    end
  end

  def write_artefact_wiki_page_text(wiki_page)
    return if wiki_page.text.blank?

    with_margin(styles.project_markdown_margins) do
      write_markdown!(
        apply_markdown_field_macros(
          wiki_page.text,
          { work_package:, project: wiki_page.project, user: User.current }
        ),
        styles.project_markdown_styling_yml
      )
    end
  end

  def wiki_page_toc_key(wiki_page)
    "wiki_page_#{wiki_page.id}"
  end

  def artefact_wiki_page_attachment?(attachment)
    attachment.container_type == "WikiPage" &&
      artefact_wiki_pages.any? { it.id == attachment.container_id }
  end
end

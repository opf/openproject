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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  class InlineExistingWikiPageDialog < ApplicationComponent
    include OpTurbo::Streamable

    DIALOG_ID = "inline-existing-wiki-page-dialog"

    def form_id = "#{DIALOG_ID}-form"

    def form_options
      if model.final_step?
        {
          id: form_id,
          model:,
          url: close_dialog_and_inline_wiki_page_link_macro_path,
          data: { turbo_stream: true }
        }
      else
        {
          id: form_id,
          model:,
          url: inline_existing_page_dialog_wiki_page_link_macro_path,
          method: :get,
          data: { turbo_stream: true }
        }
      end
    end

    def keep_dialog_open?
      model.final_step?
    end

    def system_arguments
      options
    end
  end
end

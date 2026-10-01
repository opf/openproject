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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Document types", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "PUT /admin/settings/document_types/:id/move" do
    let!(:first_record) { create(:document_type, name: "Alpha") }
    let!(:second_record) { create(:document_type, name: "Beta") }
    let!(:third_record) { create(:document_type, name: "Gamma") }
    let(:list_type) { "document_type" }
    let(:morph_target) { "documents-admin-document-types-index-component" }

    before do
      third_record.move_to_top
      second_record.move_to_top
      first_record.move_to_top
    end

    def move_path(record)
      move_admin_settings_document_type_path(record)
    end

    def ordered_names
      DocumentType.reorder(:position).where(name: %w[Alpha Beta Gamma]).pluck(:name)
    end

    it_behaves_like "an anchor-only enumeration move endpoint"
  end
end

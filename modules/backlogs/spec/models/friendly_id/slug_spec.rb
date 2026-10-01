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

RSpec.describe FriendlyId::Slug do
  describe "friendly_id_slugs(slug, sluggable_type, scope) unique constraints" do
    it "ensures uniqueness with null scope" do
      p = create(:project)
      expect do
        described_class.create!(sluggable: p, slug: "my-app", scope: nil)
        described_class.create!(sluggable: p, slug: "my-app", scope: nil)
      end.to raise_error(
        ActiveRecord::RecordNotUnique,
        /PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope"\n/ # rubocop:disable Layout/LineLength
      )
    end
  end
end

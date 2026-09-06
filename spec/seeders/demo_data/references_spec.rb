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

RSpec.describe DemoData::References do
  describe "the seed files" do
    let(:seed_files) do
      Rails.root.glob("app/seeders/*.yml") + Rails.root.glob("modules/*/app/seeders/*.yml")
    end

    it "only uses reference macros that the same file declares" do
      unresolvable = seed_files.filter_map do |path|
        content = File.read(path)
        declared = content.scan(/^\s*reference:\s*:?([a-z_0-9]+)$/).flatten
        used = content.scan(described_class::REFERENCE_MACRO).flatten.uniq

        [path.relative_path_from(Rails.root).to_s, used - declared] if (used - declared).any?
      end

      expect(unresolvable).to be_empty
    end
  end
end

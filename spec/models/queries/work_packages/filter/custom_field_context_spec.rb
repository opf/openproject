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

RSpec.describe Queries::WorkPackages::Filter::CustomFieldContext do
  describe ".custom_fields" do
    shared_let(:type) { create(:type) }
    shared_let(:other_type) { create(:type) }
    shared_let(:here) { create(:project, types: [type]) }
    shared_let(:elsewhere) { create(:project, types: [other_type]) }

    shared_let(:shown_here) { create(:list_wp_custom_field, is_filter: true, types: [type]) }
    shared_let(:shown_elsewhere) { create(:list_wp_custom_field, is_filter: true, types: [other_type]) }

    let(:context) { instance_double(Query, project: here) }

    it "offers only the fields the project's form configuration shows" do
      expect(described_class.custom_fields(context)).to contain_exactly(shown_here)
    end

    it "offers every filterable field for a project that is not saved yet" do
      expect(described_class.custom_fields(instance_double(Query, project: Project.new)))
        .to include(shown_here, shown_elsewhere)
    end

    it "offers the globally available fields without a project" do
      expect(described_class.custom_fields(nil)).not_to include(shown_here, shown_elsewhere)
    end
  end
end

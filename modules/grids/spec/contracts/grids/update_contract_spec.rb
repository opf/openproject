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
require_relative "shared_examples"

RSpec.describe Grids::UpdateContract do
  include_context "model contract"
  include_context "grid contract"

  it_behaves_like "shared grid contract attributes"

  describe "type" do
    before do
      grid.type = "Grid"
    end

    it "is not writable" do
      expect(instance.validate)
        .to be_falsey
    end

    it "explains the not writable error" do
      instance.validate
      # scope because that is what type is called on the outside for grids
      expect(instance.errors.details[:scope])
        .to contain_exactly({ error: :error_readonly }, { error: :inclusion })
    end
  end

  describe "user_id" do
    it_behaves_like "is not writable" do
      let(:model) { grid }
      let(:attribute) { :user_id }
      let(:value) { 5 }
    end
  end

  describe "project_id" do
    it_behaves_like "is not writable" do
      let(:model) { grid }
      let(:attribute) { :project_id }
      let(:value) { 5 }
    end
  end
end

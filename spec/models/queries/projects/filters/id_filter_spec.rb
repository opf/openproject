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

RSpec.describe Queries::Projects::Filters::IdFilter do
  it_behaves_like "basic query filter" do
    let(:model) { Project }
    let(:class_key) { :id }
    let(:type) { :list }
    let(:human_name) { "Project" }

    before do
      visible_scope = instance_double(ActiveRecord::Relation)
      allow(Project).to receive(:visible).and_return(visible_scope)
      allow(visible_scope).to receive(:pluck).with(:id).and_return([1234])
    end

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expect(instance.allowed_values).to eq([[1234, "1234"]])
      end
    end
  end

  it_behaves_like "list query filter" do
    let(:model) { Project }
    let(:attribute) { :id }
    let(:valid_values) { ["42"] }
  end
end

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

RSpec.describe API::Utilities::PayloadRepresenter do
  let(:parent_representer) do
    Class.new(API::Decorators::Single) do
      property :i_can_be_written
      property :i_am_read_only
    end
  end
  let(:payload_representer) do
    Class.new(parent_representer) do
      include API::Utilities::PayloadRepresenter
    end
  end
  let(:represented) do
    Struct
      .new(:i_can_be_written, :i_am_read_only, :i_was_added_later)
      .new("written value", "read only value", "added later value")
  end
  let(:writable_attributes) { %w[iCanBeWritten] }
  let(:representer) { payload_representer.new(represented, current_user: build_stubbed(:user)) }

  subject(:rendered) do
    allow(representer).to receive(:writable_attributes).and_return(writable_attributes)

    JSON.parse(representer.to_json)
  end

  it "renders writable properties" do
    expect(rendered).to include("iCanBeWritten" => "written value")
  end

  it "does not render read only properties" do
    expect(rendered).not_to have_key("iAmReadOnly")
  end

  context "with a property defined after the payload representer was created" do
    before do
      payload_representer.property :i_was_added_later
    end

    context "when the property is not writable" do
      it "does not render the property" do
        expect(rendered).not_to have_key("iWasAddedLater")
      end
    end

    context "when the property is writable" do
      let(:writable_attributes) { %w[iCanBeWritten iWasAddedLater] }

      it "renders the property" do
        expect(rendered).to include("iWasAddedLater" => "added later value")
      end
    end
  end
end

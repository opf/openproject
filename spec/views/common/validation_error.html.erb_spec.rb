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

RSpec.describe "common/_validation_error" do
  let(:base_error_messages) { ["Something went completely wrong!"] }
  let(:fields_error_messages) { ["This field is incorrect.", "This cannot be blank."] }

  before do
    view.content_for(:error_details, "Clear this!")

    render partial: "common/validation_error",
           locals: { base_error_messages:,
                     fields_error_messages:,
                     object_name: "Test" }
  end

  it "flushes the buffer before rendering" do
    # that means the same partial can be called multiple times without side effects
    expect(rendered).not_to include("Clear this!")
  end

  it "includes all given error messages" do
    expect(rendered).to include("Something went completely wrong!")
    expect(rendered).to include("This field is incorrect.")
    expect(rendered).to include("This cannot be blank.")
  end
end

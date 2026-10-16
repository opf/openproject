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
#
require "spec_helper"

RSpec.describe Projects::CopyForm, type: :forms do
  include ViewComponent::TestHelpers

  def render_form
    render_in_view_context(model, copy_options, described_class) do |model, copy_options, described_class|
      primer_form_with(url: "/foo", model:) do |f|
        render(described_class.new(f, copy_options:))
      end
    end
  end

  before do
    render_form
  end

  let(:model) { build_stubbed(:project) }
  let(:copy_options) { Projects::CopyOptions.new }

  it "renders Copy options" do
    expect(page).to have_selector :fieldset, "Copy from project"
  end
end

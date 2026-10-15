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

RSpec.shared_examples_for "label contract" do
  let(:locked_user) { create(:admin, status: User.statuses[:locked]) }

  it_behaves_like "contract is valid"

  context "when name is blank" do
    before { label.name = "" }

    it_behaves_like "contract is invalid", name: :blank
  end

  context "when name is too long" do
    before { label.name = "a" * 256 }

    it_behaves_like "contract is invalid", name: :too_long
  end

  context "when name is already taken" do
    before { create(:label, name: label.name.upcase) }

    it_behaves_like "contract is invalid", name: :taken
  end

  context "when the acting user is locked" do
    let(:contract) { described_class.new(label, locked_user) }

    it_behaves_like "contract user is unauthorized"
  end
end

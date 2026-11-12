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

require "spec_helper"

RSpec.describe Token::Base do
  let(:user) { build(:user) }

  subject { described_class.new user: }

  it "creates" do
    subject.save!
    expect(subject.value.length).to eq(64)
  end

  it "create_should_remove_existing_tokenses" do
    subject.save!
    t2 = described_class.create(user:)
    expect(subject.value).not_to eq(t2.value)
    expect(described_class.exists?(subject.id)).to be false
    expect(described_class.exists?(t2.id)).to be true
  end

  context "when defining a prefix" do
    subject { subclass.new(user:) }

    let(:subclass) { Class.new(described_class) { prefix :test } }

    it "has a plaintext value starting with the prefix" do
      expect(subject.value).to start_with("test-")
    end

    it "has the regular token value after the prefix" do
      expect(subject.value.delete_prefix("test-").length).to eq(64)
    end
  end
end

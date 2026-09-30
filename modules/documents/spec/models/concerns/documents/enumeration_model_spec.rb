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
require_module_spec_helper

RSpec.describe Documents::EnumerationModel do
  subject { build(:document_type) }

  it { is_expected.not_to be_colored }

  describe "#became_default_value?" do
    it "returns true if is_default changed to true" do
      subject.is_default = false
      subject.save!(validate: false)

      subject.is_default = true

      expect(subject).to be_became_default_value
    end

    it "returns false if is_default did not change" do
      subject.is_default = true
      subject.save!(validate: false)

      subject.is_default = true

      expect(subject).not_to be_became_default_value
    end

    it "returns false if is_default changed to false" do
      subject.is_default = true
      subject.save!(validate: false)

      subject.is_default = false

      expect(subject).not_to be_became_default_value
    end
  end

  describe "#unmark_old_default_values" do
    it "unmarks all other default values" do
      other_type = create(:document_type, is_default: true)
      subject.is_default = true

      subject.unmark_old_default_values

      expect(other_type.reload.is_default).to be(false)
    end
  end

  describe "#ensure_activated" do
    it "ensures that the enumeration is activated when marked as default" do
      subject.is_default = true
      subject.active = false

      subject.save

      expect(subject).to be_active & be_is_default
    end
  end

  describe "#in_use?" do
    subject { create(:document_type) }

    context "with documents associated" do
      before do
        create(:document, type: subject)
      end

      it "returns true" do
        expect(subject).to be_in_use
      end
    end

    context "without documents associated" do
      it "returns false" do
        expect(subject).not_to be_in_use
      end
    end
  end
end

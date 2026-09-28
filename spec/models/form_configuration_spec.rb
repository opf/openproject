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

RSpec.describe FormConfiguration do
  shared_let(:admin) { create(:admin) }

  describe "naming" do
    it "names a form after what started it" do
      expect(described_class.implicit_name("Bug")).to eq("Bug form")
    end

    it "steps past a name already taken, whatever the casing" do
      create(:form_configuration, name: "Bug form")

      expect(described_class.implicit_name("bug")).to eq("bug form (2)")
    end

    it "refuses a second form with the same name" do
      create(:form_configuration, name: "Bug form")

      expect(build(:form_configuration, name: "BUG FORM")).not_to be_valid
    end

    it "is the form a new type starts with" do
      expect(create(:type, name: "Bug").default_variant.form_configuration.name).to eq("Bug form")
    end
  end

  describe "deletion" do
    it "is refused while a variant still references it" do
      form = create(:type).default_variant.form_configuration

      expect(form.destroy).to be_falsey
      expect(form.errors).to be_of_kind(:base, :"restrict_dependent_destroy.has_many")
    end
  end

  describe "embedded queries" do
    let(:variant) { create(:type).default_variant }
    let(:query) { build(:global_query, user_id: 0) }

    before do
      login_as(admin)
      variant.attribute_groups = [["Related", [query]]]
      variant.save!
    end

    it "destroys a query once its group leaves the form" do
      variant.attribute_groups = [["details", %w[assignee]]]
      variant.save!

      expect(Query.find_by(id: query.id)).to be_nil
    end

    it "destroys its queries with the form" do
      form = variant.form_configuration
      variant.destroy

      form.reload.destroy

      expect(Query.find_by(id: query.id)).to be_nil
    end
  end
end

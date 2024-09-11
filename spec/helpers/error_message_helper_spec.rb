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

RSpec.describe ErrorMessageHelper do
  let(:model) { WikiPage.new }

  def escape_html(array)
    array.map { CGI.escapeHTML _1 }
  end

  shared_examples "error messages rendering" do
    context "when no errors" do
      it { expect(rendered).to eq("") }
    end

    context "with one field error" do
      before do
        errors.add(:title, :blank)
      end

      it { expect(rendered).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 1)) }
      it { expect(rendered).to include(t("errors.header_invalid_fields", count: 1)) }
      it { expect(rendered).to include(*escape_html(errors.full_messages)) }
    end

    context "with two field errors" do
      before do
        errors.add(:title, :blank)
        errors.add(:author, :blank)
      end

      it { expect(rendered).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 2)) }
      it { expect(rendered).to include(t("errors.header_invalid_fields", count: 2)) }
      it { expect(rendered).to include(*escape_html(errors.full_messages)) }
    end

    context "with one base error" do
      before do
        errors.add(:base, :error_unauthorized)
      end

      it { expect(rendered).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 1)) }
      it { expect(rendered).not_to include(t("errors.header_invalid_fields", count: 1)) }
      it { expect(rendered).not_to include(t("errors.header_additional_invalid_fields", count: 1)) }
      it { expect(rendered).to include(*escape_html(errors.full_messages)) }
    end

    context "with one base error and one field error" do
      before do
        errors.add(:base, :error_unauthorized)
        errors.add(:title, :blank)
      end

      it { expect(rendered).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 2)) }
      it { expect(rendered).to include(t("errors.header_additional_invalid_fields", count: 1)) }
      it { expect(rendered).to include(*escape_html(errors.full_messages)) }
    end

    context "with two base errors and two field errors" do
      before do
        errors.add(:base, :error_unauthorized)
        errors.add(:title, :blank)
        errors.add(:base, :error_conflict)
        errors.add(:author, :blank)
      end

      it { expect(rendered).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 4)) }
      it { expect(rendered).to include(t("errors.header_additional_invalid_fields", count: 2)) }
      it { expect(rendered).to include(*escape_html(errors.full_messages)) }
    end
  end

  describe "#error_messages_for" do
    let(:errors) { model.errors }

    subject(:rendered) { helper.error_messages_for(model) }

    it "accesses the model from instance variables if a name is given" do
      helper.instance_variable_set(:@wiki_page, model)
      model.errors.add(:base, :error_conflict)
      expect(helper.error_messages_for("wiki_page")).to include(*escape_html(errors.full_messages))
    end

    it "renders nothing if there is no instance variable with the given name" do
      helper.instance_variable_set(:@wiki_page, model)
      model.errors.add(:base, :error_conflict)
      expect(helper.error_messages_for("work_package")).to be_nil
    end

    include_examples "error messages rendering"
  end
end

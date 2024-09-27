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
  let(:errors) { model.errors }

  let(:error_flash) { flash[:error] }
  let(:message) { error_flash[:message] }
  let(:description) { error_flash[:description] }

  def escape_html(array)
    array.map { CGI.escapeHTML _1 }
  end

  before do
    helper.instance_variable_set(:@wiki_page, model)
  end

  shared_examples "error messages rendering" do
    context "when no errors" do
      it { expect(error_flash).to be_nil }
    end

    context "with one field error" do
      before do
        errors.add(:title, :blank)
      end

      it "adds the error messages", :aggregate_failures do
        helper.error_messages_for("wiki_page")

        expect(message).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 1))
        expect(description).to include(t("errors.header_invalid_fields", count: 1))
        expect(description).to include(*escape_html(errors.full_messages))
      end
    end

    context "with two field errors" do
      before do
        errors.add(:title, :blank)
        errors.add(:author, :blank)
      end

      it "adds both error messages", :aggregate_failures do
        helper.error_messages_for("wiki_page")

        expect(message).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 2))
        expect(description).to include(t("errors.header_invalid_fields", count: 2))
        expect(description).to include(*escape_html(errors.full_messages))
      end
    end

    context "with one base error" do
      before do
        errors.add(:base, :error_unauthorized)
      end

      it "adds the one error message", :aggregate_failures do
        helper.error_messages_for("wiki_page")

        expect(message).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 1))
        expect(description).not_to include(t("errors.header_additional_invalid_fields", count: 1))
        expect(description).to include(*escape_html(errors.full_messages))
      end
    end

    context "with one base error and one field error" do
      before do
        errors.add(:base, :error_unauthorized)
        errors.add(:title, :blank)
      end

      it "adds both error messages", :aggregate_failures do
        helper.error_messages_for("wiki_page")

        expect(message).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 2))
        expect(description).to include(t("errors.header_additional_invalid_fields", count: 1))
        expect(description).to include(*escape_html(errors.full_messages))
      end
    end

    context "with two base errors and two field errors" do
      before do
        errors.add(:base, :error_unauthorized)
        errors.add(:title, :blank)
        errors.add(:base, :error_conflict)
        errors.add(:author, :blank)
      end

      it "adds both error messages", :aggregate_failures do
        helper.error_messages_for("wiki_page")

        expect(message).to include(t("activerecord.errors.template.header", model: "Wiki page", count: 4))
        expect(description).to include(t("errors.header_additional_invalid_fields", count: 2))
        expect(description).to include(*escape_html(errors.full_messages))
      end
    end
  end

  describe "#error_messages_for" do
    it "accesses the model from instance variables if a name is given" do
      model.errors.add(:base, :error_conflict)
      helper.error_messages_for("wiki_page")
      expect(description).to include(*escape_html(errors.full_messages))
    end

    it "renders nothing if there is no instance variable with the given name" do
      model.errors.add(:base, :error_conflict)
      helper.error_messages_for("work_package")

      expect(error_flash).to be_nil
    end

    include_examples "error messages rendering"
  end
end

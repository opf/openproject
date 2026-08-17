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

RSpec.describe Type::Attributes do
  before { RequestStore.clear! }

  describe ".all_work_package_form_attributes" do
    subject(:attributes) { TypeVariant.all_work_package_form_attributes }

    context "when the multiple versions feature is inactive",
            with_settings: { work_package_multiple_versions: false } do
      it "offers the deprecated version and hides target_versions" do
        expect(attributes).to have_key("version")
        expect(attributes).not_to have_key("target_versions")
      end
    end

    context "when the multiple versions feature is active",
            with_settings: { work_package_multiple_versions: true } do
      it "offers target_versions and hides the deprecated version" do
        expect(attributes).to have_key("target_versions")
        expect(attributes).not_to have_key("version")
      end
    end
  end

  describe ".translated_work_package_form_attributes" do
    context "when the multiple versions feature is inactive",
            with_settings: { work_package_multiple_versions: false } do
      it "labels the deprecated version field" do
        expect(TypeVariant.translated_work_package_form_attributes["version"])
          .to eq(I18n.t("activerecord.attributes.work_package.version"))
      end
    end

    context "when the multiple versions feature is active",
            with_settings: { work_package_multiple_versions: true } do
      it "labels the target versions field" do
        expect(TypeVariant.translated_work_package_form_attributes["target_versions"])
          .to eq(I18n.t("activerecord.attributes.work_package.target_versions"))
      end
    end
  end
end

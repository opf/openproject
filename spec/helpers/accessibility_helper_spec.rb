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

RSpec.describe AccessibilityHelper do
  describe "#menu_item_locale" do
    before do
      I18n.backend.store_translations(:en,
                                      label_same_caption: "Same caption",
                                      label_different_caption: "English caption",
                                      label_string_caption: "String caption")
      I18n.backend.store_translations(:de,
                                      label_same_caption: "Same caption",
                                      label_different_caption: "Deutsche Beschriftung",
                                      label_string_caption: "String caption")
    end

    def menu_item(name, caption: nil)
      Redmine::MenuManager::MenuItem.new(name, "/test", caption:)
    end

    it "uses no explicit locale for English" do
      I18n.with_locale(:en) do
        expect(helper.menu_item_locale(menu_item(:same_caption, caption: :label_same_caption))).to be_nil
      end
    end

    it "marks a shared symbolic caption as English" do
      I18n.with_locale(:de) do
        expect(helper.menu_item_locale(menu_item(:same_caption, caption: :label_same_caption))).to eq(:en)
      end
    end

    it "uses the current locale for a translated symbolic caption" do
      I18n.with_locale(:de) do
        expect(helper.menu_item_locale(menu_item(:different_caption, caption: :label_different_caption))).to be_nil
      end
    end

    it "derives the translation key for a string caption" do
      I18n.with_locale(:de) do
        expect(helper.menu_item_locale(menu_item(:string_caption, caption: "Caption"))).to eq(:en)
      end
    end

    it "marks a missing translation as English" do
      I18n.with_locale(:de) do
        expect(helper.menu_item_locale(menu_item(:missing_caption, caption: :label_missing_caption))).to eq(:en)
      end
    end
  end
end

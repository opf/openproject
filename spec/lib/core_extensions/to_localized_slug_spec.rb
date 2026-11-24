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

RSpec.describe CoreExtensions::String, "#to_localized_slug" do
  let(:input) { "dübelbädel! ..." }
  let(:slug) { input.to_localized_slug }

  it "uses english by default" do
    expect(slug).to eq "dubelbadel-dot-dot-dot"
  end

  context "with a limit and german locale" do
    let(:slug) { input.to_localized_slug(locale: :de, limit: 4) }

    it "limits the localized string" do
      expect(slug).to eq "dueb"
    end
  end

  context "with a limit and english locale" do
    let(:slug) { input.to_localized_slug(locale: :en, limit: 4) }

    it "limits the localized string" do
      expect(slug).to eq "dube"
    end
  end

  context "with a different I18n.locale" do
    before do
      I18n.locale = :de
    end

    it "uses that locale but does not change the backend locale" do
      expect { slug }.not_to change { Stringex::Localization.locale }
      expect(slug).to eq "duebelbaedel-punkt-punkt-punkt"
    end
  end

  context "passing in the locale" do
    let(:slug) { input.to_localized_slug(locale: :de) }

    it "uses that locale but does not change the backend locale" do
      expect { slug }.not_to change { Stringex::Localization.locale }
      expect(slug).to eq "duebelbaedel-punkt-punkt-punkt"
    end
  end
end

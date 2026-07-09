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

RSpec.describe ColorsController do
  let(:current_user) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe "index.html" do
    def fetch
      get "index"
    end

    def expect_redirect_to
      custom_style_path(tab: :default_colors)
    end

    it_behaves_like "a controller action with require_admin"

    it "redirects to the default colors design tab" do
      expect(fetch).to redirect_to(custom_style_path(tab: :default_colors))
    end
  end

  describe "new.html" do
    def fetch
      get "new"
    end
    it_behaves_like "a controller action with require_admin"
  end

  describe "create.html" do
    def fetch
      post "create", params: { color: build(:color).attributes }
    end

    def expect_redirect_to
      Regexp.new(Regexp.escape(custom_style_path(tab: :default_colors)))
    end
    it_behaves_like "a controller action with require_admin"
  end

  describe "edit.html" do
    def fetch
      @available_color = create(:color, id: "1337")
      get "edit", params: { id: "1337" }
    end
    it_behaves_like "a controller action with require_admin"
  end

  describe "update.html" do
    def fetch
      @available_color = create(:color, id: "1337")
      put "update", params: { id: "1337", color: { "name" => "blubs" } }
    end

    def expect_redirect_to
      custom_style_path(tab: :default_colors)
    end
    it_behaves_like "a controller action with require_admin"
  end

  describe "confirm_destroy.html" do
    def fetch
      @available_color = create(:color, id: "1337")
      get "confirm_destroy", params: { id: "1337" }
    end
    it_behaves_like "a controller action with require_admin"
  end

  describe "destroy.html" do
    def fetch
      @available_color = create(:color, id: "1337")
      post "destroy", params: { id: "1337" }
    end

    def expect_redirect_to
      custom_style_path(tab: :default_colors)
    end
    it_behaves_like "a controller action with require_admin"

    it "redirects with 303 See Other" do
      expect(fetch).to have_http_status(:see_other)
      expect(fetch).to redirect_to(custom_style_path(tab: :default_colors))
    end
  end
end

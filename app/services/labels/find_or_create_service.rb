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

module Labels
  class FindOrCreateService
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call(name:)
      existing = Label.named(name).first
      return ServiceResult.success(result: existing) if existing

      create(name)
    end

    private

    def create(name)
      call = CreateService.new(user:).call(name:)
      return call if call.success? || call.errors.symbols_for(:name).exclude?(:taken)

      existing(name)
    end

    def existing(name)
      ServiceResult.success(result: Label.named(name).first!)
    end
  end

  describe "#pwa_cache_name" do
    it "changes when the app title changes" do
      name = helper.pwa_cache_name

      allow(Setting).to receive(:app_title).and_return("Another title")

      expect(helper.pwa_cache_name).not_to eq(name)
    end

    it "changes when the header colour changes" do
      name = helper.pwa_cache_name

      allow(helper).to receive(:header_bg_color).and_return("#123456")

      expect(helper.pwa_cache_name).not_to eq(name)
    end

    it "changes when the version changes" do
      name = helper.pwa_cache_name

      stub_const("OpenProject::VERSION", "0.0.1")

      expect(helper.pwa_cache_name).not_to eq(name)
    end
  end
end

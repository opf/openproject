#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

module OpenProject
  describe Themes do
    before { Themes.clear_themes }

    describe '.new_theme' do
      it 'returns a new theme' do
        theme = Themes.new_theme do |theme|
          theme.identifier = :new_theme
        end
        expect(theme).to be_kind_of Themes::Theme
        expect(theme.identifier).to eq :new_theme
      end
    end

    describe '.themes' do
      it 'returns the known themes' do
        theme = Themes.new_theme
        expect(Themes.themes).to include theme
      end
    end

    describe '.clear_themes' do
      it 'clears the known themes' do
        theme = Themes.new_theme
        Themes.clear_themes
        expect(Themes.themes).to be_empty
      end
    end

    describe '.theme' do
      it 'returns a theme by name' do
        theme = Themes.new_theme do |theme|
          theme.identifier = :new_theme
        end
        expect(Themes.theme(:new_theme)).to be theme
      end

      it 'returns the default theme if theme not found' do
        expect(Themes.theme(:missing_theme)).to be Themes.default_theme
      end
    end

    describe '.default_theme' do
      it 'returns the instance of the default theme class' do
        expect(Themes.default_theme).to be Themes::DefaultTheme.instance
      end
    end

    describe '.each' do
      it 'iterates over the registered themes' do
        Themes.new_theme do |theme|
          theme.identifier = :new_theme
        end
        themes = []
        Themes.each { |theme| themes << theme.identifier }
        expect(themes).to eq [:new_theme]
      end
    end

    describe '.inject' do
      it 'iterates over the registered themes' do
        Themes.new_theme do |theme|
          theme.identifier = :new_theme
        end
        identifiers = Themes.inject [] { |themes, theme| themes << theme.identifier }
        expect(identifiers).to eq [:new_theme]
      end
    end

    describe '.current_theme' do
      it 'returns the theme with identifier defined by current theme identifier' do
        theme = Themes.new_theme do |theme|
          theme.identifier = :new_theme
        end
        allow(Themes).to receive(:application_theme_identifier).and_return :new_theme
        expect(Themes.current_theme).to eq theme
      end

      it "returns the default theme if configured theme wasn't found" do
        allow(Themes).to receive(:application_theme_identifier).and_return :missing_theme
        expect(Themes.current_theme).to eq Themes.default_theme
      end

      describe ' with a given user' do
        let(:user) { FactoryGirl.build(:user) }

        it 'returns the theme identifier defined by the user' do
          user_theme = Themes.new_theme { |t| t.identifier = :user_theme }
          user.pref[:theme] = :user_theme
          expect(Themes.current_theme(user: user)).to eq user_theme
        end

        it 'returns the theme identifier defined by the app' do
          app_theme = Themes.new_theme { |t| t.identifier = :app_theme }
          user.pref[:theme] = nil
          allow(Themes).to receive(:application_theme_identifier).and_return :app_theme
          expect(Themes.current_theme(user: user)).to eq app_theme
        end
      end
    end

    describe '.application_theme_identifier' do
      it 'normalizes current theme setting to a symbol' do
        allow(Setting).to receive(:ui_theme).and_return 'new_theme'
        expect(Themes.application_theme_identifier).to eq :new_theme
      end

      it 'returns nil for an empty string' do
        allow(Setting).to receive(:ui_theme).and_return ''
        expect(Themes.application_theme_identifier).to be_nil
      end

      it 'returns nil for nil' do
        allow(Setting).to receive(:ui_theme).and_return nil
        expect(Themes.application_theme_identifier).to be_nil
      end
    end
  end
end

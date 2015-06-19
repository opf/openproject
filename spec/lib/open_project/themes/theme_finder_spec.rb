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
  module Themes
    describe ThemeFinder do
      before { ThemeFinder.clear_themes }
      # clear theme state after we are finished so that we do not disturb following tests
      after(:all) { ThemeFinder.clear_themes }

      describe '.themes' do
        it 'returns all instances of descendants of themes' do
          theme = Theme.new_theme
          expect(ThemeFinder.themes).to include theme
        end

        # the before filter above removes the default theme as well. to test
        # the correct behaviour we just spec that the default theme class
        # was loaded (by looking through all subclasses of BasicObject)
        it 'always includes the default theme' do
          loaded_classes = Object.descendants
          expect(loaded_classes).to include Themes::DefaultTheme
        end

        # test through the theme instances classes because
        # an abstract theme can't have an instance
        it 'filters out themes marked as abstract' do
          theme_class = Class.new(Theme) { abstract! }
          theme_classes = ThemeFinder.themes.map(&:class)
          expect(theme_classes).not_to include theme_class
        end

        it "subclasses of abstract themes aren't abstract by default" do
          abstract_theme_class = Class.new(Theme) { abstract! }
          theme = Class.new(abstract_theme_class).instance
          expect(ThemeFinder.themes).to include theme
        end
      end

      describe '.registered_themes' do
        it 'returns a hash of themes with their identifiers as keys' do
          theme = Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          expect(ThemeFinder.registered_themes).to include new_theme: theme
        end
      end

      describe '.register_theme' do
        it 'remembers whatever is passed in (this is called by #inherited hook)' do
          theme = double # do not invoke inherited callback
          ThemeFinder.register_theme(theme)
          expect(ThemeFinder.themes).to include theme
        end

        it 'clears the cache successfully' do
          ThemeFinder.registered_themes # fill the cache
          theme = Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          expect(ThemeFinder.registered_themes).to include new_theme: theme
        end

        context 'asset precompilation' do
          around do |example|
            old_precompile_config = Rails.application.config.assets.precompile
            Rails.application.config.assets.precompile.clear
            example.run
            Rails.application.config.assets.precompile = old_precompile_config
          end

          let(:asset_files) {
            %w(
              adn-bootstrap.css
              adn-bootstrap-theme.css
              ms-rainbow-colours.css
              theme_stylesheet.css
            )
          }

          let(:precompile_list) { Rails.application.config.assets.precompile }
          let(:precompiled_assets) {
            asset_files.map { |asset_path|
              precompile_list.map { |element|
                element.respond_to?(:call) ? element.call(asset_path) : element
              }
            }.flatten
          }

          # TODO: remove themes from the list, when clear_themes is called

          context 'with no stylesheet manifest registered' do
            it 'should precompile none of asset files' do
              expect(precompiled_assets).to be_none
            end
          end

          context 'with a missing stylesheet manifest registered' do
            before do
              Class.new(Theme) { def stylesheet_manifest; 'missing_theme_stylesheet.css'; end }
            end

            it 'should precompile none of asset files' do
              expect(precompiled_assets).to be_none
            end
          end

          context 'with a stylesheet manifest registered' do
            before do
              Class.new(Theme) { def stylesheet_manifest; 'theme_stylesheet.css'; end }
            end

            it 'should precompile one of the asset files' do
              expect(precompiled_assets).to be_any
              expect(precompiled_assets.count { |c| c }).to eq 1
            end
          end
        end
      end

      describe '.forget_theme' do
        it 'removes the theme from the themes list' do
          theme = Theme.new_theme
          ThemeFinder.forget_theme(theme)
          expect(ThemeFinder.themes).not_to include theme
        end
      end

      describe '.clear_cache' do
        it 'removes the theme from the registered themes list and clears the cache' do
          theme = Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          ThemeFinder.registered_themes # fill the cache
          ThemeFinder.forget_theme(theme)
          expect(ThemeFinder.registered_themes).not_to include new_theme: theme
        end
      end

      describe '.abstract!' do
        it "abstract themes won't show up in the themes llist" do
          abstract_theme_class = Class.new(Theme) { abstract! }
          theme_classes = ThemeFinder.themes.map(&:class)
          expect(theme_classes).not_to include abstract_theme_class
        end

        it 'the basic theme class is abstract' do
          theme_classes = ThemeFinder.themes.map(&:class)
          expect(theme_classes).not_to include Theme
        end
      end

      describe '.clear_themes' do
        it 'it wipes out all registered themes' do
          theme_class = Class.new(Theme)
          ThemeFinder.clear_themes
          expect(ThemeFinder.themes).to be_empty
        end

        it 'clears the registered themes cache' do
          theme = Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          ThemeFinder.registered_themes # fill the cache
          ThemeFinder.clear_themes
          expect(ThemeFinder.registered_themes).not_to include new_theme: theme
        end
      end

      describe '.each' do
        it 'iterates over all themes' do
          Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          themes = []
          ThemeFinder.each { |theme| themes << theme.identifier }
          expect(themes).to eq [:new_theme]
        end
      end
    end
  end
end

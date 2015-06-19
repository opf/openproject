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
    GoofyTheme = Class.new(Theme)

    describe Theme do
      before { ThemeFinder.clear_themes }

      # class methods

      describe '.new_theme' do
        it 'returns a new theme' do
          theme = Theme.new_theme
          expect(theme).to be_kind_of Theme
        end

        it 'allows passing in the identifier' do
          theme = Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          expect(theme.identifier).to eq :new_theme
        end
      end

      describe '.abstract!' do
        it 'abstract themes have no instance' do
          theme_class = Class.new(Theme) { abstract! }
          expect { theme_class.instance }.to raise_error NoMethodError
        end
      end

      describe '.abstract?' do
        it 'is abstract when marked as abstract' do
          theme_class = Class.new(Theme)
          expect(theme_class).not_to be_abstract
          theme_class.abstract!
          expect(theme_class).to be_abstract
        end
      end

      # duplicates singleton code, just to make sure
      describe '.instance' do
        it 'is an instance of the class' do
          theme_class = Class.new(Theme)
          expect(theme_class.instance.class).to be theme_class
        end

        it 'is a singleton' do
          theme_class = Class.new(Theme)
          expect(theme_class.instance).to be theme_class.instance
        end
      end

      describe '.inherited' do
        it 'is aware of the new theme after inheriting' do
          theme = Theme.new_theme
          expect(ThemeFinder.themes).to include theme
        end
      end

      # instance methods

      describe '#assets_path' do
        it "defaults to the main app's asset path" do
          rails_root = File.expand_path('../../../../..', __FILE__)

          theme = Theme.new_theme
          expect(theme.assets_path).to eq File.join(rails_root, 'app/assets')
        end
      end

      describe '#identifier' do
        it 'symbolizes the identifier from the class name by default' do
          theme = GoofyTheme.instance
          expect(theme.identifier).to eq :goofy
        end
      end

      describe '#name' do
        it 'titlelizes the name from the class name by default' do
          theme = GoofyTheme.instance
          expect(theme.name).to eq 'Goofy'
        end
      end

      describe '#stylesheet_manifest' do
        it 'stringifies the identier and appends the css extension' do
          theme = Theme.new_theme do |theme|
            theme.identifier = :goofy
          end
          expect(theme.stylesheet_manifest).to eq 'goofy.css'
        end
      end

      describe '#overridden_images' do
        let(:theme) { Theme.new_theme }

        context 'with correct path' do
          before do
            # set the dir of this file as the images folder
            allow(theme).to receive(:overridden_images_path).and_return(File.dirname(__FILE__))
          end

          it 'stores images that are overridden by the theme' do
            expect(theme.overridden_images).to include 'theme_spec.rb'
          end

          it "doesn't store images which are not present" do
            expect(theme.overridden_images).not_to include 'missing.rb'
          end
        end

        context 'with incorrect path' do
          before do
            # the theme has a non-existing images path
            allow(theme).to receive(:overridden_images_path).and_return('some/wrong/path')
          end

          it 'wont fail' do
            expect { theme.overridden_images }.not_to raise_error
          end

          it 'has an empty list' do
            expect(theme.overridden_images).to be_empty
          end
        end
      end

      describe '#path_to_image' do
        let(:theme) { Theme.new_theme { |t| t.identifier = :new_theme } }

        before do
          # set a list of overridden images
          allow(theme).to receive(:overridden_images).and_return(['add.png'])
        end

        it 'prepends the theme path if file is present' do
          expect(theme.path_to_image('add.png')).to eq 'new_theme/add.png'
        end

        it "doesn't prepend the theme path if the file is not overridden" do
          expect(theme.path_to_image('missing.png')).to eq 'missing.png'
        end

        it "doesn't change anything if the path is absolute" do
          expect(theme.path_to_image('/add.png')).to eq '/add.png'
        end

        it "doesn't change anything if the source is a url" do
          expect(theme.path_to_image('http://some_host/add.png')).to eq 'http://some_host/add.png'
        end
      end

      describe '#overridden_images_path' do
        let(:theme) { Theme.new_theme { |t| t.identifier = :new_theme } }

        before do
          # set an arbitrary base path for assets
          allow(theme).to receive(:assets_path).and_return('some/assets/path')
        end

        it 'appends the path to images overridden by the theme' do
          expect(theme.overridden_images_path).to eq 'some/assets/path/images/new_theme'
        end
      end

      describe '#image_overridden?' do
        let(:theme) { Theme.new_theme }

        before do
          # set the dir of this file as the images folder
          allow(theme).to receive(:overridden_images_path).and_return(File.dirname(__FILE__))
        end

        it 'is overritten if the theme redefines it' do
          expect(theme.image_overridden?('theme_spec.rb')).to be_truthy
        end

        it "is not overritten if the theme doesn't redefine it" do
          expect(theme.image_overridden?('missing.rb')).to be_falsey
        end
      end

      describe '#stylesheet_manifest' do
        it 'equals the name of the theme with a css extension' do
          theme = Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          expect(theme.stylesheet_manifest).to eq 'new_theme.css'
        end
      end

      describe '#assets_prefix' do
        it 'equals the name of the theme' do
          theme = Theme.new_theme do |theme|
            theme.identifier = :new_theme
          end
          expect(theme.assets_prefix).to eq 'new_theme'
        end
      end

      describe '#<=>' do
        it 'is equal when the classes match' do
          theme_class = Class.new(Theme)
          expect(theme_class.instance).to eq theme_class.instance
        end

        it "is not equal when the classes don't match" do
          expect(Class.new(Theme).instance).not_to eq Class.new(Theme).instance
        end
      end
    end

    describe ViewHelpers do
      let(:theme)   { Theme.new_theme { |t| t.identifier = :new_theme } }
      let(:helpers) { ApplicationController.helpers }

      before do
        # set a list of overridden images
        allow(theme).to receive(:overridden_images).and_return(['add.png'])

        # set the theme as current
        allow(helpers).to receive(:current_theme).and_return(theme)
      end

      it 'overridden images are nested' do
        expect(helpers.image_tag('add.png')).to include 'src="/assets/new_theme/add.png"'
      end

      it 'not overridden images are on root level' do
        expect(helpers.image_tag('missing.png')).to include 'src="/assets/missing.png"'
      end

      it 'overridden favicon is nested' do
        expect(helpers.favicon_link_tag('add.png')).to include 'href="/assets/new_theme/add.png"'
      end

      it 'not overridden favicon is on root level' do
        expect(helpers.favicon_link_tag('missing.png')).to include 'href="/assets/missing.png"'
      end
    end
  end
end

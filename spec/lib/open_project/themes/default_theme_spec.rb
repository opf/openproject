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
    describe DefaultTheme do
      let(:theme) { DefaultTheme.instance }

      describe '#name' do
        it 'is called OpenProject' do
          expect(theme.name).to eq 'OpenProject'
        end
      end

      describe '#stylesheet_manifest' do
        it 'is default with a css extension' do
          expect(theme.stylesheet_manifest).to eq 'default.css'
        end
      end

      describe '#assets_prefix' do
        it 'is empty' do
          expect(theme.assets_prefix).to be_empty
        end
      end

      describe '#assets_path' do
        it 'should be the assets path of the rails app' do
          rails_root = File.expand_path('../../../../..', __FILE__)
          expect(theme.assets_path).to eq File.join(rails_root, 'app/assets')
        end
      end

      describe '#overridden_images' do
        it 'is empty' do
          expect(theme.overridden_images).to be_empty
        end
      end

      describe '#path_to_image' do
        before do
          # set a list of overridden images, which default theme should ignore
          allow(theme).to receive(:overridden_images).and_return(['add.png'])
        end

        it "doesn't prepend the theme path for the default theme" do
          expect(theme.path_to_image('add.png')).to eq 'add.png'
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
        it 'should be nil' do
          expect(theme.overridden_images_path).to be_nil
        end
      end

      describe '#image_overridden?' do
        before do
          # set the dir of this file as the images folder
          # default theme should ignore all files in it
          allow(theme).to receive(:overridden_images_path).and_return(File.dirname(__FILE__))
        end

        it 'is false' do
          expect(theme.image_overridden?('theme_spec.rb')).to be_falsey
        end
      end
    end

    describe ViewHelpers do
      let(:theme)   { DefaultTheme.instance }
      let(:helpers) { ApplicationController.helpers }

      before do
        # set a list of overridden images
        allow(theme).to receive(:overridden_images).and_return(['add.png'])

        # set the theme as current
        allow(helpers).to receive(:current_theme).and_return(theme)
      end

      it 'overridden images are on root level' do
        expect(helpers.image_tag('add.png')).to include 'src="/assets/add.png"'
      end

      it 'not overridden images are on root level' do
        expect(helpers.image_tag('missing.png')).to include 'src="/assets/missing.png"'
      end

      it 'overridden favicon is on root level' do
        expect(helpers.favicon_link_tag('add.png')).to include 'href="/assets/add.png"'
      end

      it 'not overridden favicon is on root level' do
        expect(helpers.favicon_link_tag('missing.png')).to include 'href="/assets/missing.png"'
      end
    end
  end
end

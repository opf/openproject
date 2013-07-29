#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

module OpenProject
  module Themes
    describe ViewHelpers do
      let(:helpers) { ApplicationController.helpers }

      it "is mixed into application controller's helper chain" do
        expect { helpers.current_theme }.to_not raise_error NoMethodError
        expect { helpers.image_tag }.to_not raise_error NoMethodError
      end

      describe '#current_theme' do
        it "returns whatever the Themes class returns" do
          theme = Themes.new_theme
          Themes.stub(:current_theme).and_return theme
          expect(helpers.current_theme).to eq theme
        end
      end

      describe '#favicon_link_tag' do
        let(:theme) { Theme.new_theme(:new_theme) }

        before do
          # set a list of overridden images
          theme.stub(:overridden_images).and_return(['add.png'])

          # set the theme as current
          helpers.stub(:current_theme).and_return(theme)
        end

        it 'it is nested if overridden' do
          expect(helpers.favicon_link_tag('add.png')).to include 'href="/assets/new_theme/add.png"'
        end

        it 'it is on root level if not overridden' do
          expect(helpers.favicon_link_tag('missing.png')).to include 'href="/assets/missing.png"'
        end

        it 'it is unchanged if absolute path' do
          expect(helpers.favicon_link_tag('/add.png')).to include 'href="/add.png"'
        end

        it 'it is unchanged if url' do
          expect(helpers.favicon_link_tag('http://some_host/add.png')).to include 'href="http://some_host/add.png"'
        end
      end

      describe '#image_tag' do
        let(:theme) { Theme.new_theme(:new_theme) }

        before do
          # set a list of overridden images
          theme.stub(:overridden_images).and_return(['add.png'])

          # set the theme as current
          helpers.stub(:current_theme).and_return(theme)
        end

        it 'it is nested if overridden' do
          expect(helpers.image_tag('add.png')).to include 'src="/assets/new_theme/add.png"'
        end

        it 'it is on root level if not overridden' do
          expect(helpers.image_tag('missing.png')).to include 'src="/assets/missing.png"'
        end

        it 'it is unchanged if absolute path' do
          expect(helpers.image_tag('/add.png')).to include 'src="/add.png"'
        end

        it 'it is unchanged if url' do
          expect(helpers.image_tag('http://some_host/add.png')).to include 'src="http://some_host/add.png"'
        end
      end
    end
  end
end

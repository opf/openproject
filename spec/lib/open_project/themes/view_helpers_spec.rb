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
    describe ViewHelpers do
      let(:helpers) { ApplicationController.helpers }

      it "is mixed into application controller's helper chain" do
        expect { helpers.current_theme }.not_to raise_error
        expect { helpers.image_tag('example.png') }.not_to raise_error
      end

      describe '#current_theme' do
        it 'returns whatever the Themes class returns' do
          theme = Themes.new_theme
          allow(Themes).to receive(:current_theme).and_return theme
          expect(helpers.current_theme).to eq theme
        end
      end

      describe '#favicon_link_tag' do
        let(:theme) { Theme.new_theme { |t| t.identifier = :new_theme } }

        before do
          # set a list of overridden images
          allow(theme).to receive(:overridden_images).and_return(['add.png'])

          # set the theme as current
          allow(helpers).to receive(:current_theme).and_return(theme)
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
        let(:theme) { Theme.new_theme { |t| t.identifier = :new_theme } }

        before do
          # set a list of overridden images
          allow(theme).to receive(:overridden_images).and_return(['add.png'])

          # set the theme as current
          allow(helpers).to receive(:current_theme).and_return(theme)
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

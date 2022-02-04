#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
require 'spec_helper'

describe ::RailsCell do
  let(:controller) { double(ApplicationController) }
  let(:action_view) { ActionView::Base.new(ActionView::LookupContext.new(''), {}, controller) }
  let(:model) { double('model', foo: '<strong>Some HTML here!</strong>') }
  let(:context) do
    { controller: controller }
  end
  let(:options) do
    { context: context }
  end

  let(:test_cell) do
    Class.new(described_class) do
      property :foo

      def link
        link_to "<strong>HTML</strong>", '/foo/bar'
      end

      def content
        content_tag(:div) do
          content_tag(:span) do
            "<script>foo</script>"
          end
        end
      end
    end
  end

  let(:instance) { test_cell.new model, options }

  before do
    allow(controller).to receive(:view_context).and_return(action_view)
  end

  shared_examples 'uses action_view helpers' do
    describe '#link' do
      subject { instance.link }

      it 'uses link_to from rails with escaping' do
        expect(subject.to_s).to eq %(<a href="/foo/bar">&lt;strong&gt;HTML&lt;/strong&gt;</a>)
      end
    end

    describe '#foo' do
      subject { instance.foo }

      it 'escapes the property' do
        expect(subject.to_s).to eq "&lt;strong&gt;Some HTML here!&lt;/strong&gt;"
      end
    end

    describe '#content' do
      subject { instance.content }

      it 'uses content_tag from rails with escaping', :aggregate_failures do
        expect(action_view).to receive(:content_tag).twice.and_call_original
        expect(subject.to_s).to eq "<div><span>&lt;script&gt;foo&lt;/script&gt;</span></div>"
      end
    end
  end

  describe 'delegate to action_view' do
    context 'when action_view set' do
      let(:context) do
        { controller: controller, action_view: action_view }
      end

      it_behaves_like 'uses action_view helpers'
    end

    context 'when not set' do
      it_behaves_like 'uses action_view helpers'
    end
  end
end

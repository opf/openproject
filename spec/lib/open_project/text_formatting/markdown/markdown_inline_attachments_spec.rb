#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::TextFormatting::Formats::Markdown::Formatter do
  let(:context) { {} }
  let(:subject) { described_class.new(context).to_html(text) }

  describe 'work package with attachments' do
    let!(:work_package) { FactoryBot.create :work_package }
    let!(:inlinable) do
      FactoryBot.create(:attached_picture, filename: 'my-image.jpg', description: '"foobar"', container: work_package)
    end
    let(:context) { { object: work_package, only_path: true } }

    let!(:non_inlinable) do
      FactoryBot.create(:attachment, filename: 'whatever.pdf', container: work_package)
    end

    it 'inlines only the inlineable attachment' do
      work_package.attachments.reload
      assert_html_output(
        '![](my-image.jpg)' => %(<img src="/api/v3/attachments/#{inlinable.id}/content" alt='"foobar"'>),
        '![alt-text](my-image.jpg)' => %(<img src="/api/v3/attachments/#{inlinable.id}/content" alt="alt-text">),
        '![foo](does-not-exist.jpg)' => %(<img src="does-not-exist.jpg" alt="foo">),
        '![](whatever.pdf)' => %(<img src="whatever.pdf" alt="">),
        '![](some/path/to/my-image.jpg)' => %(<img src="some/path/to/my-image.jpg" alt="">)
      )
    end

    context 'with only_path=false' do
      let(:context) { { object: work_package, only_path: false } }

      it 'inlines only the inlineable attachment' do
        work_package.attachments.reload
        expected_url = "http://localhost:3000/api/v3/attachments/#{inlinable.id}/content"

        assert_html_output('![](my-image.jpg)' => %(<img src="#{expected_url}" alt='"foobar"'>))
      end
    end
  end

  private

  def assert_html_output(to_test)
    instance = described_class.new(context)
    to_test.each do |text, expected|
      expect(instance.to_html(text)).to be_html_eql "<p>#{expected}</p>"
    end
  end
end

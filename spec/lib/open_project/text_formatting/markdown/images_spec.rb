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

require_relative "expected_markdown"
RSpec.describe OpenProject::TextFormatting,
               "images" do
  include_context "expected markdown modules"

  let(:options) { {} }

  context "inline linking attachments" do
    context "work package with attachments" do
      let!(:work_package) do
        build_stubbed(:work_package).tap do |wp|
          allow(wp)
            .to receive(:attachments)
            .and_return attachments
        end
      end
      let(:attachments) { [inlinable, non_inlinable] }
      let!(:inlinable) do
        build_stubbed(:attached_picture) do |a|
          allow(a)
            .to receive(:filename)
            .and_return("my-image.jpg")
          allow(a)
            .to receive(:description)
            .and_return('"foobar"')
        end
      end
      let!(:non_inlinable) do
        build_stubbed(:attachment) do |a|
          allow(a)
            .to receive(:filename)
            .and_return("whatever.pdf")
        end
      end

      let(:only_path) { true }

      let(:options) { { object: work_package, only_path: } }

      context "for an inlineable attachment referenced by filename" do
        it_behaves_like "format_text produces" do
          let(:raw) do
            <<~RAW
              ![](my-image.jpg)
            RAW
          end

          let(:expected) do
            <<~EXPECTED
              <p class="op-uc-p">
                <figure class="op-uc-figure">
                  <div class="op-uc-figure--content">
                    <img class="op-uc-image" src="/api/v3/attachments/#{inlinable.id}/content" alt='"foobar"'>
                  </div>
                </figure>
              </p>
            EXPECTED
          end
        end

        context "with only_path false" do
          let(:only_path) { false }

          it_behaves_like "format_text produces" do
            let(:raw) do
              <<~RAW
                ![](my-image.jpg)
              RAW
            end

            let(:expected) do
              <<~EXPECTED
                <p class="op-uc-p">
                  <figure class="op-uc-figure">
                    <div class="op-uc-figure--content">
                      <img class="op-uc-image" src="http://localhost:3000/api/v3/attachments/#{inlinable.id}/content" alt='"foobar"'>
                    </div>
                  </figure>
                </p>
              EXPECTED
            end
          end
        end
      end

      context "for an inlineable attachment referenced by filename and alt-text" do
        it_behaves_like "format_text produces" do
          let(:raw) do
            <<~RAW
              ![alt-text](my-image.jpg)
            RAW
          end

          let(:expected) do
            <<~EXPECTED
              <p class="op-uc-p">
                <figure class="op-uc-figure">
                  <div class="op-uc-figure--content">
                    <img class="op-uc-image" src="/api/v3/attachments/#{inlinable.id}/content" alt="alt-text">
                  </div>
                </figure>
              </p>
            EXPECTED
          end
        end
      end

      context "for a non existing attachment and alt-text" do
        it_behaves_like "format_text produces" do
          let(:raw) do
            <<~RAW
              ![foo](does-not-exist.jpg)
            RAW
          end

          let(:expected) do
            <<~EXPECTED
              <p class="op-uc-p">
                <figure class="op-uc-figure">
                  <div class="op-uc-figure--content">
                    <img class="op-uc-image" src="does-not-exist.jpg" alt="foo">
                  </div>
                </figure>
              </p>
            EXPECTED
          end
        end
      end

      context "for a non inlineable attachment (non image)" do
        it_behaves_like "format_text produces" do
          let(:raw) do
            <<~RAW
              ![](whatever.pdf)
            RAW
          end

          let(:expected) do
            <<~EXPECTED
              <p class="op-uc-p">
                <figure class="op-uc-figure">
                  <div class="op-uc-figure--content">
                    <img class="op-uc-image" src="whatever.pdf" alt="">
                  </div>
                </figure>
              </p>
            EXPECTED
          end
        end
      end

      context "for a relative url (non attachment)" do
        it_behaves_like "format_text produces" do
          let(:raw) do
            <<~RAW
              ![](some/path/to/my-image.jpg)
            RAW
          end

          let(:expected) do
            <<~EXPECTED
              <p class="op-uc-p">
                <figure class="op-uc-figure">
                  <div class="op-uc-figure--content">
                    <img class="op-uc-image" src="some/path/to/my-image.jpg" alt="">
                  </div>
                </figure>
              </p>
            EXPECTED
          end
        end
      end

      context "for a relative url (non attachment)" do
        it_behaves_like "format_text produces" do
          let(:raw) do
            <<~RAW
              ![](some/path/to/my-image.jpg)
            RAW
          end

          let(:expected) do
            <<~EXPECTED
              <p class="op-uc-p">
                <figure class="op-uc-figure">
                  <div class="op-uc-figure--content">
                    <img class="op-uc-image" src="some/path/to/my-image.jpg" alt="">
                  </div>
                </figure>
              </p>
            EXPECTED
          end
        end
      end
    end

    context "escaping of malicious image urls" do
      it_behaves_like "format_text produces" do
        let(:raw) do
          <<~RAW
            ![](/images/comment.png"onclick=&#x61;&#x6c;&#x65;&#x72;&#x74;&#x28;&#x27;&#x58;&#x53;&#x53;&#x27;&#x29;;&#x22;)
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p class="op-uc-p">
              <figure class="op-uc-figure">
                <div class="op-uc-figure--content">
                  <img class="op-uc-image" src="/images/comment.png%22onclick=alert('XSS');%22" alt="">
                </div>
              </figure>
            </p>
          EXPECTED
        end
      end
    end
  end

  context "via html tags" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          <figure class="image op-uc-figure" style="width:50%">
            <img src="/api/v3/attachments/1293/content">
            <figcaption>Some caption with meaning</figcaption>
          </figure>
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <figure class="image op-uc-figure" style="width:50%">
            <div class="op-uc-figure--content">
              <img src="/api/v3/attachments/1293/content" class="op-uc-image">
            </div>
            <figcaption class="op-uc-figure--description">Some caption with meaning</figcaption>
          </figure>
        EXPECTED
      end
    end
  end
end

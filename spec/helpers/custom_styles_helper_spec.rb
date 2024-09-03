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

RSpec.describe CustomStylesHelper do
  let(:current_theme) { nil }
  let(:bim_edition?) { false }

  before do
    allow(CustomStyle).to receive(:current).and_return(current_theme)
    allow(OpenProject::Configuration).to receive(:bim?).and_return(bim_edition?)
  end

  describe ".apply_custom_styles?" do
    subject { helper.apply_custom_styles? }

    context "no CustomStyle present" do
      it "is falsey" do
        expect(subject).to be_falsey
      end
    end

    context "CustomStyle present" do
      let(:current_theme) { build_stubbed(:custom_style) }

      context "without EE", with_ee: false do
        context "no BIM edition" do
          it "is falsey" do
            expect(subject).to be_falsey
          end
        end

        context "BIM edition" do
          let(:bim_edition?) { true }

          it "is truthy" do
            expect(subject).to be_truthy
          end
        end
      end

      context "with EE", with_ee: %i[define_custom_style] do
        context "no BIM edition" do
          it "is truthy" do
            expect(subject).to be_truthy
          end
        end

        context "BIM edition" do
          let(:bim_edition?) { true }

          it "is truthy" do
            expect(subject).to be_truthy
          end
        end
      end
    end
  end

  shared_examples("apply when ee present") do
    context "no CustomStyle present" do
      it "is falsey" do
        expect(subject).to be_falsey
      end
    end

    context "CustomStyle present" do
      let(:current_theme) { build_stubbed(:custom_style) }

      before do
        allow(current_theme).to receive(:favicon).and_return(true)
        allow(current_theme).to receive(:touch_icon).and_return(true)
      end

      context "without EE", with_ee: false do
        it "is falsey" do
          expect(subject).to be_falsey
        end
      end

      context "with EE", with_ee: %i[define_custom_style] do
        it "is truthy" do
          expect(subject).to be_truthy
        end
      end
    end
  end

  describe ".apply_custom_favicon?" do
    subject { helper.apply_custom_favicon? }

    it_behaves_like "apply when ee present"
  end

  describe ".apply_custom_touch_icon?" do
    subject { helper.apply_custom_touch_icon? }

    it_behaves_like "apply when ee present"
  end
end

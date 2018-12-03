#-- copyright

# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::WorkPackages::Filter::SearchFilter, type: :model do
  let(:context) { nil }
  let(:value) { 'bogus' }
  let(:operator) { '~' }
  let(:subject) { 'Some subject' }
  let(:work_package) { FactoryBot.create(:work_package, subject: subject) }
  let(:instance) do
    described_class.create!(name: :search, context: context, operator: operator, values: [value])
  end

  context 'WP without attachment' do
    let(:work_package) { FactoryBot.create(:work_package, subject: "A bogus subject", description: "And a short description") }
    it 'finds in subject' do
      instance.values = ['bogus subject']
      expect(WorkPackage.where(instance.where))
        .to match_array [work_package]
    end
    it 'finds in description' do
      instance.values = ['short description']
      expect(WorkPackage.where(instance.where))
        .to match_array [work_package]
    end
  end

  context 'WP with attachment' do
    let(:text) { 'lorem ipsum' }
    # let(:filename) { 'plaintext-file.txt' }
    # let(:attachment) { FactoryBot.create(:attachment, container: work_package, file: filename) }
    let(:attachment) { FactoryBot.create(:attachment, container: work_package) }

    before do
      allow_any_instance_of(Plaintext::Resolver).to receive(:text).and_return(text)
      allow(attachment).to receive(:readable?).and_return(true)
      attachment.reload
    end

    it "finds in attachment content" do
      instance.values = ['ipsum']
      expect(WorkPackage.joins(:attachments).where(instance.where))
        .to match_array [work_package]
    end

    # it "finds in attachment content" do
    #   instance.values = [filename]
    #   expect(WorkPackage.joins(:attachments).where(instance.where))
    #     .to match_array [work_package]
    # end
  end

  if OpenProject::Database.allows_tsv?
    before do
      allow(EnterpriseToken).to receive(:allows_to?).and_return(false)
      allow(EnterpriseToken).to receive(:allows_to?).with(:attachment_filters).and_return(true)
    end

    it_behaves_like 'basic query filter' do
      let(:type) { :search }
      let(:class_key) { :search }

      describe '#available?' do
        it 'is available' do
          expect(instance).to be_available
        end
      end

      describe '#allowed_values' do
        it 'is nil' do
          expect(instance.allowed_values).to be_nil
        end
      end

      describe '#valid_values!' do
        it 'is a noop' do
          instance.values = ['none', 'is', 'changed']

          instance.valid_values!

          expect(instance.values)
            .to match_array ['none', 'is', 'changed']
        end
      end

      it_behaves_like 'non ar filter'
    end
  end
end

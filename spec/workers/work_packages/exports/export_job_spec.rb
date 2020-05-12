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

describe WorkPackages::Exports::ExportJob do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:export) do
    FactoryBot.build_stubbed(:work_packages_export, user: user)
  end
  let(:query) { FactoryBot.build_stubbed(:query) }
  let(:query_attributes) { {} }

  let(:instance) { described_class.new }
  let(:options) { {} }
  subject do
    instance.perform(export: export,
                     mime_type: mime_type,
                     options: options,
                     query: query,
                     query_attributes: query_attributes)
  end

  shared_examples_for 'exporter returning string' do
    it 'exports' do
      content = 'some string'

      result = WorkPackage::Exporter::Result::Success.new(format: 'blubs',
                                                          title: "some_title.#{mime_type}",
                                                          content: content,
                                                          mime_type: "application/octet-stream")

      service = double('attachments create service')

      expect(Attachments::CreateService)
        .to receive(:new)
        .with(export, author: user)
        .and_return(service)

      expect(WorkPackages::Exports::CleanupOutdatedJob)
        .to receive(:perform_after_grace)

      expect(service)
        .to receive(:call) do |uploaded_file:, description:|
        expect(File.basename(uploaded_file))
          .to start_with 'some_title'

        expect(File.basename(uploaded_file))
          .to end_with ".#{mime_type}"
      end

      allow("WorkPackage::Exporter::#{mime_type.upcase}".constantize)
        .to receive(:list)
        .and_yield(result)

      subject
    end
  end

  describe 'query passing' do
    context 'passing in group_by through attributes' do
      let(:query_attributes) { { group_by: 'assigned_to' }}
      let(:mime_type) { :pdf }

      it 'updates the query from attributes' do
        expect("WorkPackage::Exporter::#{mime_type.upcase}".constantize)
          .to receive(:list) do |query, _options|
          expect(query.group_by).to eq 'assigned_to'
        end

        subject
      end
    end
  end

  describe '#perform' do
    context 'with the pdf mime type' do
      let(:mime_type) { :pdf }

      it_behaves_like 'exporter returning string'
    end
  end

  describe '#perform' do
    context 'with the csv mime type' do
      let(:mime_type) { :csv }

      it_behaves_like 'exporter returning string'
    end
  end
end

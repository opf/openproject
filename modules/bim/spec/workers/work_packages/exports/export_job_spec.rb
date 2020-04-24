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

  let(:instance) { described_class.new }
  let(:options) { {} }
  subject do
    instance.perform(export: export,
                     mime_type: mime_type,
                     options: options,
                     query: query,
                     query_attributes: {})
  end

  describe '#perform' do
    context 'with the bcf mime type' do
      let(:mime_type) { :bcf }

      it 'issues an OpenProject::Bim::BcfXml::Exporter export' do
        file = double(File)
        allow(file)
          .to receive(:is_a?)
          .with(File)
          .and_return true

        result = WorkPackage::Exporter::Result::Success.new(format: 'blubs',
                                                            title: 'some_title',
                                                            content: file,
                                                            mime_type: "application/octet-stream")

        service = double('attachments create service')

        expect(Attachments::CreateService)
          .to receive(:new)
          .with(export, author: user)
          .and_return(service)

        expect(WorkPackages::Exports::CleanupOutdatedJob)
          .to receive(:perform_after_grace)

        expect(service)
          .to receive(:call)
          .with(uploaded_file: file, description: '')

        allow(OpenProject::Bim::BcfXml::Exporter)
          .to receive(:list)
          .and_yield(result)

        subject
      end
    end
  end
end

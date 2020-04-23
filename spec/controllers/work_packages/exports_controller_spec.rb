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

describe WorkPackages::ExportsController, type: :controller do
  include ::API::V3::Utilities::PathHelper

  before do
    login_as current_user
  end

  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:current_user) { user }
  let!(:export) do
    FactoryBot.build_stubbed(:work_packages_export, user: user).tap do |export|
      allow(WorkPackages::Export)
        .to receive(:find)
        .and_raise(ActiveRecord::RecordNotFound)

      allow(WorkPackages::Export)
        .to receive(:find)
        .with(export.id.to_s)
        .and_return(export)
    end
  end
  let!(:attachment) do
    FactoryBot.build_stubbed(:attachment, container: export).tap do |a|
      export_attachments = attachment_done ? [a] : []

      allow(export)
        .to receive(:attachments)
        .and_return(export_attachments)
    end
  end

  let(:status) { 'in_queue' }
  let(:job_message) { '' }
  let!(:job_status) do
    FactoryBot.build_stubbed(:delayed_job_status, status: status, message: job_message).tap do |s|
      relation = double('AR relation')
      allow(Delayed::Job::Status)
        .to receive(:of_reference)
        .with(export)
        .and_return(relation)

      allow(relation)
        .to receive(:first)
        .and_return(s)
    end
  end
  let(:attachment_done) { true }

  describe 'show' do
    context 'with an existing id' do
      before do
        get 'show', params: { id: export.id }
      end

      context 'with the attachment being ready' do
        it 'redirects to the download location' do
          expect(response)
            .to redirect_to api_v3_paths.attachment_content(attachment.id)
        end
      end

      context 'with the attachment not being ready' do
        let(:attachment_done) { false }

        it 'returns 202 ACCEPTED' do
          expect(response.status)
            .to eql 202
        end

        it 'returns the status location via the link header' do
          expect(response.headers['Link'])
            .to eql "</work_packages/exports/#{export.id}/status.json> rel=\"status\""
        end
      end

      context 'with the export belonging to a different user' do
        let(:current_user) { FactoryBot.build_stubbed(:user) }

        it 'returns 404 NOT FOUND' do
          expect(response.status)
            .to eql 404
        end
      end
    end

    context 'with an inexisting id' do
      before do
        get 'show', params: { id: export.id + 5 }
      end

      it 'returns 404 NOT FOUND' do
        expect(response.status)
          .to eql 404
      end
    end
  end

  describe 'status' do
    context 'with an existing id' do
      before do
        get 'status', params: { id: export.id, format: :json }
      end

      context 'with the associated job status signaling success' do
        let(:status) { :success }

        it 'returns 200 OK' do
          expect(response.status)
            .to eql 200
        end

        it 'links to the download location' do
          expect(response.headers['Link'])
            .to eql "<#{api_v3_paths.attachment_content(attachment.id)}> rel=\"download\""
        end

        it 'reads "Completed"' do
          expect(response.body)
            .to be_json_eql({ "status": "Completed",
                              "message": "",
                              "link": api_v3_paths.attachment_content(attachment.id) }.to_json)
        end
      end

      context 'with the associated job status being in_queue' do
        let(:status) { 'in_queue' }

        it 'returns 200 OK' do
          expect(response.status)
            .to eql 200
        end

        it 'has no link to the download' do
          expect(response.headers['Link'])
            .to be nil
        end

        it 'reads "Processing"' do
          expect(response.body)
            .to be_json_eql({ "status": "Processing",
                              "message": "" }.to_json)
        end
      end

      context 'with the associated job status being in_process' do
        let(:status) { :in_process }

        it 'returns 200 OK' do
          expect(response.status)
            .to eql 200
        end

        it 'has no link to the download' do
          expect(response.headers['Link'])
            .to be nil
        end

        it 'reads "Processing"' do
          expect(response.body)
            .to be_json_eql({ "status": "Processing",
                              "message": "" }.to_json)
        end
      end

      context 'with the associated job status being error' do
        let(:status) { :error }
        let(:job_message) { 'This errored.' }

        it 'returns 200 OK' do
          expect(response.status)
            .to eql 200
        end

        it 'has no link to the download' do
          expect(response.headers['Link'])
            .to be nil
        end

        it 'reads "Error" with the error message' do
          expect(response.body)
            .to be_json_eql({ "status": "Error",
                              "message": job_message }.to_json)
        end
      end

      context 'with the associated job status being failure' do
        let(:status) { :failure }
        let(:job_message) { 'This failed.' }

        it 'returns 200 OK' do
          expect(response.status)
            .to eql 200
        end

        it 'has no link to the download' do
          expect(response.headers['Link'])
            .to be nil
        end

        it 'reads "Error" with the error message' do
          expect(response.body)
            .to be_json_eql({ "status": "Error",
                              "message": job_message }.to_json)
        end
      end

      context 'with the export belonging to a different user' do
        let(:current_user) { FactoryBot.build_stubbed(:user) }

        it 'returns 404 NOT FOUND' do
          expect(response.status)
            .to eql 404
        end
      end
    end

    context 'with an inexisting id' do
      before do
        get 'show', params: { id: export.id + 5, format: :json }
      end

      it 'returns 404 NOT FOUND' do
        expect(response.status)
          .to eql 404
      end
    end
  end
end

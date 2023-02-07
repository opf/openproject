# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

require 'spec_helper'

# Note: The specs in this file do not attempt to test the properties themselves with all their possible
# variations. This is done in length in the work_package_representer_spec.rb. Instead, the focus of the tests
# here are on the selection of properties.
describe API::V3::WorkPackages::WorkPackageAtTimestampRepresenter, 'rendering' do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }
  let(:embed_links) { false }
  let(:timestamps) { nil }
  let(:query) { nil }
  let(:properties) do
    %w[
      subject
      start_date
      due_date
      assignee
      responsible
      project
      status
      priority
      type
      version
    ]
  end

  let(:due_date) { Date.current + 5.days }
  let(:start_date) { Date.current - 5.days }
  let(:assigned_to) { build_stubbed(:user) }
  let(:responsible) { build_stubbed(:user) }
  let(:status) { build_stubbed(:status) }
  let(:type) { build_stubbed(:type) }
  let(:priority) { build_stubbed(:priority) }
  let(:version) { build_stubbed(:version) }
  let(:project) { build_stubbed(:project) }

  let(:work_package) do
    build_stubbed(:work_package,
                  project:,
                  status:,
                  due_date:,
                  start_date:,
                  assigned_to:,
                  type:,
                  priority:,
                  version:,
                  responsible:).tap do |wp|
      allow(wp)
        .to receive(:respond_to?)
              .and_call_original
      allow(wp)
        .to receive(:respond_to?)
              .with(:wrapped?)
              .and_return(true)
    end
  end
  let(:timestamp) { Timestamp.new }

  let(:attributes_by_timestamp) do
    {
      timestamp.to_s => OpenStruct.new(work_package.attributes)
    }
  end
  let(:journables_by_timestamp) do
    {
      timestamp.to_s => work_package
    }
  end
  let(:exists_at_timestamps) { [timestamp.to_s] }
  let(:matches_query_filters_at_timestamps) { { timestamp.to_s => true } }

  let(:model) do
    # Mimicking the eager loading wrapper
    work_package.tap do |model|
      allow(model)
        .to receive(:journables_by_timestamp)
              .and_return(journables_by_timestamp)
      allow(model)
        .to receive(:attributes_by_timestamp)
              .and_return(attributes_by_timestamp)
      allow(model)
        .to receive(:exists_at_timestamps)
              .and_return(exists_at_timestamps)
      allow(model)
        .to receive(:matches_query_filters_at_timestamps)
              .and_return(matches_query_filters_at_timestamps)
      allow(model)
        .to receive(:matches_query_filters_at_timestamp?)
              .with(timestamp)
              .and_return(matches_query_filters_at_timestamps[timestamp.to_s])
              #allow(model)
      #  .to receive(:respond_to?)
      #        .and_call_original
      allow(model)
        .to receive(:respond_to?)
              .with(:matches_query_filters_at_timestamps)
              .and_return(true)
    end
  end

  let(:representer) do
    described_class.create(model, current_user:, timestamp:)
  end

  subject(:generated) { representer.to_json }

  context 'with all supported properties requested' do
    let(:expected_json) do
      {
        'subject' => work_package.subject,
        'startDate' => work_package.start_date,
        'dueDate' => work_package.due_date,
        '_meta' => {
          'matchesFilters' => true,
          'exists' => true,
          'timestamp' => timestamp.to_s
        },
        '_links' => {
          'assignee' => {
            'href' => api_v3_paths.user(assigned_to.id),
            'title' => assigned_to.name
          },
          'responsible' => {
            'href' => api_v3_paths.user(responsible.id),
            'title' => responsible.name
          },
          'project' => {
            'href' => api_v3_paths.project(project.id),
            'title' => project.name
          },
          'status' => {
            'href' => api_v3_paths.status(status.id),
            'title' => status.name
          },
          'type' => {
            'href' => api_v3_paths.type(type.id),
            'title' => type.name
          },
          'priority' => {
            'href' => api_v3_paths.priority(priority.id),
            'title' => priority.name
          },
          'version' => {
            'href' => api_v3_paths.version(version.id),
            'title' => version.name
          },
          'self' => {
            'href' => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            'title' => work_package.subject
          }
        }
      }.to_json
    end

    it 'renders as expected' do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context 'with a subset of supported properties' do
    let(:attributes_by_timestamp) do
      {
        timestamp.to_s => OpenStruct.new(work_package.attributes.slice('start_date', 'assigned_to_id', 'version_id'))
      }
    end

    let(:expected_json) do
      {
        'startDate' => work_package.start_date,
        '_meta' => {
          'matchesFilters' => true,
          'exists' => true,
          'timestamp' => timestamp.to_s
        },
        '_links' => {
          'assignee' => {
            'href' => api_v3_paths.user(assigned_to.id),
            'title' => assigned_to.name
          },
          'version' => {
            'href' => api_v3_paths.version(version.id),
            'title' => version.name
          },
          'self' => {
            'href' => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            'title' => work_package.subject
          }
        }
      }.to_json
    end

    it 'renders as expected' do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context 'without a linked property' do
    let(:attributes_by_timestamp) do
      {
        timestamp.to_s => OpenStruct.new(work_package.attributes.slice('subject', 'start_date'))
      }
    end

    let(:expected_json) do
      {
        'subject' => work_package.subject,
        'startDate' => work_package.start_date,
        '_meta' => {
          'matchesFilters' => true,
          'exists' => true,
          'timestamp' => timestamp.to_s
        },
        '_links' => {
          'self' => {
            'href' => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            'title' => work_package.subject
          }
        }
      }.to_json
    end

    it 'renders with only `self` in links' do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context 'with a nil value for a linked property' do
    let(:assigned_to) { nil }

    let(:attributes_by_timestamp) do
      {
        timestamp.to_s => OpenStruct.new(work_package.attributes.slice('assigned_to_id'))
      }
    end

    let(:expected_json) do
      {
        '_meta' => {
          'matchesFilters' => true,
          'exists' => true,
          'timestamp' => timestamp.to_s
        },
        '_links' => {
          'assignee' => {
            'href' => nil
          },
          'self' => {
            'href' => api_v3_paths.work_package(work_package.id, timestamps: timestamp),
            'title' => work_package.subject
          }
        }
      }.to_json
    end

    it 'renders as expected' do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end

  context 'without the timestamp being in the attributes_by_timestamp collection' do
    let(:attributes_by_timestamp) do
      {}
    end

    let(:exists_at_timestamps) { [] }

    let(:matches_query_filters_at_timestamps) { { timestamp.to_s => false } }

    let(:expected_json) do
      {
        '_meta' => {
          'matchesFilters' => false,
          'exists' => false,
          'timestamp' => timestamp.to_s
        }
      }.to_json
    end

    it 'has only the meta noting that the wp did not exist' do
      expect(subject)
        .to be_json_eql(expected_json)
    end
  end
end

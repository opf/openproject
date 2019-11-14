#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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

require_relative '../shared_examples'

describe Bcf::API::V2_1::Topics::SingleRepresenter, 'rendering' do
  include API::V3::Utilities::PathHelper

  let(:work_package) { FactoryBot.build_stubbed(:stubbed_work_package, type: FactoryBot.build_stubbed(:type)) }
  let(:issue) { FactoryBot.build_stubbed(:bcf_issue, work_package: work_package) }

  let(:instance) { described_class.new(issue) }

  subject { instance.to_json }

  describe 'attributes' do
    context 'guid' do
      it_behaves_like 'attribute' do
        let(:value) { issue.uuid }
        let(:path) { 'guid' }
      end
    end

    context 'topic_type' do
      it_behaves_like 'attribute' do
        let(:value) { issue.type_text }
        let(:path) { 'topic_type' }
      end
    end

    context 'topic_status' do
      it_behaves_like 'attribute' do
        let(:value) { issue.status_text }
        let(:path) { 'topic_status' }
      end
    end

    context 'reference_links' do
      it_behaves_like 'attribute' do
        let(:value) { [api_v3_paths.work_package(work_package.id)] }
        let(:path) { 'reference_links' }
      end
    end

    context 'title' do
      it_behaves_like 'attribute' do
        let(:value) { issue.title }
        let(:path) { 'title' }
      end
    end

    context 'index' do
      it_behaves_like 'attribute' do
        let(:value) { issue.index_text }
        let(:path) { 'index' }
      end
    end

    context 'labels' do
      it_behaves_like 'attribute' do
        let(:value) { issue.labels }
        let(:path) { 'labels' }
      end
    end

    context 'creation_date' do
      it_behaves_like 'attribute' do
        let(:value) { issue.creation_date_text }
        let(:path) { 'creation_date' }
      end
    end

    context 'creation_author' do
      it_behaves_like 'attribute' do
        let(:value) { issue.creation_author_text }
        let(:path) { 'creation_author' }
      end
    end

    context 'modified_date' do
      it_behaves_like 'attribute' do
        let(:value) { issue.modified_date_text }
        let(:path) { 'modified_date' }
      end
    end

    context 'modified_author' do
      it_behaves_like 'attribute' do
        let(:value) { issue.modified_author_text }
        let(:path) { 'modified_author' }
      end
    end

    context 'description' do
      it_behaves_like 'attribute' do
        let(:value) { issue.description }
        let(:path) { 'description' }
      end
    end

    context 'due_date' do
      it_behaves_like 'attribute' do
        let(:value) { issue.due_date_text }
        let(:path) { 'due_date' }
      end
    end

    context 'assigned_to' do
      it_behaves_like 'attribute' do
        let(:value) { issue.assignee_text }
        let(:path) { 'assigned_to' }
      end
    end

    context 'stage' do
      it_behaves_like 'attribute' do
        let(:value) { issue.stage_text }
        let(:path) { 'stage' }
      end
    end
  end
end

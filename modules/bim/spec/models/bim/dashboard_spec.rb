# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'rails_helper'

RSpec.describe Bim::Dashboard, type: :model do
  subject(:dashboard) { build(:bim_dashboard) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Project') }
    it { is_expected.to belong_to(:user).class_name('User').optional }
    it { is_expected.to have_many(:widgets).class_name('Bim::DashboardWidget').dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:project_id) }

    describe 'only_one_default_per_project' do
      let(:project) { create(:project) }
      let!(:existing_default) { create(:bim_dashboard, project: project, is_default: true) }

      it 'prevents creating another default for same project' do
        new_dashboard = build(:bim_dashboard, project: project, is_default: true)

        expect(new_dashboard).not_to be_valid
        expect(new_dashboard.errors[:is_default]).to include('Only one default dashboard allowed per project')
      end

      it 'allows default for different project' do
        other_project = create(:project)
        new_dashboard = build(:bim_dashboard, project: other_project, is_default: true)

        expect(new_dashboard).to be_valid
      end

      it 'allows non-default for same project' do
        new_dashboard = build(:bim_dashboard, project: project, is_default: false)

        expect(new_dashboard).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let!(:dashboard1) { create(:bim_dashboard, project: project, user: user) }
    let!(:dashboard2) { create(:bim_dashboard, project: project) }
    let!(:other_dashboard) { create(:bim_dashboard) }

    describe '.for_project' do
      it 'returns dashboards for specified project' do
        expect(described_class.for_project(project)).to contain_exactly(dashboard1, dashboard2)
      end
    end

    describe '.for_user' do
      it 'returns dashboards for specified user' do
        expect(described_class.for_user(user)).to contain_exactly(dashboard1)
      end
    end

    describe '.default_dashboards' do
      let!(:default) { create(:bim_dashboard, project: project, is_default: true) }

      it 'returns only default dashboards' do
        expect(described_class.default_dashboards).to contain_exactly(default)
      end
    end

    describe '.public_dashboards' do
      let!(:public_dashboard) { create(:bim_dashboard, is_public: true) }

      it 'returns only public dashboards' do
        expect(described_class.public_dashboards).to include(public_dashboard)
      end
    end
  end

  describe '.default_for_project' do
    let(:project) { create(:project) }

    context 'when default dashboard exists' do
      let!(:existing_default) { create(:bim_dashboard, project: project, is_default: true) }

      it 'returns existing default dashboard' do
        expect(described_class.default_for_project(project)).to eq(existing_default)
      end
    end

    context 'when default dashboard does not exist' do
      it 'creates new default dashboard' do
        expect do
          described_class.default_for_project(project)
        end.to change(described_class, :count).by(1)
      end

      it 'sets up default dashboard correctly' do
        dashboard = described_class.default_for_project(project)

        expect(dashboard.name).to eq('Default BIM Dashboard')
        expect(dashboard.is_default).to be true
        expect(dashboard.is_public).to be true
      end
    end
  end

  describe '#render_widgets' do
    let(:dashboard) { create(:bim_dashboard) }
    let!(:widget1) { create(:bim_dashboard_widget, dashboard: dashboard, widget_type: :model_count) }
    let!(:widget2) { create(:bim_dashboard_widget, dashboard: dashboard, widget_type: :clash_summary) }

    it 'returns array of widget data' do
      result = dashboard.render_widgets

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first).to include(:id, :type, :title, :position, :size, :data)
    end

    it 'includes widget data' do
      result = dashboard.render_widgets

      expect(result.first[:data]).to be_a(Hash)
    end

    context 'with force_refresh' do
      it 'forces data refresh' do
        expect(widget1).to receive(:fetch_data).with(force_refresh: true)
        expect(widget2).to receive(:fetch_data).with(force_refresh: true)

        dashboard.render_widgets(force_refresh: true)
      end
    end
  end

  describe '#metrics_summary' do
    let(:dashboard) { create(:bim_dashboard) }

    before do
      create_list(:bim_dashboard_widget, 3, dashboard: dashboard)
    end

    it 'returns dashboard metrics' do
      summary = dashboard.metrics_summary

      expect(summary).to include(
        :total_widgets,
        :widget_types,
        :last_refresh,
        :has_stale_data
      )
    end

    it 'calculates total widgets correctly' do
      expect(dashboard.metrics_summary[:total_widgets]).to eq(3)
    end
  end

  describe '#refresh_all_widgets!' do
    let(:dashboard) { create(:bim_dashboard) }
    let!(:widget1) { create(:bim_dashboard_widget, dashboard: dashboard) }
    let!(:widget2) { create(:bim_dashboard_widget, dashboard: dashboard) }

    it 'refreshes all widgets' do
      expect(widget1).to receive(:refresh_cache!)
      expect(widget2).to receive(:refresh_cache!)

      dashboard.refresh_all_widgets!
    end
  end

  describe '#clone_for' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:dashboard) { create(:bim_dashboard, name: 'Original') }
    let!(:widget1) { create(:bim_dashboard_widget, dashboard: dashboard) }
    let!(:widget2) { create(:bim_dashboard_widget, dashboard: dashboard) }

    it 'creates a clone of the dashboard' do
      expect do
        dashboard.clone_for(user: user)
      end.to change(described_class, :count).by(1)
    end

    it 'clones all widgets' do
      cloned = dashboard.clone_for(user: user)
      expect(cloned.widgets.count).to eq(2)
    end

    it 'sets new user' do
      cloned = dashboard.clone_for(user: user)
      expect(cloned.user).to eq(user)
    end

    it 'sets new project if provided' do
      cloned = dashboard.clone_for(project: project)
      expect(cloned.project).to eq(project)
    end

    it 'marks clone as non-default' do
      cloned = dashboard.clone_for(user: user)
      expect(cloned.is_default).to be false
    end

    it 'appends (Copy) to name' do
      cloned = dashboard.clone_for(user: user)
      expect(cloned.name).to eq('Original (Copy)')
    end

    it 'clears cached widget data' do
      cloned = dashboard.clone_for(user: user)
      cloned.widgets.each do |widget|
        expect(widget.cached_data).to eq({})
        expect(widget.cached_at).to be_nil
      end
    end
  end

  describe '#export_config' do
    let(:dashboard) { create(:bim_dashboard, name: 'Test Dashboard') }
    let!(:widget) { create(:bim_dashboard_widget, dashboard: dashboard) }

    it 'exports dashboard configuration' do
      config = dashboard.export_config

      expect(config).to include(
        :name,
        :description,
        :layout_config,
        :settings,
        :widgets
      )
    end

    it 'includes widget configurations' do
      config = dashboard.export_config
      expect(config[:widgets]).to be_an(Array)
      expect(config[:widgets].size).to eq(1)
    end
  end

  describe '.import_config' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:config) do
      {
        'name' => 'Imported Dashboard',
        'description' => 'Test import',
        'layout_config' => { 'cols' => 12 },
        'settings' => { 'refresh' => 300 },
        'widgets' => [
          {
            'widget_type' => 'model_count',
            'title' => 'Models',
            'position' => { 'x' => 0, 'y' => 0 },
            'size' => { 'width' => 4, 'height' => 3 },
            'config' => {}
          }
        ]
      }
    end

    it 'creates dashboard from configuration' do
      expect do
        described_class.import_config(config, project: project, user: user)
      end.to change(described_class, :count).by(1)
    end

    it 'imports all widgets' do
      dashboard = described_class.import_config(config, project: project, user: user)
      expect(dashboard.widgets.count).to eq(1)
    end

    it 'sets dashboard properties correctly' do
      dashboard = described_class.import_config(config, project: project, user: user)

      expect(dashboard.name).to eq('Imported Dashboard')
      expect(dashboard.description).to eq('Test import')
      expect(dashboard.project).to eq(project)
      expect(dashboard.user).to eq(user)
    end
  end

  describe '#accessible_by?' do
    let(:user) { create(:user) }
    let(:owner) { create(:user) }
    let(:admin) { create(:user, :admin) }

    context 'when dashboard is public' do
      let(:dashboard) { create(:bim_dashboard, is_public: true, user: owner) }

      it 'is accessible by any user' do
        expect(dashboard.accessible_by?(user)).to be true
      end
    end

    context 'when dashboard is private' do
      let(:dashboard) { create(:bim_dashboard, is_public: false, user: owner) }

      it 'is accessible by owner' do
        expect(dashboard.accessible_by?(owner)).to be true
      end

      it 'is not accessible by other users' do
        expect(dashboard.accessible_by?(user)).to be false
      end

      it 'is accessible by admin' do
        expect(dashboard.accessible_by?(admin)).to be true
      end
    end
  end

  describe '#add_widget' do
    let(:dashboard) { create(:bim_dashboard) }

    it 'adds widget to dashboard' do
      expect do
        dashboard.add_widget(:model_count)
      end.to change { dashboard.widgets.count }.by(1)
    end

    it 'sets widget type' do
      widget = dashboard.add_widget(:model_count)
      expect(widget.widget_type).to eq('model_count')
    end

    it 'auto-positions widget if position not provided' do
      widget = dashboard.add_widget(:model_count)
      expect(widget.position).to be_a(Hash)
      expect(widget.position).to have_key('x')
      expect(widget.position).to have_key('y')
    end

    it 'uses provided position and size' do
      widget = dashboard.add_widget(
        :model_count,
        position: { x: 2, y: 3 },
        size: { width: 6, height: 4 }
      )

      expect(widget.position).to eq('x' => 2, 'y' => 3)
      expect(widget.size).to eq('width' => 6, 'height' => 4)
    end
  end
end

//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Chart, registerables } from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';
import PrimerColorsPlugin from 'core-app/shared/components/work-package-graphs/plugin.primer-colors';

// Chart.js keeps a single, page-wide plugin/controller registry: Chart.register()
// mutates global state, not something scoped to whichever component called it.
//
// Registering everything here instead, globally.
//
// This guarantees the registry is fully populated *before* Angular constructs
// any component and multiple charts on the same page do not compete for a conflicting
// set of plugins.
Chart.register(...registerables, ChartDataLabels, PrimerColorsPlugin);

// Require charts using the data labels plugin to opt-in instead of the default opt-out:
Chart.defaults.set('plugins.datalabels', { display: false });

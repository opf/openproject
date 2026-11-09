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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import tseslint from 'typescript-eslint';
import angular from 'angular-eslint';
import { defineConfig, globalIgnores } from 'eslint/config';

// Oxlint cannot parse Angular templates, so ESLint keeps only the
// template rules. The TypeScript plugins are registered without rules so
// existing `eslint-disable` comments for them still resolve.
export default defineConfig([
  {
    linterOptions: { reportUnusedDisableDirectives: 'off' },
  },
  {
    files: ['**/*.ts'],
    plugins: { '@typescript-eslint': tseslint.plugin, '@angular-eslint': angular.tsPlugin },
    languageOptions: { parser: tseslint.parser },
    processor: angular.processInlineTemplates,
  },
  {
    files: ['**/*.html'],
    extends: [
      ...angular.configs.templateRecommended,
      ...angular.configs.templateAccessibility,
    ],
    rules: {
      '@angular-eslint/template/click-events-have-key-events': ['error', { ignoreWithDirectives: ['uiSref'] }],
      '@angular-eslint/template/elements-content': ['error', { allowList: ['textContent'] }],
      '@angular-eslint/template/prefer-control-flow': 'error',
    },
  },
  globalIgnores([
    '.angular/',
    'coverage/',
    'src/locales/',
    '**/vendor',
    'src/app/features/plugins/linked/openproject-gitlab_integration/**',
  ]),
]);

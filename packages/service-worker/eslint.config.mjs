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

import { readFileSync } from 'node:fs';
import eslint from '@eslint/js';
import stylistic from '@stylistic/eslint-plugin';
import vitest from '@vitest/eslint-plugin';
import headers from 'eslint-plugin-headers';
import globals from 'globals';
import tseslint from 'typescript-eslint';
import { defineConfig, globalIgnores } from 'eslint/config';

const copyrightText = readFileSync(new URL('../../COPYRIGHT_short', import.meta.url), 'utf8').trimEnd();

const copyrightHeaderOptions = {
  source: 'string',
  content: `-- copyright\n${copyrightText.replace(/^(?=.)/gm, ' ')}\n++`,
  style: 'line',
  linePrefix: '',
  trailingNewlines: 2,
};

export default defineConfig([
  globalIgnores(['node_modules/']),
  {
    files: ['**/*.{js,mjs,cjs,ts}'],
    plugins: { headers },
    rules: {
      'headers/header-format': ['error', copyrightHeaderOptions],
    },
  },
  {
    files: ['**/*.{js,mjs,cjs}'],
    extends: [eslint.configs.recommended],
    languageOptions: { globals: { ...globals.node } },
  },
  {
    files: ['**/*.ts'],
    extends: [
      eslint.configs.recommended,
      ...tseslint.configs.recommendedTypeChecked,
      ...tseslint.configs.stylisticTypeChecked,
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.spec.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      globals: { ...globals.serviceworker },
    },
    rules: {
      'no-console': ['error', { allow: ['warn', 'error'] }],
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { varsIgnorePattern: '^_', argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-empty-function': 'off',
      '@typescript-eslint/no-unused-expressions': ['error', { allowShortCircuit: true }],
      'no-void': ['error', { allowAsStatement: true }],
      'no-use-before-define': 'off',
      '@typescript-eslint/no-use-before-define': ['error', { functions: false, classes: false }],
      '@typescript-eslint/no-namespace': 'off',
      '@typescript-eslint/space-infix-ops': 'off',
      'no-underscore-dangle': ['warn', { allowAfterThis: true, allowFunctionParams: true, enforceInMethodNames: true }],
      'no-return-assign': ['error', 'except-parens'],
      '@typescript-eslint/no-base-to-string': [
        'error',
        { ignoredTypeNames: ['URI', 'Error', 'RegExp', 'URL', 'URLSearchParams'] },
      ],
    },
  },
  {
    files: ['**/*.spec.ts'],
    ...vitest.configs.recommended,
    rules: {
      ...vitest.configs.recommended.rules,
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unsafe-argument': 'off',
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',
      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-return': 'off',
    },
  },
  {
    files: ['src/notification-plan.ts'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [{
          regex: '^(?!\\./constants$)',
          message: 'The notification plan must stay pure: import only ./constants.',
        }],
      }],
    },
  },
  {
    files: ['**/*.{js,mjs,cjs,ts}'],
    plugins: { '@stylistic': stylistic },
    rules: {
      '@stylistic/semi': ['error', 'always'],
      '@stylistic/quotes': ['error', 'single', { avoidEscape: true }],
      '@stylistic/lines-between-class-members': ['error', 'always', { exceptAfterSingleLine: true }],
      '@stylistic/type-annotation-spacing': [
        'error',
        { before: true, after: true, overrides: { colon: { before: false, after: false } } },
      ],
    },
  },
]);

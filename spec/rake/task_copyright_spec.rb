# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++

require "spec_helper"

RSpec.describe Rake::Task, :copyright do
  include_context "rake" do
    let(:task_path) { "lib/tasks/copyright" }
  end

  let(:copyright_text) do
    <<~COPYRIGHT.chomp
      OpenProject copyright.

      Released under the GPL.
    COPYRIGHT
  end

  let(:canonical_header) do
    <<~HEADER.chomp
      //-- copyright
      // OpenProject copyright.
      //
      // Released under the GPL.
      //++
    HEADER
  end

  around do |example|
    Dir.mktmpdir do |directory|
      Dir.chdir(directory) do
        File.write("COPYRIGHT_short", copyright_text)
        example.run
      end
    end
  end

  def write_source(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def expect_canonical_header(path, source)
    expect(File.read(path)).to eq("#{canonical_header}\n\n#{source}")
  end

  describe "copyright:update_typescript" do
    let(:task_name) { "copyright:update_typescript" }

    it "adds the canonical header to TypeScript and TSX files" do
      write_source("source.ts", "export const source = true;\n")
      write_source("component.tsx", "export const Component = () => null;\n")
      write_source(".redocly/plugins/rule.ts", "export const rule = true;\n")

      subject.invoke(".")

      expect_canonical_header("source.ts", "export const source = true;\n")
      expect_canonical_header("component.tsx", "export const Component = () => null;\n")
      expect_canonical_header(".redocly/plugins/rule.ts", "export const rule = true;\n")
    end

    it "normalizes spaced line and block headers" do
      write_source("spaced.ts", <<~TYPESCRIPT)
        // -- copyright
        // Old copyright.
        // ++

        export const spaced = true;
      TYPESCRIPT
      write_source("block.ts", <<~TYPESCRIPT)
        /*
         * -- copyright
         * Old copyright.
         * ++
         */

        export const block = true;
      TYPESCRIPT

      subject.invoke(".")

      expect_canonical_header("spaced.ts", "export const spaced = true;\n")
      expect_canonical_header("block.ts", "export const block = true;\n")
    end

    it "normalizes headers that lost their closing marker" do
      write_source("unclosed.ts", <<~TYPESCRIPT)
        // -- copyright
        // Old copyright.

        export const unclosed = true;
      TYPESCRIPT
      write_source("unclosed_block.ts", <<~TYPESCRIPT)
        /*
         * -- copyright
         * Old copyright.
         */

        export const unclosedBlock = true;
      TYPESCRIPT

      subject.invoke(".")

      expect_canonical_header("unclosed.ts", "export const unclosed = true;\n")
      expect_canonical_header("unclosed_block.ts", "export const unclosedBlock = true;\n")
    end

    it "normalizes headers that lost their opening marker" do
      write_source("unopened.ts", <<~TYPESCRIPT)
        // OpenProject is an open source project management software.
        // Old copyright.
        // ++

        export const unopened = true;
      TYPESCRIPT
      write_source("unopened_block.ts", <<~TYPESCRIPT)
        /*
         *  OpenProject is an open source project management software.
         *  Old copyright.
         */

        export const unopenedBlock = true;
      TYPESCRIPT

      subject.invoke(".")

      expect_canonical_header("unopened.ts", "export const unopened = true;\n")
      expect_canonical_header("unopened_block.ts", "export const unopenedBlock = true;\n")
    end

    it "keeps a directive comment that abuts the closing marker" do
      write_source("directive.ts", <<~TYPESCRIPT)
        //-- copyright
        // Old copyright.
        //++
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        export const directive:any = null;
      TYPESCRIPT

      subject.invoke(".")

      expect_canonical_header(
        "directive.ts",
        "// eslint-disable-next-line @typescript-eslint/no-explicit-any\nexport const directive:any = null;\n"
      )
    end

    it "keeps an unrelated leading block comment in a file that mentions the copyright text" do
      source = <<~TYPESCRIPT
        /* eslint-disable no-console */

        const notice = 'OpenProject is an open source project management software.';
      TYPESCRIPT
      write_source("unrelated.ts", source)

      subject.invoke(".")

      expect_canonical_header("unrelated.ts", source)
    end

    it "leaves an existing canonical header unchanged" do
      content = "#{canonical_header}\n\nexport const canonical = true;\n"
      write_source("canonical.ts", content)

      subject.invoke(".")

      expect(File.read("canonical.ts")).to eq(content)
    end

    it "only updates files below the provided path" do
      write_source("selected/source.ts", "export const selected = true;\n")
      write_source("outside.ts", "export const outside = true;\n")

      subject.invoke("selected")

      expect_canonical_header("selected/source.ts", "export const selected = true;\n")
      expect(File.read("outside.ts")).to eq("export const outside = true;\n")
    end

    it "preserves existing exclusions" do
      source = "export const excluded = true;\n"
      excluded_paths = [
        "modules/gitlab_integration/frontend/source.ts",
        "frontend/node_modules/.vite/vitest/deps/dependency.ts",
        "frontend/node_modules/package/source.ts",
        "frontend/src/vendor/ckeditor/source.ts",
        "tmp/source.ts"
      ]
      excluded_paths.each { |path| write_source(path, source) }

      subject.invoke(".")

      excluded_paths.each { |path| expect(File.read(path)).to eq(source) }
    end

    it "is idempotent" do
      write_source("source.ts", "export const source = true;\n")

      subject.invoke(".")
      first_result = File.read("source.ts")
      subject.reenable
      subject.invoke(".")

      expect(File.read("source.ts")).to eq(first_result)
    end
  end

  describe "copyright:update_js" do
    let(:task_name) { "copyright:update_js" }

    it "adds the canonical header to JavaScript module variants" do
      write_source("source.js", "export const source = true;\n")
      write_source("config.mjs", "export default {};\n")
      write_source("config.cjs", "module.exports = {};\n")
      write_source(".redocly/plugins/rule.js", "export const rule = true;\n")

      subject.invoke(".")

      expect_canonical_header("source.js", "export const source = true;\n")
      expect_canonical_header("config.mjs", "export default {};\n")
      expect_canonical_header("config.cjs", "module.exports = {};\n")
      expect_canonical_header(".redocly/plugins/rule.js", "export const rule = true;\n")
    end

    it "preserves existing exclusions" do
      source = "export const excluded = true;\n"
      excluded_paths = [
        "modules/gitlab_integration/frontend/source.js",
        "frontend/node_modules/.vite/vitest/deps/dependency.js",
        "frontend/src/vendor/ckeditor/ckeditor.js",
        "public/assets/frontend/chunk-SFO6FRYT.js",
        "frontend/out-tsc/app/frontend/src/app/shared/shared.module.js",
        "frontend/dist/main.js"
      ]
      excluded_paths.each { |path| write_source(path, source) }

      subject.invoke(".")

      excluded_paths.each { |path| expect(File.read(path)).to eq(source) }
    end
  end

  describe "copyright:update_sass" do
    let(:task_name) { "copyright:update_sass" }

    it "still reports on first-party sources below a vendor directory" do
      source = "body\n  color: red\n"
      write_source("frontend/src/global_styles/vendor/_index.sass", source)

      expect { subject.invoke(".") }
        .to output(/_index\.sass does not match regexp/).to_stdout
    end
  end
end

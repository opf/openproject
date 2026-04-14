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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "fileutils"
require "rspec"
require "stringio"
require "tmpdir"
require "yaml"

load File.expand_path("../../bin/copycop", __dir__)

# rspec excludes %r{bin/} by default, so include dir of this spec explicitly
RSpec.configure { it.backtrace_inclusion_patterns << %r{spec/bin/} }

RSpec.describe "bin/copycop", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  let(:configuration) do
    {
      "copyright" => "COPYRIGHT_short",
      "ignore" => ignore,
      "styles" => styles
    }
  end
  let(:ignore) { [".copycop.yml", "COPYRIGHT_short"] }
  let(:styles) do
    [
      { "comment" => "#", "include" => %w[**/*.rb] },
      { "comment" => "//", "alternative_comments" => [%w[/* */]], "include" => %w[**/*.ts] },
      { "comment" => %w[/* */], "alternative_comments" => ["//"], "include" => %w[**/*.js] },
      { "comment" => %w[<%# #%>], "alternative_comments" => [["<%#", "%>"]], "include" => %w[**/*.erb] }
    ]
  end

  let(:rb_header) do
    <<~CODE.chomp
      #-- copyright
      # An
      # example
      # copyright.
      #++
    CODE
  end
  let(:ts_header) do
    <<~CODE.chomp
      //-- copyright
      // An
      // example
      // copyright.
      //++
    CODE
  end
  let(:erb_header) do
    <<~ERB.chomp
      <%#-- copyright
      An
      example
      copyright.
      ++#%>
    ERB
  end

  let(:root) { Dir.mktmpdir("copycop") }

  before do
    File.write(File.join(root, "COPYRIGHT_short"), <<~TEXT)
      An
      example
      copyright.
    TEXT
    File.write(File.join(root, ".copycop.yml"), YAML.dump(configuration))
  end

  after { FileUtils.remove_entry(root) }

  def full_path(name) = File.join(root, name)

  def write(name, content)
    path = full_path(name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def read(name) = File.read(full_path(name))

  def capture_output
    original = [$stdout, $stderr]
    capture = StringIO.new, StringIO.new
    $stdout, $stderr = capture

    begin
      yield
    ensure
      $stdout, $stderr = original
    end

    capture.map(&:string)
  end

  def copycop(*args)
    code = 0

    out, err = capture_output do
      # testing CopyCop instead of bin/copycop is ~80 times faster (0.06 instead of 5s)
      code = Dir.chdir(root) { CopyCop.call(args) } ? 0 : 1
    rescue SystemExit => e
      code = e.status
    end

    [out, err, code]
  end

  def self.with_different_whitespace(where, &)
    {
      "no newline" => "",
      "newline" => "\n",
      "multiple newlines" => "\n\n\n",
      "extra whitespace" => "  \n  \n  \n"
    }.each do |description, whitespace|
      context "with #{description} #{where}" do
        instance_exec(whitespace, &)
      end
    end
  end

  shared_examples "is checked and fixed" do
    let(:check_matcher) { eq(["#{file_name}: #{offence}\n", "", 1]) }

    it "is checked and fixed" do
      write(file_name, original)

      expect(copycop).to check_matcher

      expect(read(file_name)).to eq(original)

      expect(copycop("-a")).to eq(["", "", 0])

      expect(read(file_name)).to eq(expected)
    end
  end

  context "when copyright header is up to date" do
    let(:file_name) { "foo.rb" }
    let(:expected) { <<~CODE }
      #!/usr/bin/env ruby

      #{rb_header}

      code
    CODE

    with_different_whitespace "before" do |whitespace_before|
      with_different_whitespace "after" do |whitespace_after|
        let(:original) { <<~CODE }
          #!/usr/bin/env ruby#{whitespace_before}
          #{rb_header}#{whitespace_after}
          code
        CODE

        include_examples "is checked and fixed" do
          if whitespace_before == "\n" && whitespace_after == "\n"
            let(:check_matcher) { eq(["", "", 0]) }
          else
            let(:check_matcher) { match([/\A#{Regexp.escape(file_name)}: .*copyright header.*\n\z/, "", 1]) }
          end
        end
      end
    end
  end

  context "when copyright header is missing" do
    let(:offence) { "missing copyright header" }

    context "with line comment style" do
      let(:file_name) { "bar.rb" }

      context "when there are no special comments" do
        let(:expected) { <<~CODE }
          #{rb_header}

          code
        CODE

        with_different_whitespace "at the top" do |whitespace|
          let(:original) { "#{whitespace}code\n" }

          include_examples "is checked and fixed"
        end
      end

      context "when there is no trailing newline" do
        let(:original) { "code" }
        let(:expected) { "#{rb_header}\n\ncode" }

        include_examples "is checked and fixed"
      end

      context "with a shebang" do
        let(:expected) { <<~CODE }
          #!/usr/bin/env ruby

          #{rb_header}

          code
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            #!/usr/bin/env ruby#{whitespace}
            code
          CODE

          include_examples "is checked and fixed"
        end
      end

      context "with a magic comment" do
        let(:expected) { <<~CODE }
          # frozen_string_literal: true

          #{rb_header}

          code
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            # frozen_string_literal: true#{whitespace}
            code
          CODE

          include_examples "is checked and fixed"
        end
      end

      [
        "# frozen_string_literal:true",
        "#frozen_string_literal: true",
        "# frozen_string_literal : true",
        "# FROZEN_STRING_LITERAL: true",
        "#encoding:KOI8-U"
      ].each do |magic_comment|
        context "with peculiar magic comment #{magic_comment}" do
          let(:original) { "#{magic_comment}\ncode\n" }
          let(:expected) { <<~CODE }
            #{magic_comment}

            #{rb_header}

            code
          CODE

          include_examples "is checked and fixed"
        end
      end

      [
        "# encoding_hint: KOI8-U",
        "# note: some long prose here",
        "# rubocop:disable Style/Foo",
        "# https://example.com/x"
      ].each do |non_magic_comment|
        context "with non magic comment #{non_magic_comment}" do
          let(:original) { "#{non_magic_comment}\ncode\n" }
          let(:expected) { <<~CODE }
            #{rb_header}

            #{non_magic_comment}
            code
          CODE

          include_examples "is checked and fixed"
        end
      end

      context "with multiple special comments" do
        let(:expected) { <<~CODE }
          #!/usr/bin/env ruby
          # frozen_string_literal: true
          # encoding: KOI8-U
          # Some documentation attached

          #{rb_header}

          code
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            #!/usr/bin/env ruby
            # frozen_string_literal: true
            # encoding: KOI8-U
            # Some documentation attached#{whitespace}
            code
          CODE

          include_examples "is checked and fixed"
        end
      end

      context "with documentation comments" do
        let(:expected) { <<~CODE }
          #{rb_header}

          # TODO: translate
          # Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          # eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
          # ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
          # aliquip ex ea commodo consequat.
          code
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            #{whitespace}# TODO: translate
            # Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
            # eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
            # ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
            # aliquip ex ea commodo consequat.
            code
          CODE

          include_examples "is checked and fixed"
        end
      end

      context "with special and documentation comments separately" do
        let(:expected) { <<~CODE }
          #!/usr/bin/env ruby
          # frozen_string_literal: true
          # encoding: KOI8-U
          # something else

          #{rb_header}

          # Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          # eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
          # ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
          # aliquip ex ea commodo consequat.
          code
        CODE

        with_different_whitespace "between" do |whitespace|
          next unless whitespace["\n"] # at least one newline needed

          let(:original) { <<~CODE }
            #!/usr/bin/env ruby
            # frozen_string_literal: true
            # encoding: KOI8-U
            # something else#{whitespace}
            # Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
            # eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
            # ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
            # aliquip ex ea commodo consequat.
            code
          CODE

          include_examples "is checked and fixed"
        end
      end
    end

    context "with block comment style" do
      let(:file_name) { "foo.html.erb" }
      let(:expected) { <<~CODE }
        #{erb_header}

        <div></div>
      CODE

      with_different_whitespace "at the top" do |whitespace|
        let(:original) { "#{whitespace}<div></div>\n" }

        include_examples "is checked and fixed"
      end
    end
  end

  context "when copyright is incorrect" do
    let(:file_name) { "foo.rb" }
    let(:offence) { "malformed copyright header" }
    let(:expected) { <<~CODE }
      #{rb_header}

      code
    CODE

    context "when just different" do
      let(:original) { <<~CODE }
        #-- copyright
        # Stale copyright
        #++

        code
      CODE

      include_examples "is checked and fixed"
    end

    context "when marker has extra space" do
      let(:original) { <<~CODE }
        # -- copyright
        # Example copyright
        # ++

        code
      CODE

      include_examples "is checked and fixed"
    end

    context "when something goes after trailing marker" do
      let(:original) { <<~CODE }
        #{rb_header} hello, world!

        code
      CODE

      include_examples "is checked and fixed"
    end

    context "when closing marker is missing", pending: "TODO" do
      let(:original) { <<~CODE }
        #-- copyright
        # An
        # example
        # copyright.

        code
      CODE

      include_examples "is checked and fixed"
    end

    context "when opening marker is missing", pending: "TODO" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        #++

        code
      CODE

      include_examples "is checked and fixed"
    end

    context "when both markers are missing", pending: "TODO" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        # This can't be determined to not be part of copyright

        code
      CODE

      include_examples "is checked and fixed"
    end

    context "when there is a comment right after" do
      let(:original) { <<~CODE }
        #{rb_header}
        # Dangling comment
        code
      CODE

      let(:offence) { "no empty line after copyright header" }

      let(:expected) { <<~CODE }
        #{rb_header}

        # Dangling comment
        code
      CODE

      include_examples "is checked and fixed"
    end

    context "when there is whitespace before it", pending: "TODO" do
      let(:original) { <<~CODE }


        #{rb_header}

        code
      CODE

      let(:offence) { "extra whitespace before copyright header" }

      include_examples "is checked and fixed"
    end

    context "when there is code before it" do
      let(:original) { <<~CODE }
        # frozen_string_literal: true

        require "x"
        #{rb_header}

        code
      CODE

      it "is reported, but not touched", pending: "TODO" do
        write(file_name, original)

        expect(copycop).to eq(["#{file_name}: copyright header is not at the top of the file\n", "", 1])

        expect(read(file_name)).to eq(original)

        expect(copycop("-a")).to eq(["", "#{file_name}: copyright header is not at the top of the file\n", 1])

        expect(read(file_name)).to eq(original)
      end
    end

    context "with alternative comment style" do
      context "when line style is expected", pending: "TODO" do
        let(:file_name) { "foo.ts" }

        let(:original) { <<~CODE }
          /*-- copyright
          An
          example
          copyright.
          ++*/

          code
        CODE

        let(:expected) { <<~CODE }
          #{ts_header}

          code
        CODE

        include_examples "is checked and fixed"
      end

      context "when block style is expected", pending: "TODO" do
        let(:file_name) { "foo.js" }

        let(:original) { <<~CODE }
          #{ts_header}

          code
        CODE

        let(:expected) { <<~CODE }
          /*-- copyright
          An
          example
          copyright.
          ++*/

          code
        CODE

        include_examples "is checked and fixed"
      end

      context "when different block style is expected", pending: "TODO" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#-- copyright
          An
          example
          copyright.
          ++%>

          <div></div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_header}

          <div></div>
        CODE

        include_examples "is checked and fixed"
      end

      context "when a later block uses the expected style",
              pending: "decide if handling this case is worth it instead of switching erb to <%# %>" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#-- copyright
          An
          example
          copyright.
          ++%>

          <%# a note #%>
          <div></div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_header}

          <%# a note #%>
          <div></div>
        CODE

        include_examples "is checked and fixed"
      end
    end

    context "with unterminated block comment" do
      let(:file_name) { "foo.html.erb" }
      let(:original) { <<~CODE }
        <%#-- copyright
        An
        example
        copyright.

        <div></div>
      CODE

      let(:offence) { "missing copyright header" }

      let(:expected) { <<~CODE }
        #{erb_header}

        <%#-- copyright
        An
        example
        copyright.

        <div></div>
      CODE

      include_examples "is checked and fixed"
    end
  end

  describe "CLI" do
    let(:original) { "code\n" }
    let(:expected) { <<~CODE }
      #{rb_header}

      code
    CODE

    it "skips files without matching style" do
      write("text.md", "some text\n")

      expect(copycop).to eq(["", "", 0])

      expect(read("text.md")).to eq("some text\n")

      expect(copycop("-a")).to eq(["", "", 0])

      expect(read("text.md")).to eq("some text\n")
    end

    context "with overlapping style patterns" do
      let(:styles) { super() + [{ "comment" => "//", "include" => %w[**/*] }] }

      it "takes the first matching style" do
        write("foo.rb", original)

        expect(copycop("-a")).to eq(["", "", 0])

        expect(read("foo.rb")).to eq(expected)
      end
    end

    it "skips empty files" do
      write("foo.rb", "")

      expect(copycop).to eq(["", "", 0])

      expect(read("foo.rb")).to eq("")

      expect(copycop("-a")).to eq(["", "", 0])

      expect(read("foo.rb")).to eq("")
    end

    it "accepts a single file" do
      %w[
        foo.rb
        bar.rb
        baz.rb
      ].each { write(it, original) }

      expect(copycop("bar.rb")).to eq(["bar.rb: missing copyright header\n", "", 1])

      %w[
        foo.rb
        bar.rb
        baz.rb
      ].each { expect(read(it)).to eq(original) }

      expect(copycop("-a", "bar.rb")).to eq(["", "", 0])

      %w[
        foo.rb
        baz.rb
      ].each { expect(read(it)).to eq(original) }
      expect(read("bar.rb")).to eq(expected)
    end

    it "accepts a single dir" do
      %w[
        foo.rb
        lib/bar.rb
        lib/sub/bar.rb
        lib_exec/baz.rb
      ].each { write(it, original) }

      expect(copycop("lib")).to eq([<<~OUTPUT, "", 1])
        lib/bar.rb: missing copyright header
        lib/sub/bar.rb: missing copyright header
      OUTPUT

      %w[
        foo.rb
        lib/bar.rb
        lib/sub/bar.rb
        lib_exec/baz.rb
      ].each { expect(read(it)).to eq(original) }

      expect(copycop("-a", "lib")).to eq(["", "", 0])

      %w[
        foo.rb
        lib_exec/baz.rb
      ].each { expect(read(it)).to eq(original) }
      %w[
        lib/bar.rb
        lib/sub/bar.rb
      ].each { expect(read(it)).to eq(expected) }
    end

    it "aborts on path that doesn't exist" do
      write("foo.rb", original)
      write("baz.rb", original)

      expect(copycop("foo.rb", "bar.rb", "baz.rb"))
        .to eq(["foo.rb: missing copyright header\n", "No such file or directory bar.rb\n", 1])

      expect(read("foo.rb")).to eq(original)
      expect(File.exist?(full_path("bar.rb"))).to be false
      expect(read("baz.rb")).to eq(original)

      expect(copycop("-a", "foo.rb", "bar.rb", "baz.rb")).to eq(["", "No such file or directory bar.rb\n", 1])

      expect(read("foo.rb")).to eq(expected)
      expect(File.exist?(full_path("bar.rb"))).to be false
      expect(read("baz.rb")).to eq(original)
    end

    it "aborts on unknown option" do
      write("foo.rb", original)

      expect(copycop("-x")).to match(["", /\Ainvalid option: -x\n.*Usage:/m, 1])

      expect(read("foo.rb")).to eq(original)
    end

    context "with ignore pattern" do
      let(:ignore) { super() + %w[ignore/**/*] }

      it "skips ignored paths" do
        write("ignore/foo.rb", original)
        write("bar.rb", original)

        expect(copycop).to eq(["bar.rb: missing copyright header\n", "", 1])

        expect(read("ignore/foo.rb")).to eq(original)
        expect(read("bar.rb")).to eq(original)

        expect(copycop("-a")).to eq(["", "", 0])

        expect(read("ignore/foo.rb")).to eq(original)
        expect(read("bar.rb")).to eq(expected)
      end

      it "warns on on explicitly listed ignored file" do
        write("ignore/foo.rb", original)

        expect(copycop("ignore/foo.rb")).to eq(["", "Ignored ignore/foo.rb\n", 0])

        expect(read("ignore/foo.rb")).to eq(original)

        expect(copycop("-a", "ignore/foo.rb")).to eq(["", "Ignored ignore/foo.rb\n", 0])

        expect(read("ignore/foo.rb")).to eq(original)
      end
    end
  end
end

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

require "bundler"
require "fileutils"
require "open3"
require "rspec"
require "stringio"
require "tmpdir"
require "yaml"

require "support/focused_spec_circuit_breaker"

load File.expand_path("../../bin/copycop", __dir__)

# rspec excludes %r{bin/} by default, so allow copycop and this spec explicitly
RSpec.configure { it.backtrace_inclusion_patterns << %r{bin/copycop} }

RSpec.describe "bin/copycop", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  let(:configuration) do
    {
      "copyright" => "COPYRIGHT_short",
      "alternative_copyrights" => %w[COPYRIGHT_short_legacy],
      "ignore" => ignore,
      "styles" => styles
    }
  end
  let(:ignore) { [".copycop.yml"] }
  let(:styles) do
    [
      { "comment" => "#", "include" => %w[**/*.rb] },
      { "comment" => "//", "alternative_comments" => [%w[/* */]], "include" => %w[**/*.ts] },
      { "comment" => %w[/* */], "alternative_comments" => ["//"], "include" => %w[**/*.js] },
      { "comment" => %w[<%# #%>], "alternative_comments" => [["<%#", "%>"]], "include" => %w[**/*.erb] }
    ]
  end

  let(:copyright_text) { <<~TEXT }
    An
    example
    copyright.
  TEXT

  let(:rb_copyright_header) { <<~CODE.chomp }
    #-- copyright
    # An
    # example
    # copyright.
    #++
  CODE

  let(:ts_copyright_header) { <<~CODE.chomp }
    //-- copyright
    // An
    // example
    // copyright.
    //++
  CODE

  let(:erb_copyright_header) { <<~CODE.chomp }
    <%#-- copyright
    An
    example
    copyright.
    ++#%>
  CODE

  let(:root) { Dir.mktmpdir("copycop") }

  before do
    write("COPYRIGHT_short", copyright_text)
    write(".copycop.yml", YAML.dump(configuration))
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

  def copycop(*args, remove_summary: true)
    status = 0

    out, err = capture_output do
      # testing CopyCop instead of bin/copycop is ~80 times faster (0.06 instead of 5s)
      status = Dir.chdir(root) { CopyCop.call(args + %w[-v]) } ? 0 : 1
    rescue SystemExit => e
      status = e.status
    end

    out.sub!(/^\d+ files? inspected, .*\n\z/, "") if remove_summary

    {
      out:,
      err:,
      status:
    }
  end

  def self.with_different_whitespace(where, &)
    {
      "no blank line" => "",
      "one blank line" => "\n",
      "multiple blank lines" => "\n\n\n",
      "extra whitespace" => "\n  \n  \n"
    }.each do |description, whitespace|
      context "with #{description} #{where}" do
        instance_exec(whitespace, &)
      end
    end
  end

  shared_examples "is already valid" do
    it "is already valid" do
      write(file_name, original)

      expect(copycop).to eq(out: "", err: "", status: 0)

      expect(read(file_name)).to eq(original)

      expect(copycop("-a")).to eq(out: "", err: "", status: 0)

      expect(read(file_name)).to eq(original)
    end
  end

  shared_examples "is reported and fixed" do
    it "is reported and fixed" do
      write(file_name, original)

      expect(copycop).to eq(out: "#{file_name}:#{line}: #{offense}\n", err: "", status: 1)

      expect(read(file_name)).to eq(original)

      expect(copycop("-a")).to eq(out: "Corrected #{file_name}\n", err: "", status: 0)

      expect(read(file_name)).to eq(expected)

      expect(copycop).to eq(out: "", err: "", status: 0)
    end
  end

  shared_examples "is reported and fixed only unsafely" do
    it "is reported and fixed only unsafely" do
      write(file_name, original)

      expect(copycop).to eq(out: "#{file_name}:#{line}: #{offense}\n", err: "", status: 1)

      expect(copycop("-a")).to eq(out: "#{file_name}:#{line}: #{offense}\n", err: "", status: 1)

      expect(read(file_name)).to eq(original)

      expect(copycop("-A")).to eq(out: "Corrected #{file_name}\n", err: "", status: 0)

      expect(read(file_name)).to eq(expected)

      expect(copycop).to eq(out: "", err: "", status: 0)
    end
  end

  shared_examples "is reported, but not touched" do
    it "is reported, but not touched" do
      write(file_name, original)

      expect(copycop).to eq(out: "#{file_name}:#{line}: #{offense}\n", err: "", status: 1)

      expect(read(file_name)).to eq(original)

      expect(copycop("-a")).to eq(out: "#{file_name}:#{line}: #{offense}\n", err: "", status: 1)

      expect(read(file_name)).to eq(original)
    end
  end

  context "when copyright header is up to date" do
    let(:file_name) { "foo.rb" }
    let(:expected) { <<~CODE }
      #!/usr/bin/env ruby

      #{rb_copyright_header}

      puts 'hello, world'
    CODE

    with_different_whitespace "before" do |whitespace_before|
      let(:line) { 2 + whitespace_before.count("\n") }

      with_different_whitespace "after" do |whitespace_after|
        let(:original) { <<~CODE }
          #!/usr/bin/env ruby#{whitespace_before}
          #{rb_copyright_header}#{whitespace_after}
          puts 'hello, world'
        CODE

        if whitespace_before == "\n" && whitespace_after == "\n"
          include_examples "is already valid"
        else
          let(:offense) do
            {
              before: whitespace_before,
              after: whitespace_after
            }.filter_map do |position, whitespace|
              case whitespace
              when "\n"
                nil
              when ""
                "no empty line #{position} copyright header"
              else
                "extra whitespace #{position} copyright header"
              end
            end.join(", ")
          end

          include_examples "is reported and fixed"
        end
      end
    end

    context "when code contains another copyright header" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}

        example = <<~RUBY
          #-- copyright
          # part of code
          #++
        RUBY
      CODE

      include_examples "is already valid"
    end
  end

  context "when copyright header is missing" do
    let(:offense) { "missing copyright header" }
    let(:line) { 1 }

    context "with line comment style" do
      let(:file_name) { "bar.rb" }

      context "when there are no special comments" do
        let(:expected) { <<~CODE }
          #{rb_copyright_header}

          puts 'hello, world'
        CODE

        with_different_whitespace "at the top" do |whitespace|
          let(:original) { "#{whitespace}puts 'hello, world'\n" }
          let(:line) { 1 + whitespace.count("\n") }

          include_examples "is reported and fixed"
        end
      end

      context "when copyright text has a blank line" do
        let(:copyright_text) { <<~TEXT }
          An

          example

          copyright.
        TEXT

        let(:original) { "puts 'hello, world'\n" }
        let(:expected) { <<~CODE }
          #-- copyright
          # An
          #
          # example
          #
          # copyright.
          #++

          puts 'hello, world'
        CODE

        include_examples "is reported and fixed"
      end

      context "when there is no trailing newline" do
        let(:original) { "puts 'hello, world'" }
        let(:expected) { "#{rb_copyright_header}\n\nputs 'hello, world'" }

        include_examples "is reported and fixed"
      end

      context "with a shebang" do
        let(:expected) { <<~CODE }
          #!/some/path/to/bin/foo bar baz

          #{rb_copyright_header}

          puts 'hello, world'
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            #!/some/path/to/bin/foo bar baz#{whitespace}
            puts 'hello, world'
          CODE

          let(:line) { 2 + whitespace.count("\n") }

          include_examples "is reported and fixed"
        end
      end

      context "with a shebang and no code" do
        let(:original) { "#!/usr/bin/env not-ruby\n" }
        let(:line) { 2 }
        let(:expected) { <<~CODE }
          #!/usr/bin/env not-ruby

          #{rb_copyright_header}
        CODE

        include_examples "is reported and fixed"
      end

      context "with empty comments" do
        context "when followed by code" do
          let(:original) { <<~CODE }
            #

            #
            #

            puts 'hello, world'
          CODE

          let(:expected) { <<~CODE }
            #{rb_copyright_header}

            puts 'hello, world'
          CODE

          include_examples "is reported and fixed"
        end

        context "when preceded by magic comments" do
          let(:original) { <<~CODE }
            # frozen_string_literal: true

            #

            puts 'hello, world'
          CODE

          let(:line) { 3 }
          let(:expected) { <<~CODE }
            # frozen_string_literal: true

            #{rb_copyright_header}

            puts 'hello, world'
          CODE

          include_examples "is reported and fixed"
        end

        context "without code" do
          let(:original) { "#\n" }
          let(:expected) { "#{rb_copyright_header}\n" }

          include_examples "is reported and fixed"
        end
      end

      context "with magic comments in separate blocks" do
        let(:expected) { <<~CODE }
          # frozen_string_literal: true

          # encoding: KOI8-U

          #{rb_copyright_header}

          puts 'hello, world'
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            # frozen_string_literal: true

            # encoding: KOI8-U#{whitespace}
            puts 'hello, world'
          CODE

          let(:line) { 4 + whitespace.count("\n") }

          include_examples "is reported and fixed"
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
          let(:original) { "#{magic_comment}\nputs 'hello, world'\n" }
          let(:line) { 2 }
          let(:expected) { <<~CODE }
            #{magic_comment}

            #{rb_copyright_header}

            puts 'hello, world'
          CODE

          include_examples "is reported and fixed"
        end
      end

      # ensure using bytesize and not length when changing position in StringScanner
      context "with a multibyte comment" do
        let(:original) { <<~CODE }
          # ḟöö ḃäř ḃäž

          puts 'hello, world'
        CODE

        let(:expected) { <<~CODE }
          #{rb_copyright_header}

          # ḟöö ḃäř ḃäž

          puts 'hello, world'
        CODE

        include_examples "is reported and fixed"
      end

      [
        "# encoding_hint: KOI8-U",
        "# note: some long prose here",
        "# rubocop:disable Style/Foo",
        "# https://example.com/x"
      ].each do |non_magic_comment|
        context "with non magic comment #{non_magic_comment}" do
          let(:original) { "#{non_magic_comment}\nputs 'hello, world'\n" }
          let(:expected) { <<~CODE }
            #{rb_copyright_header}

            #{non_magic_comment}
            puts 'hello, world'
          CODE

          include_examples "is reported and fixed"
        end
      end

      context "with multiple special comments" do
        let(:expected) { <<~CODE }
          #!/usr/bin/env ruby
          # frozen_string_literal: true
          # encoding: KOI8-U
          # Some documentation attached

          #{rb_copyright_header}

          puts 'hello, world'
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            #!/usr/bin/env ruby
            # frozen_string_literal: true
            # encoding: KOI8-U
            # Some documentation attached#{whitespace}
            puts 'hello, world'
          CODE

          let(:line) { 5 + whitespace.count("\n") }

          include_examples "is reported and fixed"
        end
      end

      context "with documentation comments" do
        let(:expected) { <<~CODE }
          #{rb_copyright_header}

          # TODO: translate
          # Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          # eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
          # ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
          # aliquip ex ea commodo consequat.
          puts 'hello, world'
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            #{whitespace}# TODO: translate
            # Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
            # eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
            # ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
            # aliquip ex ea commodo consequat.
            puts 'hello, world'
          CODE

          let(:line) { 1 + whitespace.count("\n") }

          include_examples "is reported and fixed"
        end
      end

      context "with an unmarked copyright comment below code" do
        let(:original) { <<~CODE }
          require "x"

          # Copyright by someone

          puts 'hello, world'
        CODE

        let(:expected) { <<~CODE }
          #{rb_copyright_header}

          require "x"

          # Copyright by someone

          puts 'hello, world'
        CODE

        include_examples "is reported and fixed"
      end

      context "with special and documentation comments separately" do
        let(:expected) { <<~CODE }
          #!/usr/bin/env ruby
          # frozen_string_literal: true
          # encoding: KOI8-U
          # something else

          #{rb_copyright_header}

          # Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          # eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
          # ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
          # aliquip ex ea commodo consequat.
          puts 'hello, world'
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
            puts 'hello, world'
          CODE

          let(:line) { 5 + whitespace.count("\n") }

          include_examples "is reported and fixed"
        end
      end
    end

    context "with block comment style" do
      let(:file_name) { "foo.html.erb" }
      let(:expected) { <<~CODE }
        #{erb_copyright_header}

        <div>hello, world</div>
      CODE

      with_different_whitespace "at the top" do |whitespace|
        let(:original) { "#{whitespace}<div>hello, world</div>\n" }
        let(:line) { 1 + whitespace.count("\n") }

        include_examples "is reported and fixed"
      end
    end

    context "with a shebang that is not a comment" do
      let(:file_name) { "foo.ts" }
      let(:original) { <<~CODE }
        #!/usr/bin/env node
        console.log('hello, world')
      CODE

      let(:line) { 2 }
      let(:expected) { <<~CODE }
        #!/usr/bin/env node

        #{ts_copyright_header}

        console.log('hello, world')
      CODE

      include_examples "is reported and fixed"
    end
  end

  context "when copyright is incorrect" do
    let(:file_name) { "foo.rb" }
    let(:offense) { "malformed copyright header" }
    let(:line) { 1 }
    let(:expected) { <<~CODE }
      #{rb_copyright_header}

      puts 'hello, world'
    CODE

    context "when just different" do
      let(:original) { <<~CODE }
        #-- copyright
        # Stale copyright
        #++

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when has blank commented lines" do
      let(:original) { <<~CODE }
        #-- copyright
        # An
        #
        # example
        #
        # copyright.
        #++

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when has blank lines" do
      let(:original) { <<~CODE }
        #-- copyright
        # An

        # example

        # copyright.
        #++

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when marker has extra space" do
      let(:original) { <<~CODE }
        # -- copyright
        # Example copyright
        # ++

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when something goes after end marker" do
      let(:original) { <<~CODE }
        #{rb_copyright_header} foo bar baz

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when something goes before start marker" do
      let(:original) { <<~CODE }
        # newline before copyright header removed by accident #{rb_copyright_header}

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no start marker" }

      include_examples "is reported and fixed only unsafely"
    end

    context "when end marker is missing" do
      let(:original) { <<~CODE }
        #-- copyright
        # An
        # example
        # copyright.

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no end marker" }

      include_examples "is reported and fixed only unsafely"
    end

    context "when end marker is missing and a comment follows" do
      let(:original) { <<~CODE }
        #-- copyright
        # An

        # unrelated note
        puts 'hello, world'
      CODE

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # unrelated note
        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no end marker" }

      include_examples "is reported and fixed only unsafely"
    end

    context "when end marker is missing and empty comments precede" do
      let(:original) { <<~CODE }
        #
        #
        #-- copyright
        # An
        # example
        # copyright.

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no end marker" }

      include_examples "is reported and fixed only unsafely"
    end

    context "when end marker is missing and empty and non empty comments precede" do
      let(:original) { <<~CODE }
        # foo
        #
        #
        #-- copyright
        # An
        # example
        # copyright.

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no end marker, no empty line before copyright header" }
      let(:line) { 2 }
      let(:expected) { <<~CODE }
        # foo

        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed only unsafely"
    end

    context "when start marker is missing" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        #++

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no start marker" }

      include_examples "is reported and fixed only unsafely"
    end

    context "when start marker is missing and empty comments follow" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        #++
        #
        #

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no start marker" }

      include_examples "is reported and fixed only unsafely"
    end

    context "when start marker is missing and empty and non empty comments follow" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        #++
        #
        #
        # bar

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no start marker, no empty line after copyright header" }

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # bar

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed only unsafely"
    end

    context "when both markers are missing" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        # This can't be determined to not be part of copyright

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no markers" }

      include_examples "is reported and fixed only unsafely"
    end

    {
      "a shebang" => "#!/usr/bin/env ruby",
      "a magic comment" => "# frozen_string_literal: true",
      "a shebang and a magic comment" => "#!/usr/bin/env ruby\n# frozen_string_literal: true"
    }.each do |description, special_comment|
      context "when the chunk starts with #{description}" do
        let(:line) { 2 + special_comment.count("\n") }
        let(:expected) { <<~CODE }
          #{special_comment}

          #{rb_copyright_header}

          puts 'hello, world'
        CODE

        context "and start marker is missing" do
          let(:original) { <<~CODE }
            #{special_comment}
            # An
            # example
            # copyright.
            #++

            puts 'hello, world'
          CODE

          let(:offense) { "copyright header has no start marker, no empty line before copyright header" }

          include_examples "is reported and fixed only unsafely"
        end

        context "and both markers are missing" do
          let(:original) { <<~CODE }
            #{special_comment}
            # An
            # example
            # copyright.
            # This can't be determined to not be part of copyright

            puts 'hello, world'
          CODE

          let(:offense) { "copyright header has no markers, no empty line before copyright header" }

          include_examples "is reported and fixed only unsafely"
        end
      end
    end

    context "when a comment precedes the start marker in the same chunk" do
      let(:original) { <<~CODE }
        # some note
        #-- copyright
        # An

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no end marker, no empty line before copyright header" }
      let(:line) { 2 }
      let(:expected) { <<~CODE }
        # some note

        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed only unsafely"
    end

    context "when a comment follows the end marker in the same chunk" do
      let(:original) { <<~CODE }
        # An
        #++
        # dangling

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header has no start marker, no empty line after copyright header" }

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # dangling

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed only unsafely"
    end

    context "when there is no trailing newline after the end marker" do
      let(:original) { rb_copyright_header }
      let(:expected) { "#{rb_copyright_header}\n" }

      let(:offense) { "no empty line after copyright header" }

      include_examples "is reported and fixed"
    end

    context "when there is a comment right after" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}
        # Dangling comment
        puts 'hello, world'
      CODE

      let(:offense) { "no empty line after copyright header" }

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # Dangling comment
        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there are empty comments right before" do
      let(:original) { <<~CODE }
        #
        #
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there are empty and non empty comments right before" do
      let(:original) { <<~CODE }
        # foo
        #
        #
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      let(:offense) { "malformed copyright header, no empty line before copyright header" }
      let(:line) { 2 }
      let(:expected) { <<~CODE }
        # foo

        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there are empty comments right after" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}
        #
        #

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there are empty comments after a blank line" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}

        #

        #
        #

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there are empty and non empty comments after a blank line" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}

        #
        # bar

        puts 'hello, world'
      CODE

      include_examples "is already valid"
    end

    context "when there are empty comments before a blank line" do
      let(:original) { <<~CODE }
        #

        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is already valid"
    end

    context "when there are empty and non empty comments right after" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}
        #
        #
        # bar

        puts 'hello, world'
      CODE

      let(:offense) { "malformed copyright header, no empty line after copyright header" }

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # bar

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there are empty comments on both sides" do
      let(:original) { <<~CODE }
        #
        #
        #{rb_copyright_header}
        #
        #

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there are empty and non empty comments on both sides" do
      let(:original) { <<~CODE }
        # foo
        #
        #
        #{rb_copyright_header}
        #
        #
        # bar

        puts 'hello, world'
      CODE

      let(:offense) { "malformed copyright header, no empty line before copyright header, no empty line after copyright header" }
      let(:line) { 2 }
      let(:expected) { <<~CODE }
        # foo

        #{rb_copyright_header}

        # bar

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when there is whitespace before it" do
      let(:original) { <<~CODE }


        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      let(:offense) { "extra whitespace before copyright header" }
      let(:line) { 3 }

      include_examples "is reported and fixed"
    end

    context "when there is code before it" do
      let(:original) { <<~CODE }
        # frozen_string_literal: true

        require "x"
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      let(:offense) { "copyright header is not at the top of the file" }
      let(:line) { 4 }

      include_examples "is reported, but not touched"
    end

    context "with something around block markers" do
      let(:file_name) { "foo.html.erb" }
      let(:expected) { <<~CODE }
        #{erb_copyright_header}

        <div>hello, world</div>
      CODE

      context "when something goes after start marker" do
        let(:original) { <<~CODE }
          <%#-- copyright unexpected
          An
          example
          copyright.
          ++#%>

          <div>hello, world</div>
        CODE

        include_examples "is reported and fixed"
      end

      context "when something goes before end marker" do
        let(:original) { <<~CODE }
          <%#-- copyright
          An
          example
          copyright.
          unexpected ++#%>

          <div>hello, world</div>
        CODE

        include_examples "is reported and fixed"
      end

      {
        text: "unexpected",
        tag: "<b>unexpected</b>",
        comment: "<%# unexpected %>"
      }.each do |description, unexpected|
        context "when #{description} goes after end marker" do
          let(:original) { <<~CODE }
            #{erb_copyright_header}#{unexpected}

            <div>hello, world</div>
          CODE

          let(:offense) { "no empty line after copyright header" }

          let(:expected) { <<~CODE }
            #{erb_copyright_header}

            #{unexpected}

            <div>hello, world</div>
          CODE

          include_examples "is reported and fixed"
        end
      end

      ["unexpected", "<b>unexpected</b>"].each do |unexpected|
        context "when #{unexpected} goes before start marker" do
          let(:original) { <<~CODE }
            #{unexpected}#{erb_copyright_header}

            <div>hello, world</div>
          CODE

          let(:offense) { "copyright header is not at the top of the file" }

          include_examples "is reported, but not touched"
        end
      end

      context "when a comment goes before start marker" do
        let(:offense) { "no empty line before copyright header" }

        let(:original) { <<~CODE }
          <%# comment %>#{erb_copyright_header}

          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          <%# comment %>

          #{erb_copyright_header}

          <div>hello, world</div>
        CODE

        include_examples "is reported and fixed"
      end
    end

    context "with alternative comment style" do
      context "when line style is expected" do
        let(:file_name) { "foo.ts" }

        let(:original) { <<~CODE }
          /*-- copyright
          An
          example
          copyright.
          ++*/

          console.log('hello, world')
        CODE

        let(:expected) { <<~CODE }
          #{ts_copyright_header}

          console.log('hello, world')
        CODE

        include_examples "is reported and fixed"
      end

      context "when block style is expected" do
        let(:file_name) { "foo.js" }

        let(:original) { <<~CODE }
          #{ts_copyright_header}

          console.log('hello, world')
        CODE

        let(:expected) { <<~CODE }
          /*-- copyright
          An
          example
          copyright.
          ++*/

          console.log('hello, world')
        CODE

        include_examples "is reported and fixed"
      end

      context "when end marker is missing" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#-- copyright
          An
          example
          copyright.
          #%>

          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <div>hello, world</div>
        CODE

        let(:offense) { "copyright header has no end marker" }

        include_examples "is reported and fixed only unsafely"
      end

      context "when start marker is missing" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#
          An
          example
          copyright.
          ++#%>

          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <div>hello, world</div>
        CODE

        let(:offense) { "copyright header has no start marker" }

        include_examples "is reported and fixed only unsafely"
      end

      context "when both markers are missing" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#
          An
          example
          copyright.
          #%>

          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <div>hello, world</div>
        CODE

        let(:offense) { "copyright header has no markers" }

        include_examples "is reported and fixed only unsafely"
      end

      context "when different block style is expected" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#-- copyright
          An
          example
          copyright.
          ++%>

          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <div>hello, world</div>
        CODE

        include_examples "is reported and fixed"
      end

      context "when different block style is expected and there are no markers" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#
          An
          example
          copyright.
          %>

          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <div>hello, world</div>
        CODE

        let(:offense) { "copyright header has no markers" }

        include_examples "is reported and fixed only unsafely"
      end

      context "when a later block uses the expected style" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#-- copyright
          An
          example
          copyright.
          ++%>

          <%# a note #%>
          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <%# a note #%>
          <div>hello, world</div>
        CODE

        include_examples "is reported and fixed"
      end

      context "when a later block uses the expected style and end marker is missing" do
        let(:file_name) { "foo.html.erb" }

        let(:original) { <<~CODE }
          <%#-- copyright
          An
          example
          copyright.
          %>

          <%# a note #%>
          <div>hello, world</div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <%# a note #%>
          <div>hello, world</div>
        CODE

        let(:offense) { "copyright header has no end marker" }

        include_examples "is reported and fixed only unsafely"
      end
    end

    context "with unterminated block comment" do
      let(:file_name) { "foo.html.erb" }
      let(:original) { <<~CODE }
        <%#-- copyright
        An
        example
        copyright.

        <div>hello, world</div>
      CODE

      let(:offense) { "missing copyright header" }

      let(:expected) { <<~CODE }
        #{erb_copyright_header}

        <%#-- copyright
        An
        example
        copyright.

        <div>hello, world</div>
      CODE

      include_examples "is reported and fixed"
    end
  end

  context "with a byte order mark" do
    let(:file_name) { "foo.rb" }
    let(:expected) { "\uFEFF#{rb_copyright_header}\n\nputs 'hello, world'\n" }

    context "when copyright header is up to date" do
      let(:original) { expected }

      include_examples "is already valid"
    end

    context "when copyright header is missing" do
      let(:original) { "\uFEFFputs 'hello, world'\n" }
      let(:offense) { "missing copyright header" }
      let(:line) { 1 }

      include_examples "is reported and fixed"
    end
  end

  context "when a subdirectory has its own copyright file" do
    let(:copyright_text_a) { <<~TEXT }
      A
      really
      different
      copyright.
    TEXT

    let(:copyright_text_b) { <<~TEXT }
      An
      even
      more
      different
      copyright.
    TEXT

    let(:original) { "puts 'hello, world'\n" }
    let(:offense) { "missing copyright header" }
    let(:line) { 1 }

    before do
      write("some/nested/COPYRIGHT_short", copyright_text_a)
      write("some/nested/deeper/COPYRIGHT_short", copyright_text_b)
    end

    context "when root copyright header should apply" do
      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      context "with a file in root directory" do
        let(:file_name) { "foo.rb" }

        include_examples "is reported and fixed"
      end

      context "with a file in some directory" do
        let(:file_name) { "some/foo.rb" }

        include_examples "is reported and fixed"
      end

      context "with a file in different nested directory" do
        let(:file_name) { "some/different/foo.rb" }

        include_examples "is reported and fixed"
      end
    end

    context "when nested copyright header should apply" do
      let(:expected) { <<~CODE }
        #-- copyright
        # A
        # really
        # different
        # copyright.
        #++

        puts 'hello, world'
      CODE

      context "with a file in nested directory" do
        let(:file_name) { "some/nested/foo.rb" }

        include_examples "is reported and fixed"
      end

      context "with a file in nested sub directory" do
        let(:file_name) { "some/nested/different/foo.rb" }

        include_examples "is reported and fixed"
      end
    end

    context "when deeper nested copyright header should apply" do
      let(:expected) { <<~CODE }
        #-- copyright
        # An
        # even
        # more
        # different
        # copyright.
        #++

        puts 'hello, world'
      CODE

      context "with a file in deeper nested directory" do
        let(:file_name) { "some/nested/deeper/foo.rb" }

        include_examples "is reported and fixed"
      end

      context "with a file in deeper nested sub directory" do
        let(:file_name) { "some/nested/deeper/different/foo.rb" }

        include_examples "is reported and fixed"
      end
    end
  end

  context "when a directory has an alternative copyright file" do
    let(:file_name) { "some/foo.rb" }
    let(:line) { 1 }
    let(:alternative_copyright_text) { <<~TEXT }
      Some
      different
      copyright.
    TEXT

    let(:alternative_copyright_header) { <<~CODE.chomp }
      #-- copyright
      # Some
      # different
      # copyright.
      #++
    CODE

    before do
      write("some/COPYRIGHT_short_legacy", alternative_copyright_text)
    end

    context "when header matches primary copyright" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is already valid"
    end

    context "when header matches alternative copyright" do
      let(:original) { <<~CODE }
        #{alternative_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is already valid"
    end

    context "when header is closer to alternative copyright" do
      let(:original) { <<~CODE }
        #{alternative_copyright_header.gsub('# ', '#')}

        puts 'hello, world'
      CODE

      let(:offense) { "malformed copyright header" }
      let(:expected) { <<~CODE }
        #{alternative_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when header is closer to copyright" do
      let(:original) { <<~CODE }
        #{rb_copyright_header.gsub('# ', '#')}

        puts 'hello, world'
      CODE

      let(:offense) { "malformed copyright header" }
      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when header is equally close to both copyrights" do
      let(:copyright_text) { <<~TEXT }
        A
        copyright
        one.
      TEXT

      let(:alternative_copyright_text) { <<~TEXT }
        A
        copyright
        two.
      TEXT

      let(:original) { <<~CODE }
        #-- copyright
        # A
        # copyright
        # xxx.
        #++

        puts 'hello, world'
      CODE

      let(:offense) { "malformed copyright header" }
      let(:expected) { <<~CODE }
        #-- copyright
        # A
        # copyright
        # one.
        #++

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "when header is missing" do
      let(:original) { "puts 'hello, world'\n" }
      let(:offense) { "missing copyright header" }
      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end

    context "with a file outside of that directory" do
      let(:file_name) { "foo.rb" }
      let(:original) { <<~CODE }
        #{alternative_copyright_header}

        puts 'hello, world'
      CODE

      let(:offense) { "malformed copyright header" }
      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        puts 'hello, world'
      CODE

      include_examples "is reported and fixed"
    end
  end

  describe "CLI" do
    let(:original) { "puts 'hello, world'\n" }
    let(:expected) { <<~CODE }
      #{rb_copyright_header}

      puts 'hello, world'
    CODE

    it "runs for real" do
      write("foo.rb", original)

      out, err, status = Bundler.with_unbundled_env do
        Open3.capture3(File.expand_path("../../bin/copycop", __dir__), chdir: root)
      end

      expect(out).to eq("foo.rb:1: missing copyright header\n1 file inspected, 1 with offenses, 1 safe to correct (use -a)\n")
      expect(err).to eq("")
      expect(status.exitstatus).to eq(1)
    end

    it "skips files without matching style" do
      write("text.md", "some text\n")

      expect(copycop).to eq(out: "", err: "No style for text.md\n", status: 0)

      expect(read("text.md")).to eq("some text\n")

      expect(copycop("-a")).to eq(out: "", err: "No style for text.md\n", status: 0)

      expect(read("text.md")).to eq("some text\n")
    end

    context "with overlapping style patterns" do
      let(:styles) { super() + [{ "comment" => "//", "include" => %w[**/*] }] }

      it "takes the first matching style" do
        write("foo.rb", original)

        expect(copycop).to eq(out: "foo.rb:1: missing copyright header\n", err: "", status: 1)

        expect(read("foo.rb")).to eq(original)

        expect(copycop("-a")).to eq(out: "Corrected foo.rb\n", err: "", status: 0)

        expect(read("foo.rb")).to eq(expected)
      end
    end

    it "skips empty files" do
      write("foo.rb", "")

      expect(copycop).to eq(out: "", err: "Ignored empty foo.rb\n", status: 0)

      expect(read("foo.rb")).to eq("")

      expect(copycop("-a")).to eq(out: "", err: "Ignored empty foo.rb\n", status: 0)

      expect(read("foo.rb")).to eq("")
    end

    it "accepts a single file" do
      %w[
        foo.rb
        bar.rb
        baz.rb
      ].each { write(it, original) }

      expect(copycop("bar.rb")).to eq(out: "bar.rb:1: missing copyright header\n", err: "", status: 1)

      %w[
        foo.rb
        bar.rb
        baz.rb
      ].each { expect(read(it)).to eq(original) }

      expect(copycop("-a", "bar.rb")).to eq(out: "Corrected bar.rb\n", err: "", status: 0)

      %w[
        foo.rb
        baz.rb
      ].each { expect(read(it)).to eq(original) }
      expect(read("bar.rb")).to eq(expected)
    end

    it "accepts a single dir" do
      files = %w[
        foo.rb
        lib/bar.rb
        lib/sub/bar.rb
        lib_exec/baz.rb
      ]

      files.each { write(it, original) }

      expect(copycop("lib")).to eq(out: <<~OUT, err: "", status: 1)
        lib/bar.rb:1: missing copyright header
        lib/sub/bar.rb:1: missing copyright header
      OUT

      files.each { expect(read(it)).to eq(original) }

      expect(copycop("-a", "lib")).to eq(out: <<~OUT, err: "", status: 0)
        Corrected lib/bar.rb
        Corrected lib/sub/bar.rb
      OUT

      expect(read("foo.rb")).to eq(original)
      expect(read("lib/bar.rb")).to eq(expected)
      expect(read("lib/sub/bar.rb")).to eq(expected)
      expect(read("lib_exec/baz.rb")).to eq(original)
    end

    it "aborts on path that doesn't exist" do
      write("foo.rb", original)
      write("baz.rb", original)

      expect(copycop("foo.rb", "bar.rb", "baz.rb"))
        .to eq(out: "foo.rb:1: missing copyright header\n", err: "No such file or directory bar.rb\n", status: 1)

      expect(read("foo.rb")).to eq(original)
      expect(File.exist?(full_path("bar.rb"))).to be false
      expect(read("baz.rb")).to eq(original)

      expect(copycop("-a", "foo.rb", "bar.rb", "baz.rb"))
        .to eq(out: "Corrected foo.rb\n", err: "No such file or directory bar.rb\n", status: 1)

      expect(read("foo.rb")).to eq(expected)
      expect(File.exist?(full_path("bar.rb"))).to be false
      expect(read("baz.rb")).to eq(original)
    end

    it "aborts on unknown option" do
      write("foo.rb", original)

      expect(copycop("-x")).to match(out: "", err: /\Ainvalid option: -x\n.*Usage:/m, status: 1)

      expect(read("foo.rb")).to eq(original)
    end

    context "with limited autocorrection" do
      let(:malformed) { "#-- copyright\n# Stale copyright\n#++\n\nputs 'hello, world'\n" }

      before do
        write("malformed.rb", malformed)
        write("missing.rb", original)
      end

      it "does not insert headers with --no-insert" do
        expect(copycop("-a", "--no-insert")).to eq(out: <<~OUT, err: "", status: 1)
          Corrected malformed.rb
          missing.rb:1: missing copyright header
        OUT

        expect(read("malformed.rb")).to eq(expected)
        expect(read("missing.rb")).to eq(original)
      end

      it "does not update headers with --no-update" do
        expect(copycop("-a", "--no-update")).to eq(out: <<~OUT, err: "", status: 1)
          malformed.rb:1: malformed copyright header
          Corrected missing.rb
        OUT

        expect(read("malformed.rb")).to eq(malformed)
        expect(read("missing.rb")).to eq(expected)
      end
    end

    context "with ignore pattern" do
      let(:ignore) { super() + %w[ignore/**/*] }

      it "skips ignored paths" do
        write("ignore/foo.rb", original)
        write("bar.rb", original)

        expect(copycop).to eq(out: "bar.rb:1: missing copyright header\n", err: "", status: 1)

        expect(read("ignore/foo.rb")).to eq(original)
        expect(read("bar.rb")).to eq(original)

        expect(copycop("-a")).to eq(out: "Corrected bar.rb\n", err: "", status: 0)

        expect(read("ignore/foo.rb")).to eq(original)
        expect(read("bar.rb")).to eq(expected)
      end

      it "warns on explicitly listed ignored file" do
        write("ignore/foo.rb", original)

        expect(copycop("ignore/foo.rb")).to eq(out: "", err: "Ignored ignore/foo.rb\n", status: 0)

        expect(read("ignore/foo.rb")).to eq(original)

        expect(copycop("-a", "ignore/foo.rb")).to eq(out: "", err: "Ignored ignore/foo.rb\n", status: 0)

        expect(read("ignore/foo.rb")).to eq(original)
      end
    end

    it "ignores copyright files" do
      write("some/COPYRIGHT_short", copyright_text)
      write("some/COPYRIGHT_short_legacy", copyright_text)

      expect(copycop("COPYRIGHT_short", "some/COPYRIGHT_short", "some/COPYRIGHT_short_legacy"))
        .to eq(out: "", err: <<~ERR, status: 0)
          Ignored COPYRIGHT_short
          Ignored some/COPYRIGHT_short
          Ignored some/COPYRIGHT_short_legacy
        ERR
    end

    describe "summary" do
      context "for single file" do
        it "outputs summary" do
          write("foo.rb", expected)

          expect(copycop(remove_summary: false)).to eq(out: "1 file inspected, no offenses\n", err: "", status: 0)
        end
      end

      context "with files of every result" do
        before do
          write("valid.rb", expected)
          write("safe.rb", original)
          write("unsafe.rb", "#-- copyright\n")
          write("misplaced.rb", "puts 'hello, world'\n#{rb_copyright_header}\n")
        end

        it "counts offenses" do
          expect(copycop(remove_summary: false)).to eq(out: <<~OUT, err: "", status: 1)
            misplaced.rb:2: copyright header is not at the top of the file
            safe.rb:1: missing copyright header
            unsafe.rb:1: copyright header has no end marker
            4 files inspected, 3 with offenses, 1 safe to correct (use -a), 1 unsafe to correct (use -A), 1 requires manual correction
          OUT
        end

        it "counts safe corrections" do
          expect(copycop("-a", remove_summary: false)).to eq(out: <<~OUT, err: "", status: 1)
            misplaced.rb:2: copyright header is not at the top of the file
            Corrected safe.rb
            unsafe.rb:1: copyright header has no end marker
            4 files inspected, 3 with offenses, 1 corrected, 1 unsafe to correct (use -A), 1 requires manual correction
          OUT
        end

        it "counts all corrections" do
          expect(copycop("-A", remove_summary: false)).to eq(out: <<~OUT, err: "", status: 1)
            misplaced.rb:2: copyright header is not at the top of the file
            Corrected safe.rb
            Corrected unsafe.rb
            4 files inspected, 3 with offenses, 2 corrected, 1 requires manual correction
          OUT
        end
      end
    end
  end
end

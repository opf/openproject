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

require "support/focused_spec_circuit_breaker"

load File.expand_path("../../bin/copycop", __dir__)

# rspec excludes %r{bin/} by default, so allow copycop and this spec explicitly
RSpec.configure { it.backtrace_inclusion_patterns << %r{bin/copycop} }

RSpec.describe "bin/copycop", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  let(:configuration) do
    {
      "copyright" => "COPYRIGHT_short",
      "ignore" => ignore,
      "styles" => styles
    }
  end
  let(:ignore) { [".copycop.yml", "**/COPYRIGHT_short"] }
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

  let(:rb_copyright_header) do
    <<~CODE.chomp
      #-- copyright
      # An
      # example
      # copyright.
      #++
    CODE
  end
  let(:ts_copyright_header) do
    <<~CODE.chomp
      //-- copyright
      // An
      // example
      // copyright.
      //++
    CODE
  end
  let(:erb_copyright_header) do
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

  def copycop(*args)
    code = 0

    out, err = capture_output do
      # testing CopyCop instead of bin/copycop is ~80 times faster (0.06 instead of 5s)
      code = Dir.chdir(root) { CopyCop.call(args + %w[-v]) } ? 0 : 1
    rescue SystemExit => e
      code = e.status
    end

    [out, err, code]
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

      expect(copycop).to eq(["", "", 0])

      expect(read(file_name)).to eq(original)

      expect(copycop("-a")).to eq(["", "", 0])

      expect(read(file_name)).to eq(original)
    end
  end

  shared_examples "is reported and fixed" do
    it "is reported and fixed" do
      write(file_name, original)

      expect(copycop).to eq(["#{file_name}: #{offence}\n", "", 1])

      expect(read(file_name)).to eq(original)

      expect(copycop("-a")).to eq(["Corrected #{file_name}\n", "", 0])

      expect(read(file_name)).to eq(expected)
    end
  end

  shared_examples "is reported, but not touched" do
    it "is reported, but not touched" do
      write(file_name, original)

      expect(copycop).to eq(["#{file_name}: #{offence}\n", "", 1])

      expect(read(file_name)).to eq(original)

      expect(copycop("-a")).to eq(["#{file_name}: #{offence}\n", "", 1])

      expect(read(file_name)).to eq(original)
    end
  end

  context "when copyright header is up to date" do
    let(:file_name) { "foo.rb" }
    let(:expected) { <<~CODE }
      #!/usr/bin/env ruby

      #{rb_copyright_header}

      code
    CODE

    with_different_whitespace "before" do |whitespace_before|
      with_different_whitespace "after" do |whitespace_after|
        let(:original) { <<~CODE }
          #!/usr/bin/env ruby#{whitespace_before}
          #{rb_copyright_header}#{whitespace_after}
          code
        CODE

        if whitespace_before == "\n" && whitespace_after == "\n"
          include_examples "is already valid"
        else
          let(:offence) do
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
      let(:file_name) { "foo.rb" }
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
    let(:offence) { "missing copyright header" }

    context "with line comment style" do
      let(:file_name) { "bar.rb" }

      context "when there are no special comments" do
        let(:expected) { <<~CODE }
          #{rb_copyright_header}

          code
        CODE

        with_different_whitespace "at the top" do |whitespace|
          let(:original) { "#{whitespace}code\n" }

          include_examples "is reported and fixed"
        end
      end

      context "when copyright text has a blank line" do
        let(:copyright_text) { <<~TEXT }
          An

          example

          copyright.
        TEXT
        let(:original) { "code\n" }
        let(:expected) { <<~CODE }
          #-- copyright
          # An
          #
          # example
          #
          # copyright.
          #++

          code
        CODE

        include_examples "is reported and fixed"
      end

      context "when there is no trailing newline" do
        let(:original) { "code" }
        let(:expected) { "#{rb_copyright_header}\n\ncode" }

        include_examples "is reported and fixed"
      end

      context "with a shebang" do
        let(:expected) { <<~CODE }
          #!/some/path/to/bin/foo bar baz

          #{rb_copyright_header}

          code
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            #!/some/path/to/bin/foo bar baz#{whitespace}
            code
          CODE

          include_examples "is reported and fixed"
        end
      end

      context "with a shebang and no code" do
        let(:original) { "#!/usr/bin/env not-ruby\n" }
        let(:expected) { <<~CODE }
          #!/usr/bin/env not-ruby

          #{rb_copyright_header}
        CODE

        include_examples "is reported and fixed"
      end

      context "with a magic comment" do
        let(:expected) { <<~CODE }
          # frozen_string_literal: true

          #{rb_copyright_header}

          code
        CODE

        with_different_whitespace "between" do |whitespace|
          let(:original) { <<~CODE }
            # frozen_string_literal: true#{whitespace}
            code
          CODE

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
          let(:original) { "#{magic_comment}\ncode\n" }
          let(:expected) { <<~CODE }
            #{magic_comment}

            #{rb_copyright_header}

            code
          CODE

          include_examples "is reported and fixed"
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
            #{rb_copyright_header}

            #{non_magic_comment}
            code
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

          include_examples "is reported and fixed"
        end
      end

      context "with an unmarked copyright comment below code" do
        let(:original) { <<~CODE }
          require "x"

          # Copyright by someone

          code
        CODE

        let(:expected) { <<~CODE }
          #{rb_copyright_header}

          require "x"

          # Copyright by someone

          code
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

          include_examples "is reported and fixed"
        end
      end
    end

    context "with block comment style" do
      let(:file_name) { "foo.html.erb" }
      let(:expected) { <<~CODE }
        #{erb_copyright_header}

        <div></div>
      CODE

      with_different_whitespace "at the top" do |whitespace|
        let(:original) { "#{whitespace}<div></div>\n" }

        include_examples "is reported and fixed"
      end
    end

    context "with a shebang that is not a comment" do
      let(:file_name) { "foo.ts" }
      let(:original) { <<~CODE }
        #!/usr/bin/env node
        code
      CODE

      let(:expected) { <<~CODE }
        #!/usr/bin/env node

        #{ts_copyright_header}

        code
      CODE

      include_examples "is reported and fixed"
    end
  end

  context "when copyright is incorrect" do
    let(:file_name) { "foo.rb" }
    let(:offence) { "malformed copyright header" }
    let(:expected) { <<~CODE }
      #{rb_copyright_header}

      code
    CODE

    context "when just different" do
      let(:original) { <<~CODE }
        #-- copyright
        # Stale copyright
        #++

        code
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

        code
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

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when marker has extra space" do
      let(:original) { <<~CODE }
        # -- copyright
        # Example copyright
        # ++

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when something goes after end marker" do
      let(:original) { <<~CODE }
        #{rb_copyright_header} hello, world!

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when something goes before start marker" do
      let(:original) { <<~CODE }
        # newline before copyright header removed by accident #{rb_copyright_header}

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when closing marker is missing" do
      let(:original) { <<~CODE }
        #-- copyright
        # An
        # example
        # copyright.

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when closing marker is missing and a comment follows" do
      let(:original) { <<~CODE }
        #-- copyright
        # An

        # unrelated note
        code
      CODE

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # unrelated note
        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when opening marker is missing" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        #++

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when both markers are missing" do
      let(:original) { <<~CODE }
        # An
        # example
        # copyright.
        # This can't be determined to not be part of copyright

        code
      CODE

      include_examples "is reported and fixed"
    end

    {
      "a shebang" => "#!/usr/bin/env ruby",
      "a magic comment" => "# frozen_string_literal: true",
      "a shebang and a magic comment" => "#!/usr/bin/env ruby\n# frozen_string_literal: true"
    }.each do |description, special_comment|
      context "when the chunk starts with #{description}" do
        let(:offence) { "malformed copyright header, no empty line before copyright header" }

        let(:expected) { <<~CODE }
          #{special_comment}

          #{rb_copyright_header}

          code
        CODE

        context "and opening marker is missing" do
          let(:original) { <<~CODE }
            #{special_comment}
            # An
            # example
            # copyright.
            #++

            code
          CODE

          include_examples "is reported and fixed"
        end

        context "and both markers are missing" do
          let(:original) { <<~CODE }
            #{special_comment}
            # An
            # example
            # copyright.
            # This can't be determined to not be part of copyright

            code
          CODE

          include_examples "is reported and fixed"
        end
      end
    end

    context "when a comment precedes the start marker in the same chunk" do
      let(:original) { <<~CODE }
        # some note
        #-- copyright
        # An

        code
      CODE

      let(:offence) { "malformed copyright header, no empty line before copyright header" }

      let(:expected) { <<~CODE }
        # some note

        #{rb_copyright_header}

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when a comment follows the end marker in the same chunk" do
      let(:original) { <<~CODE }
        # An
        #++
        # dangling

        code
      CODE

      let(:offence) { "malformed copyright header, no empty line after copyright header" }

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # dangling

        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when there is no trailing newline after the end marker" do
      let(:original) { rb_copyright_header }
      let(:expected) { "#{rb_copyright_header}\n" }

      include_examples "is reported and fixed"
    end

    context "when there is a comment right after" do
      let(:original) { <<~CODE }
        #{rb_copyright_header}
        # Dangling comment
        code
      CODE

      let(:offence) { "no empty line after copyright header" }

      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        # Dangling comment
        code
      CODE

      include_examples "is reported and fixed"
    end

    context "when there is whitespace before it" do
      let(:original) { <<~CODE }


        #{rb_copyright_header}

        code
      CODE

      let(:offence) { "extra whitespace before copyright header" }

      include_examples "is reported and fixed"
    end

    context "when there is code before it" do
      let(:original) { <<~CODE }
        # frozen_string_literal: true

        require "x"
        #{rb_copyright_header}

        code
      CODE

      let(:offence) { "copyright header is not at the top of the file" }

      include_examples "is reported, but not touched"
    end

    context "with something around block markers" do
      let(:file_name) { "foo.html.erb" }
      let(:expected) { <<~CODE }
        #{erb_copyright_header}

        <div></div>
      CODE

      context "when something goes after start marker" do
        let(:original) { <<~CODE }
          <%#-- copyright unexpected
          An
          example
          copyright.
          ++#%>

          <div></div>
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

          <div></div>
        CODE

        include_examples "is reported and fixed"
      end

      ["unexpected", "<b>unexpected</b>", "<%# unexpected %>"].each do |unexpected|
        context "when #{unexpected} goes after end marker" do
          let(:original) { <<~CODE }
            <%#-- copyright
            An
            example
            copyright.
            ++#%>#{unexpected}

            <div></div>
          CODE

          let(:offence) { "malformed copyright header, no empty line after copyright header" }

          let(:expected) { <<~CODE }
            #{erb_copyright_header}

            #{unexpected}

            <div></div>
          CODE

          include_examples "is reported and fixed"
        end
      end

      ["unexpected", "<b>unexpected</b>"].each do |unexpected|
        context "when #{unexpected} goes before start marker" do
          let(:original) { <<~CODE }
            #{unexpected}<%#-- copyright
            An
            example
            copyright.
            ++#%>

            <div></div>
          CODE

          let(:offence) { "copyright header is not at the top of the file" }

          include_examples "is reported, but not touched"
        end
      end

      context "when a comment goes before start marker" do
        let(:offence) { "no empty line before copyright header" }

        let(:original) { <<~CODE }
          <%# comment %><%#-- copyright
          An
          example
          copyright.
          ++#%>

          <div></div>
        CODE

        let(:expected) { <<~CODE }
          <%# comment %>

          #{erb_copyright_header}

          <div></div>
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

          code
        CODE

        let(:expected) { <<~CODE }
          #{ts_copyright_header}

          code
        CODE

        include_examples "is reported and fixed"
      end

      context "when block style is expected" do
        let(:file_name) { "foo.js" }

        let(:original) { <<~CODE }
          #{ts_copyright_header}

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

        include_examples "is reported and fixed"
      end

      context "when different block style is expected" do
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
          #{erb_copyright_header}

          <div></div>
        CODE

        include_examples "is reported and fixed"
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
          <div></div>
        CODE

        let(:expected) { <<~CODE }
          #{erb_copyright_header}

          <%# a note #%>
          <div></div>
        CODE

        include_examples "is reported and fixed"
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
        #{erb_copyright_header}

        <%#-- copyright
        An
        example
        copyright.

        <div></div>
      CODE

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

    let(:original) { "code\n" }
    let(:offence) { "missing copyright header" }

    before do
      write("some/nested/COPYRIGHT_short", copyright_text_a)
      write("some/nested/deeper/COPYRIGHT_short", copyright_text_b)
    end

    context "when root copyright header should apply" do
      let(:expected) { <<~CODE }
        #{rb_copyright_header}

        code
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

        code
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

        code
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

  describe "CLI" do
    let(:original) { "code\n" }
    let(:expected) { <<~CODE }
      #{rb_copyright_header}

      code
    CODE

    it "skips files without matching style" do
      write("text.md", "some text\n")

      expect(copycop).to eq(["", "No style for text.md\n", 0])

      expect(read("text.md")).to eq("some text\n")

      expect(copycop("-a")).to eq(["", "No style for text.md\n", 0])

      expect(read("text.md")).to eq("some text\n")
    end

    context "with overlapping style patterns" do
      let(:styles) { super() + [{ "comment" => "//", "include" => %w[**/*] }] }

      it "takes the first matching style" do
        write("foo.rb", original)

        expect(copycop).to eq(["foo.rb: missing copyright header\n", "", 1])

        expect(read("foo.rb")).to eq(original)

        expect(copycop("-a")).to eq(["Corrected foo.rb\n", "", 0])

        expect(read("foo.rb")).to eq(expected)
      end
    end

    it "skips empty files" do
      write("foo.rb", "")

      expect(copycop).to eq(["", "Ignoring empty foo.rb\n", 0])

      expect(read("foo.rb")).to eq("")

      expect(copycop("-a")).to eq(["", "Ignoring empty foo.rb\n", 0])

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

      expect(copycop("-a", "bar.rb")).to eq(["Corrected bar.rb\n", "", 0])

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

      expect(copycop("-a", "lib")).to eq(["Corrected lib/bar.rb\nCorrected lib/sub/bar.rb\n", "", 0])

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

      expect(copycop("-a", "foo.rb", "bar.rb", "baz.rb"))
        .to eq(["Corrected foo.rb\n", "No such file or directory bar.rb\n", 1])

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

        expect(copycop("-a")).to eq(["Corrected bar.rb\n", "", 0])

        expect(read("ignore/foo.rb")).to eq(original)
        expect(read("bar.rb")).to eq(expected)
      end

      it "warns on explicitly listed ignored file" do
        write("ignore/foo.rb", original)

        expect(copycop("ignore/foo.rb")).to eq(["", "Ignored ignore/foo.rb\n", 0])

        expect(read("ignore/foo.rb")).to eq(original)

        expect(copycop("-a", "ignore/foo.rb")).to eq(["", "Ignored ignore/foo.rb\n", 0])

        expect(read("ignore/foo.rb")).to eq(original)
      end
    end
  end
end

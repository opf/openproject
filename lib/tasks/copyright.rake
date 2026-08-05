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

# rubocop:disable Rails/RakeEnvironment
namespace :copyright do
  def short_copyright(format, options = {})
    case format
    when :ruby, :rb
      short_copyright_line("#", options)
    when :js, :sass, :ts
      short_copyright_line("//", options)
    when :css
      short_copyright_surrounding("/*", "*/", options)
    when :sql
      short_copyright_line("-- ", options)
    when :erb
      short_copyright_surrounding("<%#", "#%>", options)
    when :rdoc
      "----------\n#{short_copyright_line(' ', options)}\n----------\n".gsub(" -- copyright", "==== copyright\n")
    when :md
      short_copyright_surrounding("<!--", "-->", options)
    else
      raise "Undefined format #{format}"
    end
  end

  def copyright_file(options = {})
    path = "COPYRIGHT_short"
    if options[:path]
      path = File.join(options[:path], "COPYRIGHT_short") if File.exist?(File.join(options[:path],
                                                                                   "COPYRIGHT_short"))
      path = File.join(options[:path], "COPYRIGHT_short.md") if File.exist?(File.join(options[:path],
                                                                                      "COPYRIGHT_short.md"))
    end
    path
  end

  def short_copyright_surrounding(open, close, options = {})
    short_copyright = File.read copyright_file(options)

    "#{open}-- copyright\n#{short_copyright}\n++#{close}"
  end

  def short_copyright_line(sign, options = {})
    short_copyright = File.readlines(copyright_file(options)).collect do |line|
      "#{sign} #{line}".rstrip
    end.join("\n")

    "#{sign}-- copyright\n#{short_copyright}\n#{sign}++"
  end

  def global_excluded_globs
    %w[
      **/node_modules/**/*
      tmp/**/*
      modules/gitlab_integration/**/*
    ] + build_output_globs
  end

  # Generated output. Writing a header into a built bundle changes it out from under the
  # digest that references it, so these have to be skipped even though they are gitignored
  # and therefore invisible to `git status`.
  def build_output_globs
    %w[
      app/assets/javascripts/editor/**/*
      app/assets/javascripts/locales/**/*
      frontend/dist/**/*
      frontend/out-tsc/**/*
      public/assets/**/*
      public/plugin_assets/**/*
    ]
  end

  # `**` never descends into dot-directories, which is what we want for caches such as
  # `.git` or `node_modules/.vite`. Dot-directories holding first-party sources are
  # listed here so they are globbed explicitly.
  def included_dot_directories
    %w[.redocly]
  end

  def source_file_list(path, endings)
    roots = [path, *included_dot_directories.map { |directory| File.join(path, directory) }]

    # One brace glob per root: a glob per ending would walk the whole tree once per extension.
    roots.flat_map { |root| Dir.glob("#{root}/**/*.{#{endings.join(',')}}") }.uniq
  end

  def copyright_regexp(format)
    case format
    when :ruby, :rb
      /\A(?<shebang>#![^\n]+\n)?(?<additional>.*)?#--\s*copyright.*?\+\+/m
    when :js, :ts
      # Headers in the wild are not uniform: the `-- copyright` opener, the `++` closer or
      # both may be missing, the markers may carry a space (`// -- copyright`), and the
      # notice may be a `//` run or a `/* */` block. The lookaheads decide whether a leading
      # comment is a copyright notice at all; the bodies then consume exactly that comment
      # and nothing that follows it.
      %r{
        \A
        (?<shebang>)
        (?<additional>)
        (?:
          (?=//(?:\s*--\s*copyright|\s*OpenProject\ is\ an\ open\ source\ project\ management\ software\.))
          (?:^//(?!\s*\+\+)[^\n]*(?:\n|\z))*   # body lines, stopping before the closer
          (?:^//\s*\+\+[^\n]*(?:\n|\z))?       # the closer, when the notice still has one
          |
          (?=/\*(?:(?!\*/).)*?(?:--\s*copyright|OpenProject\ is\ an\ open\ source\ project\ management\ software\.))
          /\*(?:(?!\*/).)*\*/
        )
        (?:[^\S\n]*\n)*
      }mx
    when :css, :sass
      /\A(?<shebang>#![^\n]+\n)?(?<additional>.*)?\/\/\s*--\s*copyright.*?\/\/\s*\+\+/m
    when :erb
      /\A(?<shebang>#![^\n]+\n)?(?<additional>.*)?<%#--\s*copyright.*?\+\+#%>/m
    when :rdoc
      /(?<shebang>)?(?<additional>.*)?-{10}\n={4} copyright\n\n[\s\S]*?\+\+\n-{10}\n\z/
    when :md, :html
      /\A(?<shebang>#![^\n]+\n)?(?<additional>.*)?<!----\s*copyright.*?\+\+-->/m
    when :sql
      /\A(?<shebang>#![^\n]+\n)?(?<additional>.*)?-- --\s*copyright.*?\+\+/m
    else
      raise "Undefined format #{format}"
    end
  end

  def missing_copyright_regexp(format)
    case format
    when :ruby, :rb
      /\A(?<shebang>#![^\n]+\n\n?)?(?<additional># frozen_string_literal: (?:true|false)\n\n?)?\n*/m
    when :js, :ts
      /\A(?<shebang>)(?<additional>)/
    else
      raise "Format #{format} is not yet supported for copyright creation"
    end
  end

  def rewrite_copyright(ending, additional_excluded_globs, format, path, options = {}) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    regexp = options[:regex] || copyright_regexp(format)
    path = "." if path.nil?
    copyright = options[:copyright] || short_copyright(format, path:)
    file_list = options[:file_list] || Dir[path + "/**/*.#{ending}"]
    excluded_globs = global_excluded_globs.concat(additional_excluded_globs)

    raise "Path not found" unless Dir.exist?(path)

    file_list.each do |file_name|
      file_name = file_name.delete_prefix("./")

      next if excluded_globs.any? do |glob|
        File.fnmatch(glob, file_name,
                     File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_CASEFOLD | File::FNM_DOTMATCH)
      end

      file_content = File.read(file_name)
      if file_content.match(regexp)
        replacement = "\\k<shebang>\\k<additional>#{copyright}"
        replacement += "\n\n" if options[:ensure_blank_line]
        file_content.gsub!(regexp, replacement)
      elsif options[:create]
        if file_content.include?("OpenProject is a fork of ChiliProject")
          puts "#{file_name} does not match regexp, but seems to have a copyright header!"
          next
        end

        file_content.gsub!(missing_copyright_regexp(format), "\\k<shebang>\\k<additional>#{copyright}\n\n")
      else
        puts "#{file_name} does not match regexp. Missing copyright notice?"
      end

      File.write(file_name, file_content)
    end
  end

  desc "Update special files, which do not have an ending"
  task :update_special_files, :path do |_task, args|
    # ruby-like files
    file_list = %w[
      Gemfile
      Rakefile
      config.ru
      .gitignore
    ]

    rewrite_copyright("rb", [], :rb, args[:path], file_list:, create: true)
  end

  desc "Update the copyright on .rb source files"
  task :update_rb, :path do |_task, args|
    excluded = %w[
      lib_static/plugins/{acts_as_tree,rfpdf,verification}/**/*
      lib/chronic_duration.rb
    ]

    rewrite_copyright("rb", excluded, :rb, args[:path], create: true)
  end

  desc "Update the copyright on .rake source files"
  task :update_rake, :path do |_task, args|
    rewrite_copyright("rake", [], :rb, args[:path], create: true)
  end

  desc "Update the copyright on .yml source files"
  task :update_yml, :path do |_task, args|
    excluded = %w[
      config/locales/{crowdin,generated}/*.yml
      modules/*/config/locales/crowdin/*.yml
    ]

    rewrite_copyright("yml", excluded, :rb, args[:path], create: true)
  end

  desc "Update the copyright on .yml.example source files"
  task :update_yml_example, :path do |_task, args|
    rewrite_copyright("yml.example", [], :rb, args[:path], create: true)
  end

  desc "Update the copyright on .rb.example source files"
  task :update_rb_example, :path do |_task, args|
    rewrite_copyright("rb.example", [], :rb, args[:path], create: true)
  end

  desc "Update the copyright on .rjs source files"
  task :update_rjs, :path do |_task, args|
    rewrite_copyright("rjs", [], :rb, args[:path], create: true)
  end

  desc "Update the copyright on .feature source files"
  task :update_feature, :path do |_task, args|
    rewrite_copyright("feature", [], :rb, args[:path], create: true)
  end

  desc "Update the copyright on .css source files"
  task :update_css, :path do |_task, args|
    rewrite_copyright("css", [], :css, args[:path])
  end

  desc "Update the copyright on .css.erb source files"
  task :update_css_erb, :path do |_task, args|
    rewrite_copyright("css.erb", [], :css, args[:path])
  end

  desc "Update the copyright on .sass source files"
  task :update_sass, :path do |_task, args|
    rewrite_copyright("sass", [], :sass, args[:path])
  end

  desc "Update the copyright on .sql source files"
  task :update_sql, :path do |_task, args|
    rewrite_copyright("sql", [], :sql, args[:path])
  end

  desc "Update the copyright on .js, .mjs, and .cjs source files"
  task :update_js, :path do |_task, args|
    path = args[:path] || "."
    excluded = %w[**/vendor/**/*]

    rewrite_copyright("js", excluded, :js, path,
                      file_list: source_file_list(path, %w[js mjs cjs]),
                      create: true,
                      ensure_blank_line: true)
  end

  desc "Update the copyright on .js.erb source files"
  task :update_js_erb, :path do |_task, args|
    rewrite_copyright("js.erb", [], :erb, args[:path])
  end

  desc "Update the copyright on .rdoc source files"
  task :update_rdoc, :path do |_task, args|
    excluded = %w[
      README.rdoc
      LICENSE
      COPYRIGHT
      COPYRIGHT_short
    ]

    rewrite_copyright("rdoc", excluded, :rdoc, args[:path], position: :bottom)
  end

  desc "Update the copyright on .html.erb source files"
  task :update_html_erb, :path do |_task, args|
    rewrite_copyright("html.erb", [], :erb, args[:path])
  end

  desc "Update the copyright on .json.erb source files"
  task :update_json_erb, :path do |_task, args|
    rewrite_copyright("json.erb", [], :erb, args[:path])
  end

  desc "Update the copyright on .atom.builder source files"
  task :update_atom_builder, :path do |_task, args|
    rewrite_copyright("atom.builder", [], :rb, args[:path])
  end

  desc "Update the copyright on .text.erb source files"
  task :update_text_erb, :path do |_task, args|
    rewrite_copyright("text.erb", [], :erb, args[:path])
  end

  desc "Update the copyright on .ts and .tsx source files"
  task :update_typescript, :path do |_task, args|
    path = args[:path] || "."
    excluded = %w[**/vendor/**/*]

    rewrite_copyright("ts", excluded, :ts, path,
                      file_list: source_file_list(path, %w[ts tsx]),
                      create: true,
                      ensure_blank_line: true)
  end

  desc "Update the copyright on all source files"
  task :update, :path do |_task, args|
    Rake::Task.tasks
      .select { |task| task.name.start_with?("copyright:update_") }
      .each { |task| task.invoke(args[:path]) }
  end
end
# rubocop:enable Rails/RakeEnvironment

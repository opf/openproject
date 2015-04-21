#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :copyright do
  def short_copyright(format, options = {})
    case format
    when :ruby, :rb
      short_copyright_line('#', options)
    when :js, :sass
      short_copyright_line('//', options)
    when :css
      short_copyright_surrounding('/*', '*/', options)
    when :sql
      short_copyright_line('-- ', options)
    when :erb
      short_copyright_surrounding('<%#', '#%>', options)
    when :rdoc
      "----------\n#{short_copyright_line(' ', options)}\n----------\n".gsub(' -- copyright', "==== copyright\n")
    when :md, :html
      short_copyright_surrounding('<!--', '-->', options)
    else
      raise "Undefined format #{format}"
    end
  end

  def copyright_file(options = {})
    path = 'doc/COPYRIGHT_short.rdoc'
    if options[:path]
      path = File.join(options[:path], 'doc/COPYRIGHT_short.rdoc') if File.exists?(File.join(options[:path], 'doc/COPYRIGHT_short.rdoc'))
      path = File.join(options[:path], 'doc/COPYRIGHT_short.md')   if File.exists?(File.join(options[:path], 'doc/COPYRIGHT_short.md'))
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

  def copyright_regexp(format)
    case format
    when :ruby, :rb
      /\A(?<shebang>#![^\n]+\n)?(?<additional>.*)?#--\s*copyright.*?\+\+/m
    when :js, :css, :sass
      /\A(?<shebang>#![^\n]+\n)?(?<additional>.*)?\/\/--\s*copyright.*?\/\/\+\+/m
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

  def rewrite_copyright(ending, exclude, format, path, options = {})
    regexp = options[:regex] || copyright_regexp(format)
    path = '.' if path.nil?
    copyright = options[:copyright] || short_copyright(format, path: path)
    file_list = options[:file_list] || Dir[File.absolute_path(path) + "/**/*.#{ending}"]

    raise 'Path not found' unless Dir.exists?(path)
    file_list.each do |file_name|
      # Skip 3rd party code
      next if exclude.any? { |e| file_name.include?(e) }

      file_content = File.read(file_name)
      if file_content.match(regexp)
        file_content.gsub!(regexp, '\k<shebang>' + '\k<additional>' + copyright)
      else
        if options[:position] == :bottom
          file_content = file_content + "\n\n" + copyright # append
        else
          file_content = copyright + "\n\n" + file_content # prepend
        end
      end

      File.open(file_name, 'w') do |file|
        file.write file_content
      end
    end
  end

  desc 'Update special files, which do not have an ending'
  task :update_special_files, :arg1 do |_task, args|
    # ruby-like files
    file_list = %w{Gemfile Guardfile Rakefile config.ru .travis.yml
                   .rspec .gitignore}.map do |f|
      File.absolute_path f
    end
    rewrite_copyright('rb', [], :rb, args[:arg1], file_list: file_list)
  end

  desc 'Update the copyright on .rb source files'
  task :update_rb, :arg1 do |_task, args|
    excluded = (['acts_as_tree',
                 'rfpdf',
                 'verification'].map { |dir| "lib/plugins/#{dir}" }) +
               (['redcloth'].map { |dir| "lib/#{dir}" })

    rewrite_copyright('rb', excluded, :rb, args[:arg1])
  end

  desc 'Update the copyright on .rake source files'
  task :update_rake, :arg1 do |_task, args|
    rewrite_copyright('rake', [], :rb, args[:arg1])
  end

  desc 'Update the copyright on .yml source files'
  task :update_yml, :arg1 do |_task, args|
    rewrite_copyright('yml', [], :rb, args[:arg1])
  end

  desc 'Update the copyright on .yml.example source files'
  task :update_yml_example, :arg1 do |_task, args|
    rewrite_copyright('yml.example', [], :rb, args[:arg1])
  end

  desc 'Update the copyright on .rb.example source files'
  task :update_rb_example, :arg1 do |_task, args|
    rewrite_copyright('rb.example', [], :rb, args[:arg1])
  end

  desc 'Update the copyright on .rjs source files'
  task :update_rjs, :arg1 do |_task, args|
    rewrite_copyright('rjs', [], :rb, args[:arg1])
  end

  desc 'Update the copyright on .feature source files'
  task :update_feature, :arg1 do |_task, args|
    rewrite_copyright('feature', [], :rb, args[:arg1])
  end

  desc 'Update the copyright on .css source files'
  task :update_css, :arg1 do |_task, args|
    excluded = []

    rewrite_copyright('css', excluded, :css, args[:arg1])
  end

  desc 'Update the copyright on .css.erb source files'
  task :update_css_erb, :arg1 do |_task, args|
    excluded = []

    rewrite_copyright('css.erb', excluded, :css, args[:arg1])
  end

  desc 'Update the copyright on .sass source files'
  task :update_sass, :arg1 do |task, args|
    excluded = %w(
      app/assets/stylesheets/default.css.sass
    )
    rewrite_copyright('sass', excluded, :sass, args[:arg1])
  end

  desc 'Update the copyright on .sql source files'
  task :update_sql, :arg1 do |_task, args|
    rewrite_copyright('sql', [], :sql, args[:arg1])
  end

  desc 'Update the copyright on .js source files'
  task :update_js, :arg1 do |_task, args|
    excluded = ['app/assets/javascripts/date-de-DE.js',
                'app/assets/javascripts/date-en-US.js',
                'app/assets/javascripts/jstoolbar/',
                'app/assets/javascripts/lib/',
                'frontend/bower_components',
                'frontend/node_modules',
                'frontend/vendor']

    rewrite_copyright('js', excluded, :js, args[:arg1])
  end

  desc 'Update the copyright on .js.erb source files'
  task :update_js_erb, :arg1 do |_task, args|
    excluded = ['app/assets/javascripts/application.js.erb',
                'app/assets/javascripts/jstoolbar']

    rewrite_copyright('js.erb', excluded, :erb, args[:arg1])
  end

  desc 'Update the copyright on .rdoc source files'
  task :update_rdoc, :arg1 do |_task, args|
    excluded = ['README.rdoc',
                'doc/COPYRIGHT.rdoc',
                'doc/COPYING.rdoc',
                'doc/COPYRIGHT_short.rdoc']

    rewrite_copyright('rdoc', excluded, :rdoc, args[:arg1], position: :bottom)
  end

  desc 'Update the copyright on .html.erb source files'
  task :update_html_erb, :arg1 do |_task, args|
    rewrite_copyright('html.erb', [], :erb, args[:arg1])
  end

  desc 'Update the copyright on .html source files'
  task :update_html, :arg1 do |_task, args|
    excluded = [
                  'coverage',
                  'frontend/app/templates/',
                  'frontend/bower_components',
                  'frontend/coverage',
                  'frontend/node_modules',
                  'frontend/tests/integration/mocks/',
                  'frontend/tmp',
                  'frontend/vendor'
                ]
    rewrite_copyright('html', excluded, :html, args[:arg1])
  end

  desc 'Update the copyright on .json.erb source files'
  task :update_json_erb, :arg1 do |_task, args|
    rewrite_copyright('json.erb', [], :erb, args[:arg1])
  end

  desc 'Update the copyright on .atom.builder source files'
  task :update_atom_builder, :arg1 do |_task, args|
    rewrite_copyright('atom.builder', [], :rb, args[:arg1])
  end

  desc 'Update the copyright on .text.erb source files'
  task :update_text_erb, :arg1 do |_task, args|
    rewrite_copyright('text.erb', [], :erb, args[:arg1])
  end

  desc 'Update the copyright on all source files'
  task :update, :arg1 do |_task, args|
    %w{
      css rb js js_erb css_erb html_erb json_erb text_erb atom_builder rake
      feature rdoc rjs sql html yml yml_example rb_example special_files sass
    }.each do |t|
      Rake::Task['copyright:update_' + t.to_s].invoke(args[:arg1])
    end
  end
end

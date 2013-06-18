#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :copyright do
  def short_copyright(format)
    case format
    when :ruby, :rb
      short_copyright_line("#")
    when :js, :css
      short_copyright_line("//")
    when :erb
      short_copyright_surrounding("<%#", "#%>")
    else
      raise "Undefined format #{format}"
    end
  end

  def short_copyright_surrounding(open, close)
    short_copyright = File.read("doc/COPYRIGHT_short.rdoc")

    "#{open}-- copyright\n#{short_copyright}\n++#{close}"
  end

  def short_copyright_line(sign)
    short_copyright = File.readlines("doc/COPYRIGHT_short.rdoc").collect do |line|
      "#{sign} #{line}".rstrip
    end.join("\n")

    "#{sign}-- copyright\n#{short_copyright}\n#{sign}++"
  end

  def copyright_regexp(format)
    case format
    when :ruby, :rb
      /^#--\s*copyright.*?\+\+/m
    when :js, :css
      /^\/\/--\s*copyright.*?\/\/\+\+/m
    when :erb
      /^<%#--\s*copyright.*?\+\+#%>/m
    else
      raise "Undefined format #{format}"
    end
  end

  def rewrite_copyright(ending, exclude, format)
    regexp = copyright_regexp(format)
    copyright = short_copyright(format)

    Dir["**/**{.#{ending}}"].each do |file_name|
      # Skip 3rd party code
      next if exclude.any? {|e| file_name.include?(e) }

      file_content = File.read(file_name)
      if file_content.match(regexp)
        file_content.gsub!(regexp, copyright)
      else
        file_content = copyright + "\n\n" + file_content # Prepend
      end

      File.open(file_name, "w") do |file|
        file.write file_content
      end
    end
  end

  desc "Update the copyright on .rb source files"
  task :update_rb do
    excluded = (["diff",
                 "ruby-net-ldap-0.0.4",
                 "acts_as_tree",
                 "classic_pagination",
                 "dynamic_form",
                 "rfpdf",
                 "gravatar",
                 "verification"].map{ |dir| "lib/plugins/#{dir}" }) +
               (["SVG",
                 "redcloth"].map{ |dir| "lib/#{dir}" })

    rewrite_copyright("rb", excluded, :rb)
  end

  desc "Update the copyright on .rake source files"
  task :update_rake do
    rewrite_copyright("rake", [], :rb)
  end

  desc "Update the copyright on .feature source files"
  task :update_feature do
    rewrite_copyright("feature", [], :rb)
  end

  desc "Update the copyright on .css source files"
  task :update_css do
    excluded = ["app/assets/stylesheets/reset.css",
                "lib/assets",
                "app/assets/javascripts/tinymce"]

    rewrite_copyright("css", excluded, :css)
  end

  desc "Update the copyright on .css.erb source files"
  task :update_css_erb do
    excluded = ["lib/assets/stylesheets/select2.css.erb"]

    rewrite_copyright("css.erb", excluded, :css)
  end

  desc "Update the copyright on .js source files"
  task :update_js do
    excluded = ["lib/assets",
                "app/assets/javascripts/Bitstream_Vera_Sans_400.font.js",
                "app/assets/javascripts/date-de-DE.js",
                "app/assets/javascripts/date-en-US.js",
                "app/assets/javascripts/raphael.js",
                "app/assets/javascripts/raphael-min.js",
                "app/assets/javascripts/tinymce",
                "app/assets/javascripts/calendar",
                "app/assets/javascripts/jstoolbar"]

    rewrite_copyright("js", excluded, :js)
  end

  desc "Update the copyright on .js.erb source files"
  task :update_js_erb do
    excluded = ["lib/assets",
                "app/assets/javascripts/tinymce",
                "app/assets/javascripts/calendar",
                "app/assets/javascripts/jstoolbar"]

    rewrite_copyright("js.erb", excluded, :erb)
  end

  desc "Update the copyright on .html.erb source files"
  task :update_html_erb do
    rewrite_copyright("html.erb", [], :erb)
  end

  desc "Update the copyright on .api.rsb source files"
  task :update_api_rsb do
    rewrite_copyright("api.rsb", [], :rb)
  end

  desc "Update the copyright on all source files"
  task :update => [:update_css,
                   :update_rb,
                   :update_js,
                   :update_js_erb,
                   :update_css_erb,
                   :update_html_erb,
                   :update_api_rsb,
                   :update_rake,
                   :update_feature]
end

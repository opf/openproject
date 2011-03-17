#!/usr/bin/env ruby

require 'yaml'

langdir = File.join(File.dirname(__FILE__), '..', '..', 'config', 'locales')

template_file = "#{langdir}/en.yml"
template = YAML::load_file(template_file)['en']

errors = false

Dir.glob("#{langdir}/*.yml").each {|lang_file|
  next if lang_file == template_file

  lang = YAML::load_file(lang_file)
  l = lang.keys[0]

  template.each_pair {|key, txt|
    if ! lang[l][key]
      puts "missing: ${l}: #{key}"
      errors = true
    end
  }

  lang[l].keys.each {|k|
    if !template[k]
      puts "obsolete: #{l}: #{k}"
      errors = true
    end
  }
}

puts "All OK!" unless errors

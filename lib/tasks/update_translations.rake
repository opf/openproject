desc 'Update translation files'

require 'yaml'

namespace :redmine do
    namespace :backlogs do
        task :update_translations => :environment do
            langdir = File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/locales'
            template_file = "#{langdir}/en.yml"
            template = YAML::load_file(template_file)['en']

            Dir.glob("#{langdir}/*.yml").each {|lang_file|
                next if lang_file == template_file
                lang = YAML::load_file(lang_file)
                l = lang.keys[0]

                template.each_pair {|key, txt|
                    next if lang[l][key]
                    lang[l][key] = "[[#{txt}]]"
                }
                lang[l].keys.each {|k|
                  lang[l].delete(k) unless template[k]
                }

                File.open( lang_file, 'w' ) do |out|
                    YAML.dump(lang, out)
                end
            }
        end
    end
end

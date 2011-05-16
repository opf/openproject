require 'net/http'
require 'rexml/document'

require 'yaml'
require 'uri/common'

module TaskboardCard
  class Page
    unloadable

    LABELS_FILE_NAME = File.join(File.dirname(__FILE__), '..', '..', 'config', 'labels.yml')

    if File.exist? LABELS_FILE_NAME
      LABELS = YAML::load_file(LABELS_FILE_NAME)
    else
      warn 'No label definitions found. Will not be able to print story cards.'
      LABELS = {}
    end

    class << self
      def available?
        selected_label.present?
      end

      def selected_label
        LABELS[Setting.plugin_redmine_backlogs[:card_spec]]
      end

      def measurement(x)
        x = "#{x}pt" if x =~ /[0-9]$/
        x
      end

      def malformed?(label)
        TaskboardCard::Card.topts(label['height']) > TaskboardCard::Card.topts(label['vertical_pitch']) ||
          TaskboardCard::Card.topts(label['width']) > TaskboardCard::Card.topts(label['horizontal_pitch'])
      end

      def fetch_labels
        LABELS.delete_if do |label|
          LABELS[label].blank? or Label.malformed?(LABELS[label])
        end

        malformed_labels = {}

        fetched_templates.each do |filename|
          uri = URI.parse("http://git.gnome.org/browse/glabels/plain/templates/#{filename}")
          labels = nil

          if ENV['http_proxy'].present?
            begin
              proxy = URI.parse(ENV['http_proxy'])
              if proxy.userinfo
                user, pass = proxy.userinfo.split(/:/)
              else
                user = pass = nil
              end
              labels = Net::HTTP::Proxy(proxy.host, proxy.port, user, pass).start(uri.host) {|http| http.get(uri.path)}.body
            rescue URI::Error => e
              puts "Setup proxy failed: #{e}"
              labels = nil
            end
          end

          begin
            labels = Net::HTTP.get_response(uri).body if labels.nil?
          rescue
            labels = nil
          end

          if labels.nil?
            puts "Could not fetch #{filename}"
            next
          end

          doc = REXML::Document.new(labels)

          doc.elements.each('Glabels-templates/Template') do |specs|
            label = nil

            papersize = specs.attributes['size']
            papersize = 'Letter' if papersize == 'US-Letter'

            specs.elements.each('Label-rectangle') do |geom|
              margin = nil
              geom.elements.each('Markup-margin') do |m|
                  margin = m.attributes['size']
              end
              margin = "1mm" if margin.blank?

              geom.elements.each('Layout') do |layout|
                label = {
                  'inner_margin'     => Page.measurement(margin),
                  'across'           => Integer(layout.attributes['nx']),
                  'down'             => Integer(layout.attributes['ny']),
                  'top_margin'       => Page.measurement(layout.attributes['y0']),
                  'height'           => Page.measurement(geom.attributes['height']),
                  'horizontal_pitch' => Page.measurement(layout.attributes['dx']),
                  'left_margin'      => Page.measurement(layout.attributes['x0']),
                  'width'            => Page.measurement(geom.attributes['width']),
                  'vertical_pitch'   => Page.measurement(layout.attributes['dy']),
                  'papersize'        => papersize,
                  'source'           => 'glabel'
                }
              end
            end

            next if label.nil? || label['across'] != 1 || label['down'] != 1 || label['papersize'].downcase == 'other'

            key = "#{specs.attributes['brand']} #{specs.attributes['part']}"

            if Page.malformed?(label)
              puts "Skipping malformed label '#{key}' from #{filename}"
              malformed_labels[key] = label
            else
              LABELS[key] = label if not LABELS[key] or LABELS[key]['source'] == 'glabel'

              specs.elements.each('Alias') do |also|
                key = "#{also.attributes['brand']} #{also.attributes['part']}"
                LABELS[key] = label.dup if not LABELS[key] or LABELS[key]['source'] == 'glabel'
              end
            end
          end
        end

        File.open(LABELS_FILE_NAME, 'w') do |dump|
          YAML.dump(LABELS, dump)
        end
        File.open(File.dirname(__FILE__) + '/labels-malformed.yml', 'w') do |dump|
          YAML.dump(malformed_labels, dump)
        end

        if Setting.plugin_redmine_backlogs[:card_spec] && ! Page.selected_label && LABELS.size != 0
          # current label non-existant
          label = LABELS.keys[0]
          puts "Non-existant label stock '#{Setting.plugin_redmine_backlogs[:card_spec]}' selected, replacing with random '#{label}'"
          s = Setting.plugin_redmine_backlogs
          s[:card_spec] = label
          Setting.plugin_redmine_backlogs = s
        end
      end

      def fetched_templates
        ['avery-iso-templates.xml',
         'avery-other-templates.xml',
         'avery-us-templates.xml',
         'brother-other-templates.xml',
         'dymo-other-templates.xml',
         'maco-us-templates.xml',
         'misc-iso-templates.xml',
         'misc-other-templates.xml',
         'misc-us-templates.xml',
         'pearl-iso-templates.xml',
         'uline-us-templates.xml',
         'worldlabel-us-templates.xml',
         'zweckform-iso-templates.xml']
      end
    end
  end
end
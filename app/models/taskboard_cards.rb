#!/usr/bin/ruby

require 'rubygems'
require 'prawn'
require 'prawn/measurement_extensions'
require 'net/http'
require 'rexml/document'

require 'yaml'

class TaskboardCards
    LABELS = YAML::load_file(File.dirname(__FILE__) + '/labels.yaml')

    def self.selected_label
        return nil if not Setting.plugin_redmine_backlogs[:card_spec]
        return LABELS[Setting.plugin_redmine_backlogs[:card_spec]]
    end

    def initialize
        label = TaskboardCards.selected_label
        raise "No label spec selected" if label.nil?

        geom = Prawn::Document::PageGeometry::SIZES[label['papersize']]
        raise "Paper size '#{label['papersize']} not supported" if geom.nil?

        @paper_width = geom[0]
        @paper_height = geom[1]

        @top_margin = topts(label['top_margin'])
        @vertical_pitch = topts(label['vertical_pitch'])
        @height = topts(label['height'])

        @left_margin = topts(label['left_margin'])
        @horizontal_pitch = topts(label['horizontal_pitch'])
        @width = topts(label['width'])

        @across = label['across']
        @down = label['down']

        @inner_margin = topts(label['inner_margin']) || 1.mm

        @pdf = Prawn::Document.new(
            :page_layout => :portrait,
            :left_margin => 0,
            :right_margin => 0,
            :top_margin => 0,
            :bottom_margin => 0,
            :page_size => label['papersize'])

        @cards = 0
    end

    def self.fetch_labels
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
         'zweckform-iso-templates.xml'].each {|url|
            labels = Net::HTTP.get_response(URI.parse("http://git.gnome.org/browse/glabels/plain/templates/#{url}")).body
            doc = REXML::Document.new(labels)

            doc.elements.each('Glabels-templates/Template') do |specs|
                label = nil

                papersize = specs.attributes['size']
                papersize = 'Letter' if papersize = 'US-Letter'

                specs.elements.each('Label-rectangle') do |geom|
                    margin = nil
                    geom.elements.each('Markup-margin') do |m|
                        margin = m.attributes['size']
                    end
                    margin = "1mm" if margin.nil?

                    geom.elements.each('Layout') do |layout|
                        label = {
                            'inner_margin' => margin,
                            'across' => Integer(layout.attributes['nx']),
                            'down' => Integer(layout.attributes['ny']),
                            'top_margin' => layout.attributes['y0'],
                            'height' => geom.attributes['height'],
                            'vertical_pitch' => layout.attributes['dx'],
                            'left_margin' => layout.attributes['x0'],
                            'width' => geom.attributes['width'],
                            'horizontal_pitch' => layout.attributes['dy'],
                            'papersize' => papersize,
                            'source' => 'glabel'
                        }
                    end
                end

                next if label.nil?

                key = "#{specs.attributes['brand']} #{specs.attributes['part']}"

                LABELS[key] = label if not LABELS[key] or LABELS[key]['source'] == 'glabel'

                specs.elements.each('Alias') do |also|
                    key = "#{also.attributes['brand']} #{also.attributes['part']}"
                    LABELS[key] = label.dup if not LABELS[key] or LABELS[key]['source'] == 'glabel'
                end
            end
        }

        File.open(File.dirname(__FILE__) + '/labels.yaml', 'w') do |dump|
            YAML.dump(LABELS, dump)
        end
    end

    attr_reader :pdf

    def task_header(t)
        return "#{t.id}: #{t.subject}"
    end

    def story_header(s)
        pos = (s.position.nil? ? '?' : s.position)
        return "#{pos} / #{s.id}: #{s.subject}"
    end

    def card(issue, cardtype)
        row = (@cards % @down) + 1
        col = ((@cards / @down) % @across) + 1
        @cards += 1

        @pdf.start_new_page if row == 1 and col == 1 and @cards != 1

        parent_story = issue.story

        # card bounds
        @pdf.bounding_box self.top_left(row, col), :width => @width, :height => @height do
            @pdf.line_width = 0.5
            @pdf.stroke do
                @pdf.stroke_bounds
                
                # card margin
                @pdf.bounding_box [@inner_margin, @height - @inner_margin],
                                    :width => @width - (2 * @inner_margin),
                                    :height => @height - (2 * @inner_margin) do
                    @pdf.font_size(6) do
                        @pdf.text((issue.self_and_ancestors.reverse.collect{|i| "#{i.tracker.name} ##{i.id}"}.join(" : ")) + " (#{parent_story.position})")
                    end
                    if cardtype == 'task':
                        @pdf.font_size(6) do
                            @pdf.text parent_story.subject
                        end
                    else
                        @pdf.font_size(6) do
                            if issue.fixed_version
                                @pdf.text issue.fixed_version.name
                            else
                                @pdf.text l(:backlogs_product_backlog)
                            end
                        end
                    end

                    @pdf.text issue.subject

                    # sprint name
                    # tracker
                    # subject
                    # category
                    # assigned_to ?
                    # author ?
                    # estimated_hours
                    # position
                    # points
                end
            end
        end
    end

    def add(story, add_tasks = true)
        if add_tasks
            if story.is_task?
                card(story, 'task')
            else
                story.descendants.each {|task|
                    card(task, 'task')
                }
            end
        end

        card(story, 'story')
    end

    def topts(m)
        return nil if m.class == NilClass
        return Integer(m[0..-3]).mm if m =~ /mm$/
        return Integer(m[0..-3]).cm if m =~ /cm$/
        return Integer(m[0..-3]).in if m =~ /in$/
        return Integer(m[0..-3]).pt if m =~ /pt$/
        return Integer(m)
    end

    def top_left(row, col)
        top = @paper_height - (@top_margin + @vertical_pitch * (row - 1))
        left = @left_margin + (@horizontal_pitch * (col - 1))
        return [left, top]
    end
end

module CodeRay
module Encoders

  class HTML

    module Output

      def numerize *args
        clone.numerize!(*args)
      end

=begin      NUMERIZABLE_WRAPPINGS = {
        :table => [:div, :page, nil],
        :inline => :all,
        :list => [:div, :page, nil]
      }
      NUMERIZABLE_WRAPPINGS.default = :all
=end
      def numerize! mode = :table, options = {}
        return self unless mode

        options = DEFAULT_OPTIONS.merge options

        start = options[:line_number_start]
        unless start.is_a? Integer
          raise ArgumentError, "Invalid value %p for :line_number_start; Integer expected." % start
        end

        #allowed_wrappings = NUMERIZABLE_WRAPPINGS[mode]
        #unless allowed_wrappings == :all or allowed_wrappings.include? options[:wrap]
        #  raise ArgumentError, "Can't numerize, :wrap must be in %p, but is %p" % [NUMERIZABLE_WRAPPINGS, options[:wrap]]
        #end

        bold_every = options[:bold_every]
        highlight_lines = options[:highlight_lines]
        bolding =
          if bold_every == false && highlight_lines == nil
            proc { |line| line.to_s }
          elsif highlight_lines.is_a? Enumerable
            highlight_lines = highlight_lines.to_set
            proc do |line|
              if highlight_lines.include? line
                "<strong class=\"highlighted\">#{line}</strong>"  # highlighted line numbers in bold
              else
                line.to_s
              end
            end
          elsif bold_every.is_a? Integer
            raise ArgumentError, ":bolding can't be 0." if bold_every == 0
            proc do |line|
              if line % bold_every == 0
                "<strong>#{line}</strong>"  # every bold_every-th number in bold
              else
                line.to_s
              end
            end
          else
            raise ArgumentError, 'Invalid value %p for :bolding; false or Integer expected.' % bold_every
          end

        case mode
        when :inline
          max_width = (start + line_count).to_s.size
          line_number = start
          gsub!(/^/) do
            line_number_text = bolding.call line_number
            indent = ' ' * (max_width - line_number.to_s.size)  # TODO: Optimize (10^x)
            res = "<span class=\"no\">#{indent}#{line_number_text}</span> "
            line_number += 1
            res
          end

        when :table
          # This is really ugly.
          # Because even monospace fonts seem to have different heights when bold,
          # I make the newline bold, both in the code and the line numbers.
          # FIXME Still not working perfect for Mr. Internet Exploder
          line_numbers = (start ... start + line_count).to_a.map(&bolding).join("\n")
          line_numbers << "\n"  # also for Mr. MS Internet Exploder :-/
          line_numbers.gsub!(/\n/) { "<tt>\n</tt>" }

          line_numbers_table_tpl = TABLE.apply('LINE_NUMBERS', line_numbers)
          gsub!("</div>\n", '</div>')
          gsub!("\n", "<tt>\n</tt>")
          wrap_in! line_numbers_table_tpl
          @wrapped_in = :div

        when :list
          opened_tags = []
          gsub!(/^.*$\n?/) do |line|
            line.chomp!

            open = opened_tags.join
            line.scan(%r!<(/)?span[^>]*>?!) do |close,|
              if close
                opened_tags.pop
              else
                opened_tags << $&
              end
            end
            close = '</span>' * opened_tags.size

            "<li>#{open}#{line}#{close}</li>\n"
          end
          chomp!("\n")
          wrap_in! LIST
          @wrapped_in = :div

        else
          raise ArgumentError, 'Unknown value %p for mode: expected one of %p' %
            [mode, [:table, :list, :inline]]
        end

        self
      end

      def line_count
        line_count = count("\n")
        position_of_last_newline = rindex(?\n)
        if position_of_last_newline
          after_last_newline = self[position_of_last_newline + 1 .. -1]
          ends_with_newline = after_last_newline[/\A(?:<\/span>)*\z/]
          line_count += 1 if not ends_with_newline
        end
        line_count
      end

    end

  end

end
end

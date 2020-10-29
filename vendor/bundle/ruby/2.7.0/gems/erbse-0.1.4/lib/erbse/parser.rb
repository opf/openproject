module Erbse
  class Parser
    # ERB_EXPR = /(\n)|<%(=|\#)?(.*?)%>(\n)*/m # this is the desired pattern.
    ERB_EXPR = /(\n)|<=|<%(=+|-|\#|@\s|%)?(.*?)[-=]?%>/m # this is for backward-compatibility.
    # BLOCK_EXPR     = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/
    BLOCK_EXPR = /\sdo\s*\z|\sdo\s+\|[^|]*\|\s*\z/
    BLOCK_EXEC = /\A\s*(if|unless)\b|#{BLOCK_EXPR}/

    # Parsing patterns
    #
    # Blocks will be recognized when written:
    # <% ... do %> or <% ... do |...| %>

    def initialize(*)
    end

    def call(str)
      pos = 0
      buffers = []
      result = [:multi]
      buffers << result
      match = nil

      str.scan(ERB_EXPR) do |newline, indicator, code|
        match = Regexp.last_match
        len  = match.begin(0) - pos

        text = str[pos, len]
        pos  = match.end(0)
        ch   = indicator ? indicator[0] : nil

        if newline
          buffers.last << [:static, "#{text}\n"] << [:newline]
          next
        end

        if text and !text.empty? # text
          buffers.last << [:static, text]
        end

        if ch == ?= # <%= %>
          if code =~ BLOCK_EXPR
            buffers.last << [:erb, :block, code, block = [:multi]] # picked up by our own BlockFilter.
            buffers << block
          else
            buffers.last << [:dynamic, code]
          end
        elsif ch =~ /#/ # DISCUSS: doesn't catch <% # this %>
          newlines = code.count("\n")
          buffers.last.concat  [[:newline]] * newlines if newlines > 0
        elsif code =~ /\bend\b/ # <% end %>
          buffers.pop
        elsif ch == ?@
          buffers.last << [:capture, :block, code, block = [:multi]] # picked up by our own BlockFilter. # TODO: merge with %= ?
          buffers << block
        else # <% %>
          if code =~ BLOCK_EXEC
            buffers.last << [:block, code, block = [:multi]] # picked up by Temple's ControlFlow filter.
            buffers << block
          else
            buffers.last << [:code, code]
          end
        end
      end

      # add text after last/none ERB tag.
      buffers.last << [:static, str[pos..str.length]] if pos < str.length

      buffers.last
    end
  end
end

#                                vim:ts=4:sw=4:
# = RedCloth - Textile and Markdown Hybrid for Ruby
#
# Homepage::  http://whytheluckystiff.net/ruby/redcloth/
# Author::    why the lucky stiff (http://whytheluckystiff.net/)
# Copyright:: (cc) 2004 why the lucky stiff (and his puppet organizations.)
# License::   BSD
#
# (see http://hobix.com/textile/ for a Textile Reference.)
#
# Based on (and also inspired by) both:
#
# PyTextile: http://diveintomark.org/projects/textile/textile.py.txt
# Textism for PHP: http://www.textism.com/tools/textile/
#
#

# = RedCloth
#
# RedCloth is a Ruby library for converting Textile and/or Markdown
# into HTML.  You can use either format, intermingled or separately.
# You can also extend RedCloth to honor your own custom text stylings.
#
# RedCloth users are encouraged to use Textile if they are generating
# HTML and to use Markdown if others will be viewing the plain text.
#
# == What is Textile?
#
# Textile is a simple formatting style for text
# documents, loosely based on some HTML conventions.
#
# == Sample Textile Text
#
#  h2. This is a title
#
#  h3. This is a subhead
#
#  This is a bit of paragraph.
#
#  bq. This is a blockquote.
#
# = Writing Textile
#
# A Textile document consists of paragraphs.  Paragraphs
# can be specially formatted by adding a small instruction
# to the beginning of the paragraph.
#
#  h[n].   Header of size [n].
#  bq.     Blockquote.
#  #       Numeric list.
#  *       Bulleted list.
#
# == Quick Phrase Modifiers
#
# Quick phrase modifiers are also included, to allow formatting
# of small portions of text within a paragraph.
#
#  \_emphasis\_
#  \_\_italicized\_\_
#  \*strong\*
#  \*\*bold\*\*
#  ??citation??
#  -deleted text-
#  +inserted text+
#  ^superscript^
#  ~subscript~
#  @code@
#  %(classname)span%
#
#  ==notextile== (leave text alone)
#
# == Links
#
# To make a hypertext link, put the link text in "quotation 
# marks" followed immediately by a colon and the URL of the link.
# 
# Optional: text in (parentheses) following the link text, 
# but before the closing quotation mark, will become a Title 
# attribute for the link, visible as a tool tip when a cursor is above it.
# 
# Example:
#
#  "This is a link (This is a title) ":http://www.textism.com
# 
# Will become:
# 
#  <a href="http://www.textism.com" title="This is a title">This is a link</a>
#
# == Images
#
# To insert an image, put the URL for the image inside exclamation marks.
#
# Optional: text that immediately follows the URL in (parentheses) will 
# be used as the Alt text for the image. Images on the web should always 
# have descriptive Alt text for the benefit of readers using non-graphical 
# browsers.
#
# Optional: place a colon followed by a URL immediately after the 
# closing ! to make the image into a link.
# 
# Example:
#
#  !http://www.textism.com/common/textist.gif(Textist)!
#
# Will become:
#
#  <img src="http://www.textism.com/common/textist.gif" alt="Textist" />
#
# With a link:
#
#  !/common/textist.gif(Textist)!:http://textism.com
#
# Will become:
#
#  <a href="http://textism.com"><img src="/common/textist.gif" alt="Textist" /></a>
#
# == Defining Acronyms
#
# HTML allows authors to define acronyms via the tag. The definition appears as a 
# tool tip when a cursor hovers over the acronym. A crucial aid to clear writing, 
# this should be used at least once for each acronym in documents where they appear.
#
# To quickly define an acronym in Textile, place the full text in (parentheses) 
# immediately following the acronym.
# 
# Example:
#
#  ACLU(American Civil Liberties Union)
#
# Will become:
#
#  <acronym title="American Civil Liberties Union">ACLU</acronym>
#
# == Adding Tables
#
# In Textile, simple tables can be added by seperating each column by
# a pipe.
#
#     |a|simple|table|row|
#     |And|Another|table|row|
#
# Attributes are defined by style definitions in parentheses.
#
#     table(border:1px solid black).
#     (background:#ddd;color:red). |{}| | | |
#
# == Using RedCloth
# 
# RedCloth is simply an extension of the String class, which can handle
# Textile formatting.  Use it like a String and output HTML with its
# RedCloth#to_html method.
#
#  doc = RedCloth.new "
#
#  h2. Test document
#
#  Just a simple test."
#
#  puts doc.to_html
#
# By default, RedCloth uses both Textile and Markdown formatting, with
# Textile formatting taking precedence.  If you want to turn off Markdown
# formatting, to boost speed and limit the processor:
#
#  class RedCloth::Textile.new( str )

class RedCloth3 < String

    VERSION = '3.0.4'
    DEFAULT_RULES = [:textile, :markdown]

    #
    # Two accessor for setting security restrictions.
    #
    # This is a nice thing if you're using RedCloth for
    # formatting in public places (e.g. Wikis) where you
    # don't want users to abuse HTML for bad things.
    #
    # If +:filter_html+ is set, HTML which wasn't
    # created by the Textile processor will be escaped.
    #
    # If +:filter_styles+ is set, it will also disable
    # the style markup specifier. ('{color: red}')
    #
    attr_accessor :filter_html, :filter_styles

    #
    # Accessor for toggling hard breaks.
    #
    # If +:hard_breaks+ is set, single newlines will
    # be converted to HTML break tags.  This is the
    # default behavior for traditional RedCloth.
    #
    attr_accessor :hard_breaks

    # Accessor for toggling lite mode.
    #
    # In lite mode, block-level rules are ignored.  This means
    # that tables, paragraphs, lists, and such aren't available.
    # Only the inline markup for bold, italics, entities and so on.
    #
    #   r = RedCloth.new( "And then? She *fell*!", [:lite_mode] )
    #   r.to_html
    #   #=> "And then? She <strong>fell</strong>!"
    #
    attr_accessor :lite_mode

    #
    # Accessor for toggling span caps.
    #
    # Textile places `span' tags around capitalized
    # words by default, but this wreaks havoc on Wikis.
    # If +:no_span_caps+ is set, this will be
    # suppressed.
    #
    attr_accessor :no_span_caps

    #
    # Establishes the markup predence.  Available rules include:
    #
    # == Textile Rules
    #
    # The following textile rules can be set individually.  Or add the complete
    # set of rules with the single :textile rule, which supplies the rule set in
    # the following precedence:
    #
    # refs_textile::          Textile references (i.e. [hobix]http://hobix.com/)
    # block_textile_table::   Textile table block structures
    # block_textile_lists::   Textile list structures
    # block_textile_prefix::  Textile blocks with prefixes (i.e. bq., h2., etc.)
    # inline_textile_image::  Textile inline images
    # inline_textile_link::   Textile inline links
    # inline_textile_span::   Textile inline spans
    # glyphs_textile:: Textile entities (such as em-dashes and smart quotes)
    #
    # == Markdown
    #
    # refs_markdown::         Markdown references (for example: [hobix]: http://hobix.com/)
    # block_markdown_setext:: Markdown setext headers
    # block_markdown_atx::    Markdown atx headers
    # block_markdown_rule::   Markdown horizontal rules
    # block_markdown_bq::     Markdown blockquotes
    # block_markdown_lists::  Markdown lists
    # inline_markdown_link::  Markdown links
    attr_accessor :rules

    # Returns a new RedCloth object, based on _string_ and
    # enforcing all the included _restrictions_.
    #
    #   r = RedCloth.new( "h1. A <b>bold</b> man", [:filter_html] )
    #   r.to_html
    #     #=>"<h1>A &lt;b&gt;bold&lt;/b&gt; man</h1>"
    #
    def initialize( string, restrictions = [] )
        restrictions.each { |r| method( "#{ r }=" ).call( true ) }
        super( string )
    end

    #
    # Generates HTML from the Textile contents.
    #
    #   r = RedCloth.new( "And then? She *fell*!" )
    #   r.to_html( true )
    #     #=>"And then? She <strong>fell</strong>!"
    #
    def to_html( *rules )
        rules = DEFAULT_RULES if rules.empty?
        # make our working copy
        text = self.dup
        
        @urlrefs = {}
        @shelf = []
        textile_rules = [:refs_textile, :block_textile_table, :block_textile_lists,
                         :block_textile_prefix, :inline_textile_image, :inline_textile_link,
                         :inline_textile_code, :inline_textile_span, :glyphs_textile]
        markdown_rules = [:refs_markdown, :block_markdown_setext, :block_markdown_atx, :block_markdown_rule,
                          :block_markdown_bq, :block_markdown_lists, 
                          :inline_markdown_reflink, :inline_markdown_link]
        @rules = rules.collect do |rule|
            case rule
            when :markdown
                markdown_rules
            when :textile
                textile_rules
            else
                rule
            end
        end.flatten

        # standard clean up
        incoming_entities text 
        clean_white_space text 

        # start processor
        @pre_list = []
        rip_offtags text
        no_textile text
        escape_html_tags text
        hard_break text 
        unless @lite_mode
            refs text
            # need to do this before text is split by #blocks
            block_textile_quotes text
            blocks text
        end
        inline text
        smooth_offtags text

        retrieve text

        text.gsub!( /<\/?notextile>/, '' )
        text.gsub!( /x%x%/, '&#38;' )
        clean_html text if filter_html
        text.strip!
        text

    end

    #######
    private
    #######
    #
    # Mapping of 8-bit ASCII codes to HTML numerical entity equivalents.
    # (from PyTextile)
    #
    TEXTILE_TAGS =

        [[128, 8364], [129, 0], [130, 8218], [131, 402], [132, 8222], [133, 8230], 
         [134, 8224], [135, 8225], [136, 710], [137, 8240], [138, 352], [139, 8249], 
         [140, 338], [141, 0], [142, 0], [143, 0], [144, 0], [145, 8216], [146, 8217], 
         [147, 8220], [148, 8221], [149, 8226], [150, 8211], [151, 8212], [152, 732], 
         [153, 8482], [154, 353], [155, 8250], [156, 339], [157, 0], [158, 0], [159, 376]].

        collect! do |a, b|
            [a.chr, ( b.zero? and "" or "&#{ b };" )]
        end

    #
    # Regular expressions to convert to HTML.
    #
    A_HLGN = /(?:(?:<>|<|>|\=|[()]+)+)/
    A_VLGN = /[\-^~]/
    C_CLAS = '(?:\([^)]+\))'
    C_LNGE = '(?:\[[^\[\]]+\])'
    C_STYL = '(?:\{[^}]+\})'
    S_CSPN = '(?:\\\\\d+)'
    S_RSPN = '(?:/\d+)'
    A = "(?:#{A_HLGN}?#{A_VLGN}?|#{A_VLGN}?#{A_HLGN}?)"
    S = "(?:#{S_CSPN}?#{S_RSPN}|#{S_RSPN}?#{S_CSPN}?)"
    C = "(?:#{C_CLAS}?#{C_STYL}?#{C_LNGE}?|#{C_STYL}?#{C_LNGE}?#{C_CLAS}?|#{C_LNGE}?#{C_STYL}?#{C_CLAS}?)"
    # PUNCT = Regexp::quote( '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~' )
    PUNCT = Regexp::quote( '!"#$%&\'*+,-./:;=?@\\^_`|~' )
    PUNCT_NOQ = Regexp::quote( '!"#$&\',./:;=?@\\`|' )
    PUNCT_Q = Regexp::quote( '*-_+^~%' )
    HYPERLINK = '(\S+?)([^\w\s/;=\?]*?)(?=\s|<|$)'

    # Text markup tags, don't conflict with block tags
    SIMPLE_HTML_TAGS = [
        'tt', 'b', 'i', 'big', 'small', 'em', 'strong', 'dfn', 'code', 
        'samp', 'kbd', 'var', 'cite', 'abbr', 'acronym', 'a', 'img', 'br',
        'br', 'map', 'q', 'sub', 'sup', 'span', 'bdo'
    ]

    QTAGS = [
        ['**', 'b', :limit],
        ['*', 'strong', :limit],
        ['??', 'cite', :limit],
        ['-', 'del', :limit],
        ['__', 'i', :limit],
        ['_', 'em', :limit],
        ['%', 'span', :limit],
        ['+', 'ins', :limit],
        ['^', 'sup', :limit],
        ['~', 'sub', :limit]
    ] 
    QTAGS.collect! do |rc, ht, rtype|
        rcq = Regexp::quote rc
        re =
            case rtype
            when :limit
                /(^|[>\s\(])
                (#{rcq})
                (#{C})
                (?::(\S+?))?
                ([^\s\-].*?[^\s\-]|\w)
                #{rcq}
                (?=[[:punct:]]|\s|\)|$)/x
            else
                /(#{rcq})
                (#{C})
                (?::(\S+))?
                ([^\s\-].*?[^\s\-]|\w)
                #{rcq}/xm 
            end
        [rc, ht, re, rtype]
    end

    # Elements to handle
    GLYPHS = [
    #   [ /([^\s\[{(>])?\'([dmst]\b|ll\b|ve\b|\s|:|$)/, '\1&#8217;\2' ], # single closing
    #   [ /([^\s\[{(>#{PUNCT_Q}][#{PUNCT_Q}]*)\'/, '\1&#8217;' ], # single closing
    #   [ /\'(?=[#{PUNCT_Q}]*(s\b|[\s#{PUNCT_NOQ}]))/, '&#8217;' ], # single closing
    #   [ /\'/, '&#8216;' ], # single opening
    #   [ /</, '&lt;' ], # less-than
    #   [ />/, '&gt;' ], # greater-than
    #   [ /([^\s\[{(])?"(\s|:|$)/, '\1&#8221;\2' ], # double closing
    #   [ /([^\s\[{(>#{PUNCT_Q}][#{PUNCT_Q}]*)"/, '\1&#8221;' ], # double closing
    #   [ /"(?=[#{PUNCT_Q}]*[\s#{PUNCT_NOQ}])/, '&#8221;' ], # double closing
    #   [ /"/, '&#8220;' ], # double opening
    #   [ /\b( )?\.{3}/, '\1&#8230;' ], # ellipsis
    #   [ /\b([A-Z][A-Z0-9]{2,})\b(?:[(]([^)]*)[)])/, '<acronym title="\2">\1</acronym>' ], # 3+ uppercase acronym
    #   [ /(^|[^"][>\s])([A-Z][A-Z0-9 ]+[A-Z0-9])([^<A-Za-z0-9]|$)/, '\1<span class="caps">\2</span>\3', :no_span_caps ], # 3+ uppercase caps
    #   [ /(\.\s)?\s?--\s?/, '\1&#8212;' ], # em dash
    #   [ /\s->\s/, ' &rarr; ' ], # right arrow
    #   [ /\s-\s/, ' &#8211; ' ], # en dash
    #   [ /(\d+) ?x ?(\d+)/, '\1&#215;\2' ], # dimension sign
    #   [ /\b ?[(\[]TM[\])]/i, '&#8482;' ], # trademark
    #   [ /\b ?[(\[]R[\])]/i, '&#174;' ], # registered
    #   [ /\b ?[(\[]C[\])]/i, '&#169;' ] # copyright
    ]

    H_ALGN_VALS = {
        '<' => 'left',
        '=' => 'center',
        '>' => 'right',
        '<>' => 'justify'
    }

    V_ALGN_VALS = {
        '^' => 'top',
        '-' => 'middle',
        '~' => 'bottom'
    }

    #
    # Flexible HTML escaping
    #
    def htmlesc( str, mode=:Quotes )
      if str
        str.gsub!( '&', '&amp;' )
        str.gsub!( '"', '&quot;' ) if mode != :NoQuotes
        str.gsub!( "'", '&#039;' ) if mode == :Quotes
        str.gsub!( '<', '&lt;')
        str.gsub!( '>', '&gt;')
      end
      str
    end

    # Search and replace for Textile glyphs (quotes, dashes, other symbols)
    def pgl( text )
        #GLYPHS.each do |re, resub, tog|
        #    next if tog and method( tog ).call
        #    text.gsub! re, resub
        #end
        text.gsub!(/\b([A-Z][A-Z0-9]{2,})\b(?:[(]([^)]*)[)])/) do |m|
          "<acronym title=\"#{htmlesc $2}\">#{$1}</acronym>"
        end
    end

    # Parses Textile attribute lists and builds an HTML attribute string
    def pba( text_in, element = "" )
        
        return '' unless text_in

        style = []
        text = text_in.dup
        if element == 'td'
            colspan = $1 if text =~ /\\(\d+)/
            rowspan = $1 if text =~ /\/(\d+)/
            style << "vertical-align:#{ v_align( $& ) };" if text =~ A_VLGN
        end

        style << "#{ htmlesc $1 };" if not filter_styles and
            text.sub!( /\{([^}]*)\}/, '' )

        lang = $1 if
            text.sub!( /\[([^)]+?)\]/, '' )

        cls = $1 if
            text.sub!( /\(([^()]+?)\)/, '' )
                        
        style << "padding-left:#{ $1.length }em;" if
            text.sub!( /([(]+)/, '' )

        style << "padding-right:#{ $1.length }em;" if text.sub!( /([)]+)/, '' )

        style << "text-align:#{ h_align( $& ) };" if text =~ A_HLGN

        cls, id = $1, $2 if cls =~ /^(.*?)#(.*)$/
        
        atts = ''
        atts << " style=\"#{ style.join }\"" unless style.empty?
        atts << " class=\"#{ cls }\"" unless cls.to_s.empty?
        atts << " lang=\"#{ lang }\"" if lang
        atts << " id=\"#{ id }\"" if id
        atts << " colspan=\"#{ colspan }\"" if colspan
        atts << " rowspan=\"#{ rowspan }\"" if rowspan
        
        atts
    end

    TABLE_RE = /^(?:table(_?#{S}#{A}#{C})\. ?\n)?^(#{A}#{C}\.? ?\|.*?\|)(\n\n|\Z)/m
    
    # Parses a Textile table block, building HTML from the result.
    def block_textile_table( text ) 
        text.gsub!( TABLE_RE ) do |matches|

            tatts, fullrow = $~[1..2]
            tatts = pba( tatts, 'table' )
            tatts = shelve( tatts ) if tatts
            rows = []

            fullrow.each_line do |row|
                ratts, row = pba( $1, 'tr' ), $2 if row =~ /^(#{A}#{C}\. )(.*)/m
                cells = []
                row.split( /(\|)(?![^\[\|]*\]\])/ )[1..-2].each do |cell|
                    next if cell == '|'
                    ctyp = 'd'
                    ctyp = 'h' if cell =~ /^_/

                    catts = ''
                    catts, cell = pba( $1, 'td' ), $2 if cell =~ /^(_?#{S}#{A}#{C}\. ?)(.*)/

                    catts = shelve( catts ) if catts
                    cells << "\t\t\t<t#{ ctyp }#{ catts }>#{ cell }</t#{ ctyp }>" 
                end
                ratts = shelve( ratts ) if ratts
                rows << "\t\t<tr#{ ratts }>\n#{ cells.join( "\n" ) }\n\t\t</tr>"
            end
            "\t<table#{ tatts }>\n#{ rows.join( "\n" ) }\n\t</table>\n\n"
        end
    end

    LISTS_RE = /^([#*]+?#{C} .*?)$(?![^#*])/m
    LISTS_CONTENT_RE = /^([#*]+)(#{A}#{C}) (.*)$/m

    # Parses Textile lists and generates HTML
    def block_textile_lists( text ) 
        text.gsub!( LISTS_RE ) do |match|
            lines = match.split( /\n/ )
            last_line = -1
            depth = []
            lines.each_with_index do |line, line_id|
                if line =~ LISTS_CONTENT_RE 
                    tl,atts,content = $~[1..3]
                    if depth.last
                        if depth.last.length > tl.length
                            (depth.length - 1).downto(0) do |i|
                                break if depth[i].length == tl.length
                                lines[line_id - 1] << "</li>\n\t</#{ lT( depth[i] ) }l>\n\t"
                                depth.pop
                            end
                        end
                        if depth.last and depth.last.length == tl.length
                            lines[line_id - 1] << '</li>'
                        end
                    end
                    unless depth.last == tl
                        depth << tl
                        atts = pba( atts )
                        atts = shelve( atts ) if atts
                        lines[line_id] = "\t<#{ lT(tl) }l#{ atts }>\n\t<li>#{ content }"
                    else
                        lines[line_id] = "\t\t<li>#{ content }"
                    end
                    last_line = line_id

                else
                    last_line = line_id
                end
                if line_id - last_line > 1 or line_id == lines.length - 1
                    depth.delete_if do |v|
                        lines[last_line] << "</li>\n\t</#{ lT( v ) }l>"
                    end
                end
            end
            lines.join( "\n" )
        end
    end
    
    QUOTES_RE = /(^>+([^\n]*?)\n?)+/m
    QUOTES_CONTENT_RE = /^([> ]+)(.*)$/m
    
    def block_textile_quotes( text )
      text.gsub!( QUOTES_RE ) do |match|
        lines = match.split( /\n/ )
        quotes = ''
        indent = 0
        lines.each do |line|
          line =~ QUOTES_CONTENT_RE 
          bq,content = $1, $2
          l = bq.count('>')
          if l != indent
            quotes << ("\n\n" + (l>indent ? '<blockquote>' * (l-indent) : '</blockquote>' * (indent-l)) + "\n\n")
            indent = l
          end
          quotes << (content + "\n")
        end
        quotes << ("\n" + '</blockquote>' * indent + "\n\n")
        quotes
      end
    end

    CODE_RE = /(\W)
        @
        (?:\|(\w+?)\|)?
        (.+?)
        @
        (?=\W)/x

    def inline_textile_code( text ) 
        text.gsub!( CODE_RE ) do |m|
            before,lang,code,after = $~[1..4]
            lang = " lang=\"#{ lang }\"" if lang
            rip_offtags( "#{ before }<code#{ lang }>#{ code }</code>#{ after }" )
        end
    end

    def lT( text ) 
        text =~ /\#$/ ? 'o' : 'u'
    end

    def hard_break( text )
        text.gsub!( /(.)\n(?!\Z| *([#*=]+(\s|$)|[{|]))/, "\\1<br />" ) if hard_breaks
    end

    BLOCKS_GROUP_RE = /\n{2,}(?! )/m

    def blocks( text, deep_code = false )
        text.replace( text.split( BLOCKS_GROUP_RE ).collect do |blk|
            plain = blk !~ /\A[#*> ]/

            # skip blocks that are complex HTML
            if blk =~ /^<\/?(\w+).*>/ and not SIMPLE_HTML_TAGS.include? $1
                blk
            else
                # search for indentation levels
                blk.strip!
                if blk.empty?
                    blk
                else
                    code_blk = nil
                    blk.gsub!( /((?:\n(?:\n^ +[^\n]*)+)+)/m ) do |iblk|
                        flush_left iblk
                        blocks iblk, plain
                        iblk.gsub( /^(\S)/, "\t\\1" )
                        if plain
                            code_blk = iblk; ""
                        else
                            iblk
                        end
                    end

                    block_applied = 0 
                    @rules.each do |rule_name|
                        block_applied += 1 if ( rule_name.to_s.match /^block_/ and method( rule_name ).call( blk ) )
                    end
                    if block_applied.zero?
                        if deep_code
                            blk = "\t<pre><code>#{ blk }</code></pre>"
                        else
                            blk = "\t<p>#{ blk }</p>"
                        end
                    end
                    # hard_break blk
                    blk + "\n#{ code_blk }"
                end
            end

        end.join( "\n\n" ) )
    end

    def textile_bq( tag, atts, cite, content )
        cite, cite_title = check_refs( cite )
        cite = " cite=\"#{ cite }\"" if cite
        atts = shelve( atts ) if atts
        "\t<blockquote#{ cite }>\n\t\t<p#{ atts }>#{ content }</p>\n\t</blockquote>"
    end

    def textile_p( tag, atts, cite, content )
        atts = shelve( atts ) if atts
        "\t<#{ tag }#{ atts }>#{ content }</#{ tag }>"
    end

    alias textile_h1 textile_p
    alias textile_h2 textile_p
    alias textile_h3 textile_p
    alias textile_h4 textile_p
    alias textile_h5 textile_p
    alias textile_h6 textile_p

    def textile_fn_( tag, num, atts, cite, content )
        atts << " id=\"fn#{ num }\" class=\"footnote\""
        content = "<sup>#{ num }</sup> #{ content }"
        atts = shelve( atts ) if atts
        "\t<p#{ atts }>#{ content }</p>"
    end

    BLOCK_RE = /^(([a-z]+)(\d*))(#{A}#{C})\.(?::(\S+))? (.*)$/m

    def block_textile_prefix( text ) 
        if text =~ BLOCK_RE
            tag,tagpre,num,atts,cite,content = $~[1..6]
            atts = pba( atts )

            # pass to prefix handler
            if respond_to? "textile_#{ tag }", true
                text.gsub!( $&, method( "textile_#{ tag }" ).call( tag, atts, cite, content ) )
            elsif respond_to? "textile_#{ tagpre }_", true
                text.gsub!( $&, method( "textile_#{ tagpre }_" ).call( tagpre, num, atts, cite, content ) )
            end
        end
    end
    
    SETEXT_RE = /\A(.+?)\n([=-])[=-]* *$/m
    def block_markdown_setext( text )
        if text =~ SETEXT_RE
            tag = if $2 == "="; "h1"; else; "h2"; end
            blk, cont = "<#{ tag }>#{ $1 }</#{ tag }>", $'
            blocks cont
            text.replace( blk + cont )
        end
    end

    ATX_RE = /\A(\#{1,6})  # $1 = string of #'s
              [ ]*
              (.+?)       # $2 = Header text
              [ ]*
              \#*         # optional closing #'s (not counted)
              $/x
    def block_markdown_atx( text )
        if text =~ ATX_RE
            tag = "h#{ $1.length }"
            blk, cont = "<#{ tag }>#{ $2 }</#{ tag }>\n\n", $'
            blocks cont
            text.replace( blk + cont )
        end
    end

    MARKDOWN_BQ_RE = /\A(^ *> ?.+$(.+\n)*\n*)+/m

    def block_markdown_bq( text )
        text.gsub!( MARKDOWN_BQ_RE ) do |blk|
            blk.gsub!( /^ *> ?/, '' )
            flush_left blk
            blocks blk
            blk.gsub!( /^(\S)/, "\t\\1" )
            "<blockquote>\n#{ blk }\n</blockquote>\n\n"
        end
    end

    MARKDOWN_RULE_RE = /^(#{
        ['*', '-', '_'].collect { |ch| ' ?(' + Regexp::quote( ch ) + ' ?){3,}' }.join( '|' )
    })$/

    def block_markdown_rule( text )
        text.gsub!( MARKDOWN_RULE_RE ) do |blk|
            "<hr />"
        end
    end

    # XXX TODO XXX
    def block_markdown_lists( text )
    end

    def inline_textile_span( text ) 
        QTAGS.each do |qtag_rc, ht, qtag_re, rtype|
            text.gsub!( qtag_re ) do |m|
             
                case rtype
                when :limit
                    sta,qtag,atts,cite,content = $~[1..5]
                else
                    qtag,atts,cite,content = $~[1..4]
                    sta = ''
                end
                atts = pba( atts )
                atts << " cite=\"#{ cite }\"" if cite
                atts = shelve( atts ) if atts

                "#{ sta }<#{ ht }#{ atts }>#{ content }</#{ ht }>"

            end
        end
    end

    LINK_RE = /
            ([\s\[{(]|[#{PUNCT}])?     # $pre
            "                          # start
            (#{C})                     # $atts
            ([^"\n]+?)                 # $text
            \s?
            (?:\(([^)]+?)\)(?="))?     # $title
            ":
            ([\w\/]\S+?)               # $url
            (\/)?                      # $slash
            ([^\w\=\/;\(\)]*?)         # $post
            (?=<|\s|$)
        /x 
#"
    def inline_textile_link( text ) 
        text.gsub!( LINK_RE ) do |m|
            pre,atts,text,title,url,slash,post = $~[1..7]

            url, url_title = check_refs( url )
            title ||= url_title
            
            # Idea below : an URL with unbalanced parethesis and
            # ending by ')' is put into external parenthesis
            if ( url[-1]==?) and ((url.count("(") - url.count(")")) < 0 ) )
              url=url[0..-2] # discard closing parenth from url
              post = ")"+post # add closing parenth to post
            end
            atts = pba( atts )
            atts = " href=\"#{ url }#{ slash }\"#{ atts }"
            atts << " title=\"#{ htmlesc title }\"" if title
            atts = shelve( atts ) if atts
            
            external = (url =~ /^https?:\/\//) ? ' class="external"' : ''
            
            "#{ pre }<a#{ atts }#{ external }>#{ text }</a>#{ post }"
        end
    end

    MARKDOWN_REFLINK_RE = /
            \[([^\[\]]+)\]      # $text
            [ ]?                # opt. space
            (?:\n[ ]*)?         # one optional newline followed by spaces
            \[(.*?)\]           # $id
        /x 

    def inline_markdown_reflink( text ) 
        text.gsub!( MARKDOWN_REFLINK_RE ) do |m|
            text, id = $~[1..2]

            if id.empty?
                url, title = check_refs( text )
            else
                url, title = check_refs( id )
            end
            
            atts = " href=\"#{ url }\""
            atts << " title=\"#{ title }\"" if title
            atts = shelve( atts )
            
            "<a#{ atts }>#{ text }</a>"
        end
    end

    MARKDOWN_LINK_RE = /
            \[([^\[\]]+)\]      # $text
            \(                  # open paren
            [ \t]*              # opt space
            <?(.+?)>?           # $href
            [ \t]*              # opt space
            (?:                 # whole title
            (['"])              # $quote
            (.*?)               # $title
            \3                  # matching quote
            )?                  # title is optional
            \)
        /x 

    def inline_markdown_link( text ) 
        text.gsub!( MARKDOWN_LINK_RE ) do |m|
            text, url, quote, title = $~[1..4]

            atts = " href=\"#{ url }\""
            atts << " title=\"#{ title }\"" if title
            atts = shelve( atts )
            
            "<a#{ atts }>#{ text }</a>"
        end
    end

    TEXTILE_REFS_RE =  /(^ *)\[([^\[\n]+?)\](#{HYPERLINK})(?=\s|$)/
    MARKDOWN_REFS_RE = /(^ *)\[([^\n]+?)\]:\s+<?(#{HYPERLINK})>?(?:\s+"((?:[^"]|\\")+)")?(?=\s|$)/m

    def refs( text )
        @rules.each do |rule_name|
            method( rule_name ).call( text ) if rule_name.to_s.match /^refs_/
        end
    end

    def refs_textile( text ) 
        text.gsub!( TEXTILE_REFS_RE ) do |m|
            flag, url = $~[2..3]
            @urlrefs[flag.downcase] = [url, nil]
            nil
        end
    end
    
    def refs_markdown( text )
        text.gsub!( MARKDOWN_REFS_RE ) do |m|
            flag, url = $~[2..3]
            title = $~[6]
            @urlrefs[flag.downcase] = [url, title]
            nil
        end
    end

    def check_refs( text ) 
        ret = @urlrefs[text.downcase] if text
        ret || [text, nil]
    end

    IMAGE_RE = /
            (<p>|.|^)            # start of line?
            \!                   # opening
            (\<|\=|\>)?          # optional alignment atts
            (#{C})               # optional style,class atts
            (?:\. )?             # optional dot-space
            ([^\s(!]+?)          # presume this is the src
            \s?                  # optional space
            (?:\(((?:[^\(\)]|\([^\)]+\))+?)\))?   # optional title
            \!                   # closing
            (?::#{ HYPERLINK })? # optional href
        /x 

    def inline_textile_image( text ) 
        text.gsub!( IMAGE_RE )  do |m|
            stln,algn,atts,url,title,href,href_a1,href_a2 = $~[1..8]
            htmlesc title
            atts = pba( atts )
            atts = " src=\"#{ url }\"#{ atts }"
            atts << " title=\"#{ title }\"" if title
            atts << " alt=\"#{ title }\"" 
            # size = @getimagesize($url);
            # if($size) $atts.= " $size[3]";

            href, alt_title = check_refs( href ) if href
            url, url_title = check_refs( url )

            out = ''
            out << "<a#{ shelve( " href=\"#{ href }\"" ) }>" if href
            out << "<img#{ shelve( atts ) } />"
            out << "</a>#{ href_a1 }#{ href_a2 }" if href
            
            if algn 
                algn = h_align( algn )
                if stln == "<p>"
                    out = "<p style=\"float:#{ algn }\">#{ out }"
                else
                    out = "#{ stln }<div style=\"float:#{ algn }\">#{ out }</div>"
                end
            else
                out = stln + out
            end

            out
        end
    end

    def shelve( val ) 
        @shelf << val
        " :redsh##{ @shelf.length }:"
    end
    
    def retrieve( text ) 
        @shelf.each_with_index do |r, i|
            text.gsub!( " :redsh##{ i + 1 }:", r )
        end
    end

    def incoming_entities( text ) 
        ## turn any incoming ampersands into a dummy character for now.
        ## This uses a negative lookahead for alphanumerics followed by a semicolon,
        ## implying an incoming html entity, to be skipped

        text.gsub!( /&(?![#a-z0-9]+;)/i, "x%x%" )
    end

    def no_textile( text ) 
        text.gsub!( /(^|\s)==([^=]+.*?)==(\s|$)?/,
            '\1<notextile>\2</notextile>\3' )
        text.gsub!( /^ *==([^=]+.*?)==/m,
            '\1<notextile>\2</notextile>\3' )
    end

    def clean_white_space( text ) 
        # normalize line breaks
        text.gsub!( /\r\n/, "\n" )
        text.gsub!( /\r/, "\n" )
        text.gsub!( /\t/, '    ' )
        text.gsub!( /^ +$/, '' )
        text.gsub!( /\n{3,}/, "\n\n" )
        text.gsub!( /"$/, "\" " )

        # if entire document is indented, flush
        # to the left side
        flush_left text
    end

    def flush_left( text )
        indt = 0
        if text =~ /^ /
            while text !~ /^ {#{indt}}\S/
                indt += 1
            end unless text.empty?
            if indt.nonzero?
                text.gsub!( /^ {#{indt}}/, '' )
            end
        end
    end

    def footnote_ref( text ) 
        text.gsub!( /\b\[([0-9]+?)\](\s)?/,
            '<sup><a href="#fn\1">\1</a></sup>\2' )
    end
    
    OFFTAGS = /(code|pre|kbd|notextile)/
    OFFTAG_MATCH = /(?:(<\/#{ OFFTAGS }>)|(<#{ OFFTAGS }[^>]*>))(.*?)(?=<\/?#{ OFFTAGS }|\Z)/mi
    OFFTAG_OPEN = /<#{ OFFTAGS }/
    OFFTAG_CLOSE = /<\/?#{ OFFTAGS }/
    HASTAG_MATCH = /(<\/?\w[^\n]*?>)/m
    ALLTAG_MATCH = /(<\/?\w[^\n]*?>)|.*?(?=<\/?\w[^\n]*?>|$)/m

    def glyphs_textile( text, level = 0 )
        if text !~ HASTAG_MATCH
            pgl text
            footnote_ref text
        else
            codepre = 0
            text.gsub!( ALLTAG_MATCH ) do |line|
                ## matches are off if we're between <code>, <pre> etc.
                if $1
                    if line =~ OFFTAG_OPEN
                        codepre += 1
                    elsif line =~ OFFTAG_CLOSE
                        codepre -= 1
                        codepre = 0 if codepre < 0
                    end 
                elsif codepre.zero?
                    glyphs_textile( line, level + 1 )
                else
                    htmlesc( line, :NoQuotes )
                end
                # p [level, codepre, line]

                line
            end
        end
    end

    def rip_offtags( text )
        if text =~ /<.*>/
            ## strip and encode <pre> content
            codepre, used_offtags = 0, {}
            text.gsub!( OFFTAG_MATCH ) do |line|
                if $3
                    offtag, aftertag = $4, $5
                    codepre += 1
                    used_offtags[offtag] = true
                    if codepre - used_offtags.length > 0
                        htmlesc( line, :NoQuotes )
                        @pre_list.last << line
                        line = ""
                    else
                        htmlesc( aftertag, :NoQuotes ) if aftertag
                        line = "<redpre##{ @pre_list.length }>"
                        $3.match(/<#{ OFFTAGS }([^>]*)>/)
                        tag = $1
                        $2.to_s.match(/(class\=\S+)/i)
                        tag << " #{$1}" if $1
                        @pre_list << "<#{ tag }>#{ aftertag }"
                    end
                elsif $1 and codepre > 0
                    if codepre - used_offtags.length > 0
                        htmlesc( line, :NoQuotes )
                        @pre_list.last << line
                        line = ""
                    end
                    codepre -= 1 unless codepre.zero?
                    used_offtags = {} if codepre.zero?
                end 
                line
            end
        end
        text
    end

    def smooth_offtags( text )
        unless @pre_list.empty?
            ## replace <pre> content
            text.gsub!( /<redpre#(\d+)>/ ) { @pre_list[$1.to_i] }
        end
    end

    def inline( text ) 
        [/^inline_/, /^glyphs_/].each do |meth_re|
            @rules.each do |rule_name|
                method( rule_name ).call( text ) if rule_name.to_s.match( meth_re )
            end
        end
    end

    def h_align( text ) 
        H_ALGN_VALS[text]
    end

    def v_align( text ) 
        V_ALGN_VALS[text]
    end

    def textile_popup_help( name, windowW, windowH )
        ' <a target="_blank" href="http://hobix.com/textile/#' + helpvar + '" onclick="window.open(this.href, \'popupwindow\', \'width=' + windowW + ',height=' + windowH + ',scrollbars,resizable\'); return false;">' + name + '</a><br />'
    end

    # HTML cleansing stuff
    BASIC_TAGS = {
        'a' => ['href', 'title'],
        'img' => ['src', 'alt', 'title'],
        'br' => [],
        'i' => nil,
        'u' => nil, 
        'b' => nil,
        'pre' => nil,
        'kbd' => nil,
        'code' => ['lang'],
        'cite' => nil,
        'strong' => nil,
        'em' => nil,
        'ins' => nil,
        'sup' => nil,
        'sub' => nil,
        'del' => nil,
        'table' => nil,
        'tr' => nil,
        'td' => ['colspan', 'rowspan'],
        'th' => nil,
        'ol' => nil,
        'ul' => nil,
        'li' => nil,
        'p' => nil,
        'h1' => nil,
        'h2' => nil,
        'h3' => nil,
        'h4' => nil,
        'h5' => nil,
        'h6' => nil, 
        'blockquote' => ['cite']
    }

    def clean_html( text, tags = BASIC_TAGS )
        text.gsub!( /<!\[CDATA\[/, '' )
        text.gsub!( /<(\/*)(\w+)([^>]*)>/ ) do
            raw = $~
            tag = raw[2].downcase
            if tags.has_key? tag
                pcs = [tag]
                tags[tag].each do |prop|
                    ['"', "'", ''].each do |q|
                        q2 = ( q != '' ? q : '\s' )
                        if raw[3] =~ /#{prop}\s*=\s*#{q}([^#{q2}]+)#{q}/i
                            attrv = $1
                            next if prop == 'src' and attrv =~ %r{^(?!http)\w+:}
                            pcs << "#{prop}=\"#{$1.gsub('"', '\\"')}\""
                            break
                        end
                    end
                end if tags[tag]
                "<#{raw[1]}#{pcs.join " "}>"
            else
                " "
            end
        end
    end
    
    ALLOWED_TAGS = %w(redpre pre code notextile)
    
    def escape_html_tags(text)
      text.gsub!(%r{<(\/?([!\w]+)[^<>\n]*)(>?)}) {|m| ALLOWED_TAGS.include?($2) ? "<#{$1}#{$3}" : "&lt;#{$1}#{'&gt;' unless $3.blank?}" }
    end
end


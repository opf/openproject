
HEADING_RE = /<h(1|2|3|4)( [^>]+)?>(.+?)<\/h(1|2|3|4)>/i unless const_defined?(:HEADING_RE)

# Headings and TOC
# Adds ids and links to headings unless options[:headings] is set to false
def parse_headings(text, _project, _obj, _attr, _only_path, options)
  return if options[:headings] == false

  text.gsub!(HEADING_RE) do
    level = $1.to_i
    attrs = $2
    content = $3
    item = strip_tags(content).strip
    tocitem = strip_tags(content.gsub(/<br \/>/, ' '))
    anchor = item.gsub(%r{[^\w\s\-]}, '').gsub(%r{\s+(\-+\s*)?}, '-')
    @parsed_headings << [level, anchor, tocitem]
    url = full_url(anchor)
    "<a name=\"#{anchor}\"></a>\n<h#{level} #{attrs}>#{content}<a href=\"#{url}\" class=\"wiki-anchor\">&para;</a></h#{level}>"
  end
end

TOC_RE = /<p>\{\{([<>]?)toc\}\}<\/p>/i unless const_defined?(:TOC_RE)

# Renders the TOC with given headings
def replace_toc(text, headings)
  text.gsub!(TOC_RE) do
    if headings.empty?
      ''
    else
      div_class = 'toc'
      div_class << ' right' if $1 == '>'
      div_class << ' left' if $1 == '<'
      out = "<fieldset class='form--fieldset -collapsible'>"
      out << "<legend class='form--fieldset-legend' title='" +
        l(:description_toc_toggle) +
        "' onclick='toggleFieldset(this);'>
            <a href='javascript:'>
              #{l(:label_table_of_contents)}
            </a>
            </legend><div>"
      out << "<ul class=\"#{div_class}\"><li>"
      root = headings.map(&:first).min
      current = root
      started = false
      headings.each do |level, anchor, item|
        if level > current
          out << '<ul><li>' * (level - current)
        elsif level < current
          out << "</li></ul>\n" * (current - level) + '</li><li>'
        elsif started
          out << '</li><li>'
        end
        url = full_url anchor
        out << "<a href=\"#{url}\">#{item}</a>"
        current = level
        started = true
      end
      out << '</li></ul>' * (current - root)
      out << '</li></ul>'
      out << '</div></fieldset>'
    end
  end
end

#
# displays the current url plus an optional anchor
#
def full_url(anchor_name = '')
  return "##{anchor_name}" if current_request.nil?
  current = request.original_fullpath
  return current if anchor_name.blank?
  "#{current}##{anchor_name}"
end

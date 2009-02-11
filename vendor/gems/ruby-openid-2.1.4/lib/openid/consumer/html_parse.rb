require "openid/yadis/htmltokenizer"

module OpenID

  # Stuff to remove before we start looking for tags
  REMOVED_RE = /
    # Comments
    <!--.*?-->

    # CDATA blocks
  | <!\[CDATA\[.*?\]\]>

    # script blocks
  | <script\b

    # make sure script is not an XML namespace
    (?!:)

    [^>]*>.*?<\/script>

  /mixu 

  def OpenID.openid_unescape(s)
    s.gsub('&amp;','&').gsub('&lt;','<').gsub('&gt;','>').gsub('&quot;','"')
  end

  def OpenID.unescape_hash(h)
    newh = {}
    h.map{|k,v|
      newh[k]=openid_unescape(v)
    }
    newh
  end


  def OpenID.parse_link_attrs(html)
    stripped = html.gsub(REMOVED_RE,'')
    parser = HTMLTokenizer.new(stripped)

    links = []
    # to keep track of whether or not we are in the head element
    in_head = false
    in_html = false
    saw_head = false

    begin
      while el = parser.getTag('head', '/head', 'link', 'body', '/body', 
                               'html', '/html')
        
        # we are leaving head or have reached body, so we bail
        return links if ['/head', 'body', '/body', '/html'].member?(el.tag_name)

        # enforce html > head > link
        if el.tag_name == 'html'
          in_html = true
        end
        next unless in_html
        if el.tag_name == 'head'
          if saw_head
            return links #only allow one head
          end
          saw_head = true
          unless el.to_s[-2] == 47 # tag ends with a /: a short tag
            in_head = true
          end
        end
        next unless in_head

        return links if el.tag_name == 'html'

        if el.tag_name == 'link'
          links << unescape_hash(el.attr_hash)
        end
        
      end
    rescue Exception # just stop parsing if there's an error
    end
    return links
  end

  def OpenID.rel_matches(rel_attr, target_rel)
    # Does this target_rel appear in the rel_str?
    # XXX: TESTME
    rels = rel_attr.strip().split()
    rels.each { |rel|
      rel = rel.downcase
      if rel == target_rel
        return true
      end
    }

    return false
  end

  def OpenID.link_has_rel(link_attrs, target_rel)
    # Does this link have target_rel as a relationship?

    # XXX: TESTME
    rel_attr = link_attrs['rel']
    return (rel_attr and rel_matches(rel_attr, target_rel))
  end

  def OpenID.find_links_rel(link_attrs_list, target_rel)
    # Filter the list of link attributes on whether it has target_rel
    # as a relationship.

    # XXX: TESTME
    matchesTarget = lambda { |attrs| link_has_rel(attrs, target_rel) }
    result = []

    link_attrs_list.each { |item|
      if matchesTarget.call(item)
        result << item
      end
    }

    return result
  end

  def OpenID.find_first_href(link_attrs_list, target_rel)
    # Return the value of the href attribute for the first link tag in
    # the list that has target_rel as a relationship.

    # XXX: TESTME
    matches = find_links_rel(link_attrs_list, target_rel)
    if !matches or matches.empty?
      return nil
    end

    first = matches[0]
    return first['href']
  end
end


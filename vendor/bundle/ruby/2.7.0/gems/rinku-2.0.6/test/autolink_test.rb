require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'cgi'
require 'uri'
require 'rinku'

class RinkuAutoLinkTest < Minitest::Test
  def generate_result(link_text, href = nil)
    href ||= link_text
    href = "http://" + href unless href =~ %r{\A(\w+://|mailto:)}
    %{<a href="#{CGI.escapeHTML href}">#{CGI.escapeHTML link_text}</a>}
  end

  def assert_linked(expected, url)
    assert_equal expected, Rinku.auto_link(url)
  end

  def test_segfault
    Rinku.auto_link("a+b@d.com+e@f.com", :all)
  end

  def test_escapes_quotes
    assert_linked %(<a href="http://website.com/&quot;onmouseover=document.body.style.backgroundColor=&quot;pink&quot;;//">http://website.com/"onmouseover=document.body.style.backgroundColor="pink";//</a>),
      %(http://website.com/"onmouseover=document.body.style.backgroundColor="pink";//)
  end

  def test_global_skip_tags
    assert_nil Rinku.skip_tags
    Rinku.skip_tags = ['pre']
    assert_equal Rinku.skip_tags, ['pre']

    Rinku.skip_tags = ['pa']
    url = 'This is just a <pa>http://www.pokemon.com</pa> test'
    assert_equal Rinku.auto_link(url), url

    Rinku.skip_tags = nil
    refute_equal Rinku.auto_link(url), url
  end

  def test_auto_link_with_single_trailing_punctuation_and_space
    url = "http://www.youtube.com"
    url_result = generate_result(url)
    assert_equal url_result, Rinku.auto_link(url)
    ["?", "!", ".", ",", ":"].each do |punc|
      assert_equal "link: #{url_result}#{punc} foo?", Rinku.auto_link("link: #{url}#{punc} foo?")
    end
  end

  def test_terminates_on_ampersand
    url = "http://example.com"
    assert_linked "hello &#39;<a href=\"#{url}\">#{url}</a>&#39; hello", "hello &#39;#{url}&#39; hello"
  end

  def test_does_not_segfault
    assert_linked "< this is just a test", "< this is just a test"
  end

  def test_skips_tags
    html = <<-html
This is just a test. http://www.pokemon.com
<div>
  More test
  http://www.amd.com
</div>
<pre>
  CODE www.less.es
</pre>
    html

    result = <<-result
This is just a test. <a href="http://www.pokemon.com">http://www.pokemon.com</a>
<div>
  More test
  http://www.amd.com
</div>
<pre>
  CODE <a href="http://www.less.es">www.less.es</a>
</pre>
    result
    assert_equal result, Rinku.auto_link(html, :all, nil, ["div", "a"])
  end

  def test_auto_link_with_brackets
    link1_raw = 'http://en.wikipedia.org/wiki/Sprite_(computer_graphics)'
    link1_result = generate_result(link1_raw)
    assert_equal link1_result, Rinku.auto_link(link1_raw)
    assert_equal "(link: #{link1_result})", Rinku.auto_link("(link: #{link1_raw})")

    link2_raw = 'http://en.wikipedia.org/wiki/Sprite_[computer_graphics]'
    link2_result = generate_result(link2_raw)
    assert_equal link2_result, Rinku.auto_link(link2_raw)
    assert_equal "[link: #{link2_result}]", Rinku.auto_link("[link: #{link2_raw}]")

    link3_raw = 'http://en.wikipedia.org/wiki/Sprite_{computer_graphics}'
    link3_result = generate_result(link3_raw)
    assert_equal link3_result, Rinku.auto_link(link3_raw)
    assert_equal "{link: #{link3_result}}", Rinku.auto_link("{link: #{link3_raw}}")
  end

  def test_auto_link_with_multiple_trailing_punctuations
    url = "http://youtube.com"
    url_result = generate_result(url)
    assert_equal url_result, Rinku.auto_link(url)
    assert_equal "(link: #{url_result}).", Rinku.auto_link("(link: #{url}).")
  end

  def test_auto_link_with_block
    url = "http://api.rubyonrails.com/Foo.html"
    email = "fantabulous@shiznadel.ic"

    assert_equal %(<p><a href="#{url}">#{url[0...7]}...</a><br /><a href="mailto:#{email}">#{email[0...7]}...</a><br /></p>), Rinku.auto_link("<p>#{url}<br />#{email}<br /></p>") { |_url| _url[0...7] + '...'}
  end

  def test_auto_link_with_block_with_html
    pic = "http://example.com/pic.png"
    url = "http://example.com/album?a&b=c"

    expect = %(My pic: <a href="#{pic}"><img src="#{pic}" width="160px"></a> -- full album here #{generate_result(url)})
    text = "My pic: #{pic} -- full album here #{CGI.escapeHTML url}"

    assert_equal expect, Rinku.auto_link(text) { |link|
      if link =~ /\.(jpg|gif|png|bmp|tif)$/i
        %(<img src="#{link}" width="160px">)
      else
        link
      end
    }
  end

  def test_auto_link_already_linked
    linked1 = generate_result('Ruby On Rails', 'http://www.rubyonrails.com')
    linked2 = %('<a href="http://www.example.com">www.example.com</a>')
    linked3 = %('<a href="http://www.example.com" rel="nofollow">www.example.com</a>')
    linked4 = %('<a href="http://www.example.com"><b>www.example.com</b></a>')
    linked5 = %('<a href="#close">close</a> <a href="http://www.example.com"><b>www.example.com</b></a>')
    assert_equal linked1, Rinku.auto_link(linked1)
    assert_equal linked2, Rinku.auto_link(linked2)
    assert_equal linked3, Rinku.auto_link(linked3)
    assert_equal linked4, Rinku.auto_link(linked4)
    assert_equal linked5, Rinku.auto_link(linked5)

    linked_email = %Q(<a href="mailto:david@loudthinking.com">Mail me</a>)
    assert_equal linked_email, Rinku.auto_link(linked_email)
  end


  def test_auto_link_at_eol
    url1 = "http://api.rubyonrails.com/Foo.html"
    url2 = "http://www.ruby-doc.org/core/Bar.html"

    assert_equal %(<p><a href="#{url1}">#{url1}</a><br /><a href="#{url2}">#{url2}</a><br /></p>), Rinku.auto_link("<p>#{url1}<br />#{url2}<br /></p>")
  end

  def test_block
    link = Rinku.auto_link("Find ur favorite pokeman @ http://www.pokemon.com") do |url|
      assert_equal url, "http://www.pokemon.com"
      "POKEMAN WEBSITE"
    end

    assert_equal link, "Find ur favorite pokeman @ <a href=\"http://www.pokemon.com\">POKEMAN WEBSITE</a>"
  end

  def test_autolink_works
    url = "http://example.com/"
    assert_linked "<a href=\"#{url}\">#{url}</a>", url
  end

  def test_autolink_options_for_short_domains
    url = "http://google"
    linked_url = "<a href=\"#{url}\">#{url}</a>"
    flags = Rinku::AUTOLINK_SHORT_DOMAINS

    # Specifying use short_domains in the args
    url = "http://google"
    linked_url = "<a href=\"#{url}\">#{url}</a>"
    assert_equal Rinku.auto_link(url, nil, nil, nil, flags), linked_url

    # Specifying no short_domains in the args
    url = "http://google"
    linked_url = "<a href=\"#{url}\">#{url}</a>"
    assert_equal Rinku.auto_link(url, nil, nil, nil, 0), url
  end

  def test_not_autolink_www
    assert_linked "Awww... man", "Awww... man"
  end

  def test_does_not_terminate_on_dash
    url = "http://example.com/Notification_Center-GitHub-20101108-140050.jpg"
    assert_linked "<a href=\"#{url}\">#{url}</a>", url
  end

  def test_does_not_include_trailing_gt
    url = "http://example.com"
    assert_linked "&lt;<a href=\"#{url}\">#{url}</a>&gt;", "&lt;#{url}&gt;"
  end

  def test_links_with_anchors
    url = "https://github.com/github/hubot/blob/master/scripts/cream.js#L20-20"
    assert_linked "<a href=\"#{url}\">#{url}</a>", url
  end

  def test_links_like_rails
    urls = %w(http://www.rubyonrails.com
              http://www.rubyonrails.com:80
              http://www.rubyonrails.com/~minam
              https://www.rubyonrails.com/~minam
              http://www.rubyonrails.com/~minam/url%20with%20spaces
              http://www.rubyonrails.com/foo.cgi?something=here
              http://www.rubyonrails.com/foo.cgi?something=here&and=here
              http://www.rubyonrails.com/contact;new
              http://www.rubyonrails.com/contact;new%20with%20spaces
              http://www.rubyonrails.com/contact;new?with=query&string=params
              http://www.rubyonrails.com/~minam/contact;new?with=query&string=params
              http://en.wikipedia.org/wiki/Wikipedia:Today%27s_featured_picture_%28animation%29/January_20%2C_2007
              http://www.mail-archive.com/rails@lists.rubyonrails.org/
              http://www.amazon.com/Testing-Equal-Sign-In-Path/ref=pd_bbs_sr_1?ie=UTF8&s=books&qid=1198861734&sr=8-1
              http://en.wikipedia.org/wiki/Sprite_(computer_graphics)
              http://en.wikipedia.org/wiki/Texas_hold%27em
              https://www.google.com/doku.php?id=gps:resource:scs:start
            )

    urls.each do |url|
      assert_linked %(<a href="#{CGI.escapeHTML url}">#{CGI.escapeHTML url}</a>), CGI.escapeHTML(url)
    end
  end

  def test_links_like_autolink_rails
    email_raw    = 'david@loudthinking.com'
    email_result = %{<a href="mailto:#{email_raw}">#{email_raw}</a>}
    email2_raw    = '+david@loudthinking.com'
    email2_result = %{<a href="mailto:#{email2_raw}">#{email2_raw}</a>}
    link_raw     = 'http://www.rubyonrails.com'
    link_result  = %{<a href="#{link_raw}">#{link_raw}</a>}
    link2_raw    = 'www.rubyonrails.com'
    link2_result = %{<a href="http://#{link2_raw}">#{link2_raw}</a>}
    link3_raw    = 'http://manuals.ruby-on-rails.com/read/chapter.need_a-period/103#page281'
    link3_result = %{<a href="#{link3_raw}">#{link3_raw}</a>}
    link4_raw    = CGI.escapeHTML 'http://foo.example.com/controller/action?parm=value&p2=v2#anchor123'
    link4_result = %{<a href="#{link4_raw}">#{link4_raw}</a>}
    link5_raw    = 'http://foo.example.com:3000/controller/action'
    link5_result = %{<a href="#{link5_raw}">#{link5_raw}</a>}
    link6_raw    = 'http://foo.example.com:3000/controller/action+pack'
    link6_result = %{<a href="#{link6_raw}">#{link6_raw}</a>}
    link7_raw    = CGI.escapeHTML 'http://foo.example.com/controller/action?parm=value&p2=v2#anchor-123'
    link7_result = %{<a href="#{link7_raw}">#{link7_raw}</a>}
    link8_raw    = 'http://foo.example.com:3000/controller/action.html'
    link8_result = %{<a href="#{link8_raw}">#{link8_raw}</a>}
    link9_raw    = 'http://business.timesonline.co.uk/article/0,,9065-2473189,00.html'
    link9_result = %{<a href="#{link9_raw}">#{link9_raw}</a>}
    link10_raw    = 'http://www.mail-archive.com/ruby-talk@ruby-lang.org/'
    link10_result = %{<a href="#{link10_raw}">#{link10_raw}</a>}

    assert_linked %(Go to #{link_result} and say hello to #{email_result}), "Go to #{link_raw} and say hello to #{email_raw}"
    assert_linked %(<p>Link #{link_result}</p>), "<p>Link #{link_raw}</p>"
    assert_linked %(<p>#{link_result} Link</p>), "<p>#{link_raw} Link</p>"
    assert_linked %(Go to #{link_result}.), %(Go to #{link_raw}.)
    assert_linked %(<p>Go to #{link_result}, then say hello to #{email_result}.</p>), %(<p>Go to #{link_raw}, then say hello to #{email_raw}.</p>)
    assert_linked %(<p>Link #{link2_result}</p>), "<p>Link #{link2_raw}</p>"
    assert_linked %(<p>#{link2_result} Link</p>), "<p>#{link2_raw} Link</p>"
    assert_linked %(Go to #{link2_result}.), %(Go to #{link2_raw}.)
    assert_linked %(<p>Say hello to #{email_result}, then go to #{link2_result},</p>), %(<p>Say hello to #{email_raw}, then go to #{link2_raw},</p>)
    assert_linked %(<p>Link #{link3_result}</p>), "<p>Link #{link3_raw}</p>"
    assert_linked %(<p>#{link3_result} Link</p>), "<p>#{link3_raw} Link</p>"
    assert_linked %(Go to #{link3_result}.), %(Go to #{link3_raw}.)
    assert_linked %(<p>Go to #{link3_result}. seriously, #{link3_result}? i think I'll say hello to #{email_result}. instead.</p>), %(<p>Go to #{link3_raw}. seriously, #{link3_raw}? i think I'll say hello to #{email_raw}. instead.</p>)
    assert_linked %(<p>Link #{link4_result}</p>), "<p>Link #{link4_raw}</p>"
    assert_linked %(<p>#{link4_result} Link</p>), "<p>#{link4_raw} Link</p>"
    assert_linked %(<p>#{link5_result} Link</p>), "<p>#{link5_raw} Link</p>"
    assert_linked %(<p>#{link6_result} Link</p>), "<p>#{link6_raw} Link</p>"
    assert_linked %(<p>#{link7_result} Link</p>), "<p>#{link7_raw} Link</p>"
    assert_linked %(<p>Link #{link8_result}</p>), "<p>Link #{link8_raw}</p>"
    assert_linked %(<p>#{link8_result} Link</p>), "<p>#{link8_raw} Link</p>"
    assert_linked %(Go to #{link8_result}.), %(Go to #{link8_raw}.)
    assert_linked %(<p>Go to #{link8_result}. seriously, #{link8_result}? i think I'll say hello to #{email_result}. instead.</p>), %(<p>Go to #{link8_raw}. seriously, #{link8_raw}? i think I'll say hello to #{email_raw}. instead.</p>)
    assert_linked %(<p>Link #{link9_result}</p>), "<p>Link #{link9_raw}</p>"
    assert_linked %(<p>#{link9_result} Link</p>), "<p>#{link9_raw} Link</p>"
    assert_linked %(Go to #{link9_result}.), %(Go to #{link9_raw}.)
    assert_linked %(<p>Go to #{link9_result}. seriously, #{link9_result}? i think I'll say hello to #{email_result}. instead.</p>), %(<p>Go to #{link9_raw}. seriously, #{link9_raw}? i think I'll say hello to #{email_raw}. instead.</p>)
    assert_linked %(<p>#{link10_result} Link</p>), "<p>#{link10_raw} Link</p>"
    assert_linked email2_result, email2_raw
    assert_linked "#{link_result} #{link_result} #{link_result}", "#{link_raw} #{link_raw} #{link_raw}"
    assert_linked '<a href="http://www.rubyonrails.com">Ruby On Rails</a>', '<a href="http://www.rubyonrails.com">Ruby On Rails</a>'
  end

  def test_copies_source_encoding
    str = "http://www.bash.org"

    ret = Rinku.auto_link str
    assert_equal str.encoding, ret.encoding

    str.encode! 'binary'

    ret = Rinku.auto_link str
    assert_equal str.encoding, ret.encoding
  end

  def test_valid_encodings_are_generated
    str = "&lt;a href=&#39;http://gi.co&#39;&gt;gi.co&lt;/a&gt;\xC2\xA0r"
    assert_equal Encoding::UTF_8, str.encoding

    res = Rinku.auto_link(str)
    assert_equal Encoding::UTF_8, res.encoding
    assert res.valid_encoding?
  end

  def test_polish_wikipedia_haha
    url = "https://pl.wikipedia.org/wiki/Komisja_śledcza_do_zbadania_sprawy_zarzutu_nielegalnego_wywierania_wpływu_na_funkcjonariuszy_policji,_służb_specjalnych,_prokuratorów_i_osoby_pełniące_funkcje_w_organach_wymiaru_sprawiedliwości"
    input = "A wikipedia link (#{url})"
    expected = "A wikipedia link (<a href=\"#{url}\">#{url}</a>)"

    assert_linked expected, input
  end

  def test_only_valid_encodings_are_accepted
    str = "this is invalid \xA0 utf8"
    assert_equal Encoding::UTF_8, str.encoding
    assert !str.valid_encoding?

    assert_raises ArgumentError do
      Rinku.auto_link(str)
    end
  end

  NBSP = "\xC2\xA0".freeze

  def test_the_famous_nbsp
    input = "at http://google.com/#{NBSP};"
    expected = "at <a href=\"http://google.com/\">http://google.com/</a>#{NBSP};"
    assert_linked expected, input
  end

  def test_does_not_include_trailing_nonbreaking_spaces
    url = "http://example.com/"
    assert_linked "<a href=\"#{url}\">#{url}</a>#{NBSP}and", "#{url}#{NBSP}and"
  end

  def test_identifies_preceeding_nonbreaking_spaces
    url = "http://example.com/"
    assert_linked "#{NBSP}<a href=\"#{url}\">#{url}</a> and", "#{NBSP}#{url} and"
  end

  def test_urls_with_2_wide_UTF8_characters
    url = "http://example.com/?foo=¥&bar=1"
    assert_linked "<a href=\"#{url}\">#{url}</a> and", "#{url} and"
  end

  def test_urls_with_4_wide_UTF8_characters
    url = "http://example.com/?foo=&bar=1"
    assert_linked "<a href=\"#{url}\">#{url}</a> and", "#{url} and"
  end

  def test_handles_urls_with_emoji_properly
    url = "http://foo.com/💖a"
    assert_linked "<a href=\"#{url}\">#{url}</a> and", "#{url} and"
  end

  def test_identifies_nonbreaking_spaces_preceeding_emails
    email_raw = 'david@loudthinking.com'
    assert_linked "email#{NBSP}<a href=\"mailto:#{email_raw}\">#{email_raw}</a>", "email#{NBSP}#{email_raw}"
  end

  def test_identifies_unicode_spaces
    assert_linked(
      %{This is just a test. <a href="http://www.pokemon.com">http://www.pokemon.com</a>\u202F\u2028\u2001},
      "This is just a test. http://www.pokemon.com\u202F\u2028\u2001"
    )
  end

  def test_www_is_case_insensitive
    url = "www.reddit.com"
    assert_linked generate_result(url), url

    url = "WWW.REDDIT.COM"
    assert_linked generate_result(url), url

    url = "Www.reddit.Com"
    assert_linked generate_result(url), url

    url = "WwW.reddit.CoM"
    assert_linked generate_result(url), url
  end

  def test_non_emails_ending_in_periods
    assert_linked "abc/def@ghi.", "abc/def@ghi."
    assert_linked "abc/def@ghi. ", "abc/def@ghi. "
    assert_linked "abc/def@ghi. x", "abc/def@ghi. x"
    assert_linked "abc/def@ghi.< x", "abc/def@ghi.< x"
    assert_linked "abc/<a href=\"mailto:def@ghi.x\">def@ghi.x</a>", "abc/def@ghi.x"
    assert_linked "abc/<a href=\"mailto:def@ghi.x\">def@ghi.x</a>. a", "abc/def@ghi.x. a"
  end

  def test_urls_with_entities_and_parens
    assert_linked "&lt;<a href=\"http://www.google.com\">http://www.google.com</a>&gt;", "&lt;http://www.google.com&gt;"

    assert_linked "&lt;<a href=\"http://www.google.com\">http://www.google.com</a>&gt;)", "&lt;http://www.google.com&gt;)"

    # this produces invalid output, but limits how much work we will do
    assert_linked "&lt;<a href=\"http://www.google.com&gt;\">http://www.google.com&gt;</a>)&lt;)&lt;)&lt;)&lt;)&lt;)&lt;)", "&lt;http://www.google.com&gt;)&lt;)&lt;)&lt;)&lt;)&lt;)&lt;)"

    url = "http://pokemon.com/bulbasaur"
    assert_linked "URL is #{generate_result(url)}.", "URL is #{url}."
    assert_linked "(URL is #{generate_result(url)}.)", "(URL is #{url}.)"

    url = "www.pokemon.com/bulbasaur"
    assert_linked "URL is #{generate_result(url)}.", "URL is #{url}."
    assert_linked "(URL is #{generate_result(url)}.)", "(URL is #{url}.)"

    url = "abc@xyz.com"
    assert_linked "URL is #{generate_result(url, "mailto:#{url}")}.", "URL is #{url}."
    assert_linked "(URL is #{generate_result(url, "mailto:#{url}")}.)", "(URL is #{url}.)"
  end

  def test_urls_with_parens
    assert_linked "(<a href=\"http://example.com\">http://example.com</a>)", "(http://example.com)"
    assert_linked "((<a href=\"http://example.com/()\">http://example.com/()</a>))", "((http://example.com/()))"
    assert_linked "[<a href=\"http://example.com/()\">http://example.com/()</a>]", "[http://example.com/()]"

    assert_linked "（<a href=\"http://example.com/\">http://example.com/</a>）", "（http://example.com/）"
    assert_linked "【<a href=\"http://example.com/\">http://example.com/</a>】", "【http://example.com/】"
    assert_linked "『<a href=\"http://example.com/\">http://example.com/</a>』", "『http://example.com/』"
    assert_linked "「<a href=\"http://example.com/\">http://example.com/</a>」", "「http://example.com/」"
    assert_linked "《<a href=\"http://example.com/\">http://example.com/</a>》", "《http://example.com/》"
    assert_linked "〈<a href=\"http://example.com/\">http://example.com/</a>〉", "〈http://example.com/〉"
  end

  def test_urls_with_quotes
    assert_linked "'<a href=\"http://example.com\">http://example.com</a>'", "'http://example.com'"
    assert_linked "\"<a href=\"http://example.com\">http://example.com</a>\"\"", "\"http://example.com\"\""
  end

  def test_underscore_in_domain
    assert_linked "http://foo_bar.com", "http://foo_bar.com"
  end

  def test_underscore_in_subdomain
    assert_linked "<a href=\"http://foo_bar.xyz.com\">http://foo_bar.xyz.com</a>", "http://foo_bar.xyz.com"
  end

  def test_regression_84
    assert_linked "<a href=\"https://www.keepright.atの情報をもとにエラー修正\">https://www.keepright.atの情報をもとにエラー修正</a>", "https://www.keepright.atの情報をもとにエラー修正"
  end
end

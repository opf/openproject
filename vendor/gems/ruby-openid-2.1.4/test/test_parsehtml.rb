require 'test/unit'
require "openid/yadis/parsehtml"
require "testutil"

module OpenID
  class ParseHTMLTestCase < Test::Unit::TestCase
    include OpenID::TestDataMixin

    def test_parsehtml
      reserved_values = ['None', 'EOF']
      chunks = read_data_file('test1-parsehtml.txt', false).split("\f\n")
      test_num = 1

      chunks.each{|c|
        expected, html = c.split("\n", 2)
        found = Yadis::html_yadis_location(html)

        assert(!reserved_values.member?(found))

        # this case is a little hard to detect and the distinction
        # seems unimportant
        expected = "None" if expected == "EOF"

        found = "None" if found.nil?
        assert_equal(expected, found, html.split("\n",2)[0])
      }
    end
  end

  # the HTML tokenizer test
  class TC_TestHTMLTokenizer < Test::Unit::TestCase
    def test_bad_link
      toke = HTMLTokenizer.new("<p><a href=http://bad.com/link>foo</a></p>")
      assert("http://bad.com/link" == toke.getTag("a").attr_hash['href'])
    end

    def test_namespace
      toke = HTMLTokenizer.new("<f:table xmlns:f=\"http://www.com/foo\">")
      assert("http://www.com/foo" == toke.getTag("f:table").attr_hash['xmlns:f'])
    end

    def test_comment
      toke = HTMLTokenizer.new("<!-- comment on me -->")
      t = toke.getNextToken
      assert(HTMLComment == t.class)
      assert("comment on me" == t.contents)
    end

    def test_full
      page = "<HTML>
<HEAD>
<TITLE>This is the title</TITLE>
</HEAD>
<!-- Here comes the <a href=\"missing.link\">blah</a>
comment body
-->
<BODY>
<H1>This is the header</H1>
<P>
  This is the paragraph, it contains
  <a href=\"link.html\">links</a>,
  <img src=\"blah.gif\" optional alt='images
are
really cool'>.  Ok, here is some more text and
  <A href=\"http://another.link.com/\" target=\"_blank\">another link</A>.
</P>
</body>
</HTML>
"
      toke = HTMLTokenizer.new(page)

      assert("<h1>" == toke.getTag("h1", "h2", "h3").to_s.downcase)
      assert(HTMLTag.new("<a href=\"link.html\">") == toke.getTag("IMG", "A"))
      assert("links" == toke.getTrimmedText)
      assert(toke.getTag("IMG", "A").attr_hash['optional'])
      assert("_blank" == toke.getTag("IMG", "A").attr_hash['target'])
    end
  end
end


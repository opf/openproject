# encoding: utf-8
require_relative 'common'

describe 'Sanitize' do
  describe 'initializer' do
    it 'should not modify a transformers array in the given config' do
      transformers = [
        lambda {}
      ]

      Sanitize.new({ :transformers => transformers })
      transformers.length.must_equal(1)
    end
  end

  describe 'instance methods' do
    before do
      @s = Sanitize.new
    end

    describe '#document' do
      before do
        @s = Sanitize.new(:elements => ['html'])
      end

      it 'should sanitize an HTML document' do
        @s.document('<!doctype html><html><b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script></html>')
          .must_equal "<html>Lorem ipsum dolor sit amet </html>"
      end

      it 'should not modify the input string' do
        input = '<!DOCTYPE html><b>foo</b>'
        @s.document(input)
        input.must_equal('<!DOCTYPE html><b>foo</b>')
      end

      it 'should not choke on frozen documents' do
        @s.document('<!doctype html><html><b>foo</b>'.freeze).must_equal "<html>foo</html>"
      end

      it 'should normalize newlines' do
        @s.document("a\r\n\n\r\r\r\nz").must_equal "<html>a\n\n\n\n\nz</html>"
      end

      it 'should strip control characters (except ASCII whitespace)' do
        sample_control_chars = "\u0001\u0008\u000b\u000e\u001f\u007f\u009f"
        whitespace = "\t\n\f\u0020"
        @s.document("a#{sample_control_chars}#{whitespace}z").must_equal "<html>a#{whitespace}z</html>"
      end

      it 'should strip non-characters' do
        sample_non_chars = "\ufdd0\ufdef\ufffe\uffff\u{1fffe}\u{1ffff}\u{2fffe}\u{2ffff}\u{3fffe}\u{3ffff}\u{4fffe}\u{4ffff}\u{5fffe}\u{5ffff}\u{6fffe}\u{6ffff}\u{7fffe}\u{7ffff}\u{8fffe}\u{8ffff}\u{9fffe}\u{9ffff}\u{afffe}\u{affff}\u{bfffe}\u{bffff}\u{cfffe}\u{cffff}\u{dfffe}\u{dffff}\u{efffe}\u{effff}\u{ffffe}\u{fffff}\u{10fffe}\u{10ffff}"
        @s.document("a#{sample_non_chars}z").must_equal "<html>az</html>"
      end

      describe 'when html body exceeds Nokogumbo::DEFAULT_MAX_TREE_DEPTH' do
        let(:content) do
          content = nest_html_content('<b>foo</b>', Nokogumbo::DEFAULT_MAX_TREE_DEPTH)
          "<html>#{content}</html>"
        end

        it 'raises an ArgumentError exception' do
          assert_raises ArgumentError do
            @s.document(content)
          end
        end

        describe 'and :max_tree_depth of -1 is supplied in :parser_options' do
          before do
            @s = Sanitize.new(elements: ['html'], parser_options: { max_tree_depth: -1 })
          end

          it 'does not raise an ArgumentError exception' do
            @s.document(content).must_equal '<html>foo</html>'
          end
        end
      end
    end

    describe '#fragment' do
      it 'should sanitize an HTML fragment' do
        @s.fragment('<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>')
          .must_equal 'Lorem ipsum dolor sit amet '
      end

      it 'should not modify the input string' do
        input = '<b>foo</b>'
        @s.fragment(input)
        input.must_equal '<b>foo</b>'
      end

      it 'should not choke on fragments containing <html> or <body>' do
        @s.fragment('<html><b>foo</b></html>').must_equal 'foo'
        @s.fragment('<body><b>foo</b></body>').must_equal 'foo'
        @s.fragment('<html><body><b>foo</b></body></html>').must_equal 'foo'
        @s.fragment('<!DOCTYPE html><html><body><b>foo</b></body></html>').must_equal 'foo'
      end

      it 'should not choke on frozen fragments' do
        @s.fragment('<b>foo</b>'.freeze).must_equal 'foo'
      end

      it 'should normalize newlines' do
        @s.fragment("a\r\n\n\r\r\r\nz").must_equal "a\n\n\n\n\nz"
      end

      it 'should strip control characters (except ASCII whitespace)' do
        sample_control_chars = "\u0001\u0008\u000b\u000e\u001f\u007f\u009f"
        whitespace = "\t\n\f\u0020"
        @s.fragment("a#{sample_control_chars}#{whitespace}z").must_equal "a#{whitespace}z"
      end

      it 'should strip non-characters' do
        sample_non_chars = "\ufdd0\ufdef\ufffe\uffff\u{1fffe}\u{1ffff}\u{2fffe}\u{2ffff}\u{3fffe}\u{3ffff}\u{4fffe}\u{4ffff}\u{5fffe}\u{5ffff}\u{6fffe}\u{6ffff}\u{7fffe}\u{7ffff}\u{8fffe}\u{8ffff}\u{9fffe}\u{9ffff}\u{afffe}\u{affff}\u{bfffe}\u{bffff}\u{cfffe}\u{cffff}\u{dfffe}\u{dffff}\u{efffe}\u{effff}\u{ffffe}\u{fffff}\u{10fffe}\u{10ffff}"
        @s.fragment("a#{sample_non_chars}z").must_equal "az"
      end

      describe 'when html body exceeds Nokogumbo::DEFAULT_MAX_TREE_DEPTH' do
        let(:content) do
          content = nest_html_content('<b>foo</b>', Nokogumbo::DEFAULT_MAX_TREE_DEPTH)
          "<body>#{content}</body>"
        end

        it 'raises an ArgumentError exception' do
          assert_raises ArgumentError do
            @s.fragment(content)
          end
        end

        describe 'and :max_tree_depth of -1 is supplied in :parser_options' do
          before do
            @s = Sanitize.new(parser_options: { max_tree_depth: -1 })
          end

          it 'does not raise an ArgumentError exception' do
            @s.fragment(content).must_equal 'foo'
          end
        end
      end
    end

    describe '#node!' do
      it 'should sanitize a Nokogiri::XML::Node' do
        doc  = Nokogiri::HTML5.parse('<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>')
        frag = doc.fragment

        doc.xpath('/html/body/node()').each {|node| frag << node }

        @s.node!(frag)
        frag.to_html.must_equal 'Lorem ipsum dolor sit amet '
      end

      describe "when the given node is a document and <html> isn't allowlisted" do
        it 'should raise a Sanitize::Error' do
          doc = Nokogiri::HTML5.parse('foo')
          proc { @s.node!(doc) }.must_raise Sanitize::Error
        end
      end
    end
  end

  describe 'class methods' do
    describe '.document' do
      it 'should sanitize an HTML document with the given config' do
        html = '<!doctype html><html><b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script></html>'
        Sanitize.document(html, :elements => ['html'])
          .must_equal "<html>Lorem ipsum dolor sit amet </html>"
      end
    end

    describe '.fragment' do
      it 'should sanitize an HTML fragment with the given config' do
        html = '<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>'
        Sanitize.fragment(html, :elements => ['strong'])
          .must_equal 'Lorem ipsum <strong>dolor</strong> sit amet '
      end
    end

    describe '.node!' do
      it 'should sanitize a Nokogiri::XML::Node with the given config' do
        doc = Nokogiri::HTML5.parse('<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <script>alert("hello world");</script>')
        frag = doc.fragment

        doc.xpath('/html/body/node()').each {|node| frag << node }

        Sanitize.node!(frag, :elements => ['strong'])
        frag.to_html.must_equal 'Lorem ipsum <strong>dolor</strong> sit amet '
      end
    end
  end

  private

  def nest_html_content(html_content, depth)
    "#{'<span>' * depth}#{html_content}#{'</span>' * depth}"
  end
end

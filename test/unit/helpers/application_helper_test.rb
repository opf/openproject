# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../../test_helper', __FILE__)

class ApplicationHelperTest < ActionView::TestCase
  
  fixtures :projects, :roles, :enabled_modules, :users,
                      :repositories, :changesets, 
                      :trackers, :issue_statuses, :issues, :versions, :documents,
                      :wikis, :wiki_pages, :wiki_contents,
                      :boards, :messages,
                      :attachments,
                      :enumerations

  def setup
    super
  end

  context "#link_to_if_authorized" do
    context "authorized user" do
      should "be tested"
    end
    
    context "unauthorized user" do
      should "be tested"
    end
    
    should "allow using the :controller and :action for the target link" do
      User.current = User.find_by_login('admin')

      @project = Issue.first.project # Used by helper
      response = link_to_if_authorized("By controller/action",
                                       {:controller => 'issues', :action => 'edit', :id => Issue.first.id})
      assert_match /href/, response
    end
    
  end
  
  def test_auto_links
    to_test = {
      'http://foo.bar' => '<a class="external" href="http://foo.bar">http://foo.bar</a>',
      'http://foo.bar/~user' => '<a class="external" href="http://foo.bar/~user">http://foo.bar/~user</a>',
      'http://foo.bar.' => '<a class="external" href="http://foo.bar">http://foo.bar</a>.',
      'https://foo.bar.' => '<a class="external" href="https://foo.bar">https://foo.bar</a>.',
      'This is a link: http://foo.bar.' => 'This is a link: <a class="external" href="http://foo.bar">http://foo.bar</a>.',
      'A link (eg. http://foo.bar).' => 'A link (eg. <a class="external" href="http://foo.bar">http://foo.bar</a>).',
      'http://foo.bar/foo.bar#foo.bar.' => '<a class="external" href="http://foo.bar/foo.bar#foo.bar">http://foo.bar/foo.bar#foo.bar</a>.',
      'http://www.foo.bar/Test_(foobar)' => '<a class="external" href="http://www.foo.bar/Test_(foobar)">http://www.foo.bar/Test_(foobar)</a>',
      '(see inline link : http://www.foo.bar/Test_(foobar))' => '(see inline link : <a class="external" href="http://www.foo.bar/Test_(foobar)">http://www.foo.bar/Test_(foobar)</a>)',
      '(see inline link : http://www.foo.bar/Test)' => '(see inline link : <a class="external" href="http://www.foo.bar/Test">http://www.foo.bar/Test</a>)',
      '(see inline link : http://www.foo.bar/Test).' => '(see inline link : <a class="external" href="http://www.foo.bar/Test">http://www.foo.bar/Test</a>).',
      '(see "inline link":http://www.foo.bar/Test_(foobar))' => '(see <a href="http://www.foo.bar/Test_(foobar)" class="external">inline link</a>)',
      '(see "inline link":http://www.foo.bar/Test)' => '(see <a href="http://www.foo.bar/Test" class="external">inline link</a>)',
      '(see "inline link":http://www.foo.bar/Test).' => '(see <a href="http://www.foo.bar/Test" class="external">inline link</a>).',
      'www.foo.bar' => '<a class="external" href="http://www.foo.bar">www.foo.bar</a>',
      'http://foo.bar/page?p=1&t=z&s=' => '<a class="external" href="http://foo.bar/page?p=1&#38;t=z&#38;s=">http://foo.bar/page?p=1&#38;t=z&#38;s=</a>',
      'http://foo.bar/page#125' => '<a class="external" href="http://foo.bar/page#125">http://foo.bar/page#125</a>',
      'http://foo@www.bar.com' => '<a class="external" href="http://foo@www.bar.com">http://foo@www.bar.com</a>',
      'http://foo:bar@www.bar.com' => '<a class="external" href="http://foo:bar@www.bar.com">http://foo:bar@www.bar.com</a>',
      'ftp://foo.bar' => '<a class="external" href="ftp://foo.bar">ftp://foo.bar</a>',
      'ftps://foo.bar' => '<a class="external" href="ftps://foo.bar">ftps://foo.bar</a>',
      'sftp://foo.bar' => '<a class="external" href="sftp://foo.bar">sftp://foo.bar</a>',
      # two exclamation marks
      'http://example.net/path!602815048C7B5C20!302.html' => '<a class="external" href="http://example.net/path!602815048C7B5C20!302.html">http://example.net/path!602815048C7B5C20!302.html</a>',
      # escaping
      'http://foo"bar' => '<a class="external" href="http://foo&quot;bar">http://foo"bar</a>',
      # wrap in angle brackets
      '<http://foo.bar>' => '&lt;<a class="external" href="http://foo.bar">http://foo.bar</a>&gt;'
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_auto_mailto
    assert_equal '<p><a class="email" href="mailto:test@foo.bar">test@foo.bar</a></p>', 
      textilizable('test@foo.bar')
  end
  
  def test_inline_images
    to_test = {
      '!http://foo.bar/image.jpg!' => '<img src="http://foo.bar/image.jpg" alt="" />',
      'floating !>http://foo.bar/image.jpg!' => 'floating <div style="float:right"><img src="http://foo.bar/image.jpg" alt="" /></div>',
      'with class !(some-class)http://foo.bar/image.jpg!' => 'with class <img src="http://foo.bar/image.jpg" class="some-class" alt="" />',
      # inline styles should be stripped
      'with style !{width:100px;height100px}http://foo.bar/image.jpg!' => 'with style <img src="http://foo.bar/image.jpg" alt="" />',
      'with title !http://foo.bar/image.jpg(This is a title)!' => 'with title <img src="http://foo.bar/image.jpg" title="This is a title" alt="This is a title" />',
      'with title !http://foo.bar/image.jpg(This is a double-quoted "title")!' => 'with title <img src="http://foo.bar/image.jpg" title="This is a double-quoted &quot;title&quot;" alt="This is a double-quoted &quot;title&quot;" />',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_inline_images_inside_tags
    raw = <<-RAW
h1. !foo.png! Heading

Centered image:

p=. !bar.gif!
RAW

    assert textilizable(raw).include?('<img src="foo.png" alt="" />')
    assert textilizable(raw).include?('<img src="bar.gif" alt="" />')
  end
  
  def test_attached_images
    to_test = {
      'Inline image: !logo.gif!' => 'Inline image: <img src="/attachments/download/3" title="This is a logo" alt="This is a logo" />',
      'Inline image: !logo.GIF!' => 'Inline image: <img src="/attachments/download/3" title="This is a logo" alt="This is a logo" />',
      'No match: !ogo.gif!' => 'No match: <img src="ogo.gif" alt="" />',
      'No match: !ogo.GIF!' => 'No match: <img src="ogo.GIF" alt="" />',
      # link image
      '!logo.gif!:http://foo.bar/' => '<a href="http://foo.bar/"><img src="/attachments/download/3" title="This is a logo" alt="This is a logo" /></a>',
    }
    attachments = Attachment.find(:all)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text, :attachments => attachments) }
  end
  
  def test_textile_external_links
    to_test = {
      'This is a "link":http://foo.bar' => 'This is a <a href="http://foo.bar" class="external">link</a>',
      'This is an intern "link":/foo/bar' => 'This is an intern <a href="/foo/bar">link</a>',
      '"link (Link title)":http://foo.bar' => '<a href="http://foo.bar" title="Link title" class="external">link</a>',
      '"link (Link title with "double-quotes")":http://foo.bar' => '<a href="http://foo.bar" title="Link title with &quot;double-quotes&quot;" class="external">link</a>',
      "This is not a \"Link\":\n\nAnother paragraph" => "This is not a \"Link\":</p>\n\n\n\t<p>Another paragraph",
      # no multiline link text
      "This is a double quote \"on the first line\nand another on a second line\":test" => "This is a double quote \"on the first line<br />and another on a second line\":test",
      # mailto link
      "\"system administrator\":mailto:sysadmin@example.com?subject=redmine%20permissions" => "<a href=\"mailto:sysadmin@example.com?subject=redmine%20permissions\">system administrator</a>",
      # two exclamation marks
      '"a link":http://example.net/path!602815048C7B5C20!302.html' => '<a href="http://example.net/path!602815048C7B5C20!302.html" class="external">a link</a>',
      # escaping
      '"test":http://foo"bar' => '<a href="http://foo&quot;bar" class="external">test</a>',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_redmine_links
    issue_link = link_to('#3', {:controller => 'issues', :action => 'show', :id => 3}, 
                               :class => 'issue status-1 priority-1 overdue', :title => 'Error 281 when updating a recipe (New)')
    
    changeset_link = link_to('r1', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 1},
                                   :class => 'changeset', :title => 'My very first commit')
    changeset_link2 = link_to('r2', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 2},
                                    :class => 'changeset', :title => 'This commit fixes #1, #2 and references #1 & #3')
    
    document_link = link_to('Test document', {:controller => 'documents', :action => 'show', :id => 1},
                                             :class => 'document')
    
    version_link = link_to('1.0', {:controller => 'versions', :action => 'show', :id => 2},
                                  :class => 'version')

    message_url = {:controller => 'messages', :action => 'show', :board_id => 1, :id => 4}
    
    project_url = {:controller => 'projects', :action => 'show', :id => 'subproject1'}
    
    source_url = {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :path => ['some', 'file']}
    source_url_with_ext = {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :path => ['some', 'file.ext']}
    
    to_test = {
      # tickets
      '#3, [#3], (#3) and #3.'      => "#{issue_link}, [#{issue_link}], (#{issue_link}) and #{issue_link}.",
      # changesets
      'r1'                          => changeset_link,
      'r1.'                         => "#{changeset_link}.",
      'r1, r2'                      => "#{changeset_link}, #{changeset_link2}",
      'r1,r2'                       => "#{changeset_link},#{changeset_link2}",
      # documents
      'document#1'                  => document_link,
      'document:"Test document"'    => document_link,
      # versions
      'version#2'                   => version_link,
      'version:1.0'                 => version_link,
      'version:"1.0"'               => version_link,
      # source
      'source:/some/file'           => link_to('source:/some/file', source_url, :class => 'source'),
      'source:/some/file.'          => link_to('source:/some/file', source_url, :class => 'source') + ".",
      'source:/some/file.ext.'      => link_to('source:/some/file.ext', source_url_with_ext, :class => 'source') + ".",
      'source:/some/file. '         => link_to('source:/some/file', source_url, :class => 'source') + ".",
      'source:/some/file.ext. '     => link_to('source:/some/file.ext', source_url_with_ext, :class => 'source') + ".",
      'source:/some/file, '         => link_to('source:/some/file', source_url, :class => 'source') + ",",
      'source:/some/file@52'        => link_to('source:/some/file@52', source_url.merge(:rev => 52), :class => 'source'),
      'source:/some/file.ext@52'    => link_to('source:/some/file.ext@52', source_url_with_ext.merge(:rev => 52), :class => 'source'),
      'source:/some/file#L110'      => link_to('source:/some/file#L110', source_url.merge(:anchor => 'L110'), :class => 'source'),
      'source:/some/file.ext#L110'  => link_to('source:/some/file.ext#L110', source_url_with_ext.merge(:anchor => 'L110'), :class => 'source'),
      'source:/some/file@52#L110'   => link_to('source:/some/file@52#L110', source_url.merge(:rev => 52, :anchor => 'L110'), :class => 'source'),
      'export:/some/file'           => link_to('export:/some/file', source_url.merge(:format => 'raw'), :class => 'source download'),
      # message
      'message#4'                   => link_to('Post 2', message_url, :class => 'message'),
      'message#5'                   => link_to('RE: post 2', message_url.merge(:anchor => 'message-5'), :class => 'message'),
      # project
      'project#3'                   => link_to('eCookbook Subproject 1', project_url, :class => 'project'),
      'project:subproject1'         => link_to('eCookbook Subproject 1', project_url, :class => 'project'),
      'project:"eCookbook subProject 1"'        => link_to('eCookbook Subproject 1', project_url, :class => 'project'),
      # escaping
      '!#3.'                        => '#3.',
      '!r1'                         => 'r1',
      '!document#1'                 => 'document#1',
      '!document:"Test document"'   => 'document:"Test document"',
      '!version#2'                  => 'version#2',
      '!version:1.0'                => 'version:1.0',
      '!version:"1.0"'              => 'version:"1.0"',
      '!source:/some/file'          => 'source:/some/file',
      # not found
      '#0123456789'                 => '#0123456789',
      # invalid expressions
      'source:'                     => 'source:',
      # url hash
      "http://foo.bar/FAQ#3"       => '<a class="external" href="http://foo.bar/FAQ#3">http://foo.bar/FAQ#3</a>',
    }
    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text), "#{text} failed" }
  end

  def test_redmine_links_git_commit
    changeset_link = link_to('abcd',
                               {
                                 :controller => 'repositories',
                                 :action     => 'revision',
                                 :id         => 'subproject1',
                                 :rev        => 'abcd',
                                },
                              :class => 'changeset', :title => 'test commit')
    to_test = {
      'commit:abcd' => changeset_link,
     }
    @project = Project.find(3)
    r = Repository::Git.create!(:project => @project, :url => '/tmp/test/git')
    assert r
    c = Changeset.new(:repository => r,
                      :committed_on => Time.now,
                      :revision => 'abcd',
                      :scmid => 'abcd',
                      :comments => 'test commit')
    assert( c.save )
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  # TODO: Bazaar commit id contains mail address, so it contains '@' and '_'.
  def test_redmine_links_darcs_commit
    changeset_link = link_to('20080308225258-98289-abcd456efg.gz',
                               {
                                 :controller => 'repositories',
                                 :action     => 'revision',
                                 :id         => 'subproject1',
                                 :rev        => '123',
                                },
                              :class => 'changeset', :title => 'test commit')
    to_test = {
      'commit:20080308225258-98289-abcd456efg.gz' => changeset_link,
     }
    @project = Project.find(3)
    r = Repository::Darcs.create!(:project => @project, :url => '/tmp/test/darcs')
    assert r
    c = Changeset.new(:repository => r,
                      :committed_on => Time.now,
                      :revision => '123',
                      :scmid => '20080308225258-98289-abcd456efg.gz',
                      :comments => 'test commit')
    assert( c.save )
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end

  def test_attachment_links
    attachment_link = link_to('error281.txt', {:controller => 'attachments', :action => 'download', :id => '1'}, :class => 'attachment')
    to_test = {
      'attachment:error281.txt'      => attachment_link
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text, :attachments => Issue.find(3).attachments), "#{text} failed" }
  end
  
  def test_wiki_links
    to_test = {
      '[[CookBook documentation]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation" class="wiki-page">CookBook documentation</a>',
      '[[Another page|Page]]' => '<a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Page</a>',
      # link with anchor
      '[[CookBook documentation#One-section]]' => '<a href="/projects/ecookbook/wiki/CookBook_documentation#One-section" class="wiki-page">CookBook documentation</a>',
      '[[Another page#anchor|Page]]' => '<a href="/projects/ecookbook/wiki/Another_page#anchor" class="wiki-page">Page</a>',
      # page that doesn't exist
      '[[Unknown page]]' => '<a href="/projects/ecookbook/wiki/Unknown_page" class="wiki-page new">Unknown page</a>',
      '[[Unknown page|404]]' => '<a href="/projects/ecookbook/wiki/Unknown_page" class="wiki-page new">404</a>',
      # link to another project wiki
      '[[onlinestore:]]' => '<a href="/projects/onlinestore/wiki" class="wiki-page">onlinestore</a>',
      '[[onlinestore:|Wiki]]' => '<a href="/projects/onlinestore/wiki" class="wiki-page">Wiki</a>',
      '[[onlinestore:Start page]]' => '<a href="/projects/onlinestore/wiki/Start_page" class="wiki-page">Start page</a>',
      '[[onlinestore:Start page|Text]]' => '<a href="/projects/onlinestore/wiki/Start_page" class="wiki-page">Text</a>',
      '[[onlinestore:Unknown page]]' => '<a href="/projects/onlinestore/wiki/Unknown_page" class="wiki-page new">Unknown page</a>',
      # striked through link
      '-[[Another page|Page]]-' => '<del><a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Page</a></del>',
      '-[[Another page|Page]] link-' => '<del><a href="/projects/ecookbook/wiki/Another_page" class="wiki-page">Page</a> link</del>',
      # escaping
      '![[Another page|Page]]' => '[[Another page|Page]]',
      # project does not exist
      '[[unknowproject:Start]]' => '[[unknowproject:Start]]',
      '[[unknowproject:Start|Page title]]' => '[[unknowproject:Start|Page title]]',
    }
    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_html_tags
    to_test = {
      "<div>content</div>" => "<p>&lt;div&gt;content&lt;/div&gt;</p>",
      "<div class=\"bold\">content</div>" => "<p>&lt;div class=\"bold\"&gt;content&lt;/div&gt;</p>",
      "<script>some script;</script>" => "<p>&lt;script&gt;some script;&lt;/script&gt;</p>",
      # do not escape pre/code tags
      "<pre>\nline 1\nline2</pre>" => "<pre>\nline 1\nline2</pre>",
      "<pre><code>\nline 1\nline2</code></pre>" => "<pre><code>\nline 1\nline2</code></pre>",
      "<pre><div>content</div></pre>" => "<pre>&lt;div&gt;content&lt;/div&gt;</pre>",
      "HTML comment: <!-- no comments -->" => "<p>HTML comment: &lt;!-- no comments --&gt;</p>",
      "<!-- opening comment" => "<p>&lt;!-- opening comment</p>",
      # remove attributes except class
      "<pre class='foo'>some text</pre>" => "<pre class='foo'>some text</pre>",
      '<pre class="foo">some text</pre>' => '<pre class="foo">some text</pre>',
      "<pre class='foo bar'>some text</pre>" => "<pre class='foo bar'>some text</pre>",
      '<pre class="foo bar">some text</pre>' => '<pre class="foo bar">some text</pre>',
      "<pre onmouseover='alert(1)'>some text</pre>" => "<pre>some text</pre>",
      # xss
      '<pre><code class=""onmouseover="alert(1)">text</code></pre>' => '<pre><code>text</code></pre>',
      '<pre class=""onmouseover="alert(1)">text</pre>' => '<pre>text</pre>',
    }
    to_test.each { |text, result| assert_equal result, textilizable(text) }
  end
  
  def test_allowed_html_tags
    to_test = {
      "<pre>preformatted text</pre>" => "<pre>preformatted text</pre>",
      "<notextile>no *textile* formatting</notextile>" => "no *textile* formatting",
      "<notextile>this is <tag>a tag</tag></notextile>" => "this is &lt;tag&gt;a tag&lt;/tag&gt;"
    }
    to_test.each { |text, result| assert_equal result, textilizable(text) }
  end
  
  def test_pre_tags
    raw = <<-RAW
Before

<pre>
<prepared-statement-cache-size>32</prepared-statement-cache-size>
</pre>

After
RAW

    expected = <<-EXPECTED
<p>Before</p>
<pre>
&lt;prepared-statement-cache-size&gt;32&lt;/prepared-statement-cache-size&gt;
</pre>
<p>After</p>
EXPECTED
    
    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end
  
  def test_pre_content_should_not_parse_wiki_and_redmine_links
    raw = <<-RAW
[[CookBook documentation]]
  
#1

<pre>
[[CookBook documentation]]
  
#1
</pre>
RAW

    expected = <<-EXPECTED
<p><a href="/projects/ecookbook/wiki/CookBook_documentation" class="wiki-page">CookBook documentation</a></p>
<p><a href="/issues/1" class="issue status-1 priority-1" title="Can't print recipes (New)">#1</a></p>
<pre>
[[CookBook documentation]]

#1
</pre>
EXPECTED
                                 
    @project = Project.find(1)
    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end
  
  def test_non_closing_pre_blocks_should_be_closed
    raw = <<-RAW
<pre><code>
RAW

    expected = <<-EXPECTED
<pre><code>
</code></pre>
EXPECTED
                                 
    @project = Project.find(1)
    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end
  
  def test_syntax_highlight
    raw = <<-RAW
<pre><code class="ruby">
# Some ruby code here
</code></pre>
RAW

    expected = <<-EXPECTED
<pre><code class="ruby syntaxhl"><span class=\"CodeRay\"><span class="no">1</span> <span class="c"># Some ruby code here</span></span>
</code></pre>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end
  
  def test_wiki_links_in_tables
    to_test = {"|[[Page|Link title]]|[[Other Page|Other title]]|\n|Cell 21|[[Last page]]|" =>
                 '<tr><td><a href="/projects/ecookbook/wiki/Page" class="wiki-page new">Link title</a></td>' +
                 '<td><a href="/projects/ecookbook/wiki/Other_Page" class="wiki-page new">Other title</a></td>' +
                 '</tr><tr><td>Cell 21</td><td><a href="/projects/ecookbook/wiki/Last_page" class="wiki-page new">Last page</a></td></tr>'
    }
    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<table>#{result}</table>", textilizable(text).gsub(/[\t\n]/, '') }
  end
  
  def test_text_formatting
    to_test = {'*_+bold, italic and underline+_*' => '<strong><em><ins>bold, italic and underline</ins></em></strong>',
               '(_text within parentheses_)' => '(<em>text within parentheses</em>)',
               'a *Humane Web* Text Generator' => 'a <strong>Humane Web</strong> Text Generator',
               'a H *umane* W *eb* T *ext* G *enerator*' => 'a H <strong>umane</strong> W <strong>eb</strong> T <strong>ext</strong> G <strong>enerator</strong>',
               'a *H* umane *W* eb *T* ext *G* enerator' => 'a <strong>H</strong> umane <strong>W</strong> eb <strong>T</strong> ext <strong>G</strong> enerator',
              }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_wiki_horizontal_rule
    assert_equal '<hr />', textilizable('---')
    assert_equal '<p>Dashes: ---</p>', textilizable('Dashes: ---')
  end
  
  def test_footnotes
    raw = <<-RAW
This is some text[1].

fn1. This is the foot note
RAW

    expected = <<-EXPECTED
<p>This is some text<sup><a href=\"#fn1\">1</a></sup>.</p>
<p id="fn1" class="footnote"><sup>1</sup> This is the foot note</p>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), textilizable(raw).gsub(%r{[\r\n\t]}, '')
  end
  
  def test_table_of_content
    raw = <<-RAW
{{toc}}

h1. Title

Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

h2. Subtitle with a [[Wiki]] link

Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.

h2. Subtitle with [[Wiki|another Wiki]] link

h2. Subtitle with %{color:red}red text%

<pre>
some code
</pre>

h3. Subtitle with *some* _modifiers_

h1. Another title

h3. An "Internet link":http://www.redmine.org/ inside subtitle

h2. "Project Name !/attachments/1234/logo_small.gif! !/attachments/5678/logo_2.png!":/projects/projectname/issues

RAW

    expected =  '<ul class="toc">' +
                  '<li><a href="#Title">Title</a>' +
                    '<ul>' +
                      '<li><a href="#Subtitle-with-a-Wiki-link">Subtitle with a Wiki link</a></li>' + 
                      '<li><a href="#Subtitle-with-another-Wiki-link">Subtitle with another Wiki link</a></li>' + 
                      '<li><a href="#Subtitle-with-red-text">Subtitle with red text</a>' +
                        '<ul>' +
                          '<li><a href="#Subtitle-with-some-modifiers">Subtitle with some modifiers</a></li>' +
                        '</ul>' +
                      '</li>' +
                    '</ul>' +
                  '</li>' +
                  '<li><a href="#Another-title">Another title</a>' +
                    '<ul>' +
                      '<li>' +
                        '<ul>' +
                          '<li><a href="#An-Internet-link-inside-subtitle">An Internet link inside subtitle</a></li>' +
                        '</ul>' +
                      '</li>' +
                      '<li><a href="#Project-Name">Project Name</a></li>' +
                    '</ul>' +
                  '</li>' +
               '</ul>'

    @project = Project.find(1)
    assert textilizable(raw).gsub("\n", "").include?(expected), textilizable(raw)
  end
  
  def test_table_of_content_should_contain_included_page_headings
    raw = <<-RAW
{{toc}}

h1. Included

{{include(Child_1)}}
RAW

    expected = '<ul class="toc">' +
               '<li><a href="#Included">Included</a></li>' +
               '<li><a href="#Child-page-1">Child page 1</a></li>' + 
               '</ul>'

    @project = Project.find(1)
    assert textilizable(raw).gsub("\n", "").include?(expected)
  end
  
  def test_blockquote
    # orig raw text
    raw = <<-RAW
John said:
> Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.
> Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.
> * Donec odio lorem,
> * sagittis ac,
> * malesuada in,
> * adipiscing eu, dolor.
>
> >Nulla varius pulvinar diam. Proin id arcu id lorem scelerisque condimentum. Proin vehicula turpis vitae lacus.
> Proin a tellus. Nam vel neque.

He's right.
RAW
    
    # expected html
    expected = <<-EXPECTED
<p>John said:</p>
<blockquote>
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.
Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.
<ul>
  <li>Donec odio lorem,</li>
  <li>sagittis ac,</li>
  <li>malesuada in,</li>
  <li>adipiscing eu, dolor.</li>
</ul>
<blockquote>
<p>Nulla varius pulvinar diam. Proin id arcu id lorem scelerisque condimentum. Proin vehicula turpis vitae lacus.</p>
</blockquote>
<p>Proin a tellus. Nam vel neque.</p>
</blockquote>
<p>He's right.</p>
EXPECTED
    
    assert_equal expected.gsub(%r{\s+}, ''), textilizable(raw).gsub(%r{\s+}, '')
  end
  
  def test_table
    raw = <<-RAW
This is a table with empty cells:

|cell11|cell12||
|cell21||cell23|
|cell31|cell32|cell33|
RAW

    expected = <<-EXPECTED
<p>This is a table with empty cells:</p>

<table>
  <tr><td>cell11</td><td>cell12</td><td></td></tr>
  <tr><td>cell21</td><td></td><td>cell23</td></tr>
  <tr><td>cell31</td><td>cell32</td><td>cell33</td></tr>
</table>
EXPECTED

    assert_equal expected.gsub(%r{\s+}, ''), textilizable(raw).gsub(%r{\s+}, '')
  end
  
  def test_table_with_line_breaks
    raw = <<-RAW
This is a table with line breaks:

|cell11
continued|cell12||
|-cell21-||cell23
cell23 line2
cell23 *line3*|
|cell31|cell32
cell32 line2|cell33|

RAW

    expected = <<-EXPECTED
<p>This is a table with line breaks:</p>

<table>
  <tr>
    <td>cell11<br />continued</td>
    <td>cell12</td>
    <td></td>
  </tr>
  <tr>
    <td><del>cell21</del></td>
    <td></td>
    <td>cell23<br/>cell23 line2<br/>cell23 <strong>line3</strong></td>
  </tr>
  <tr>
    <td>cell31</td>
    <td>cell32<br/>cell32 line2</td>
    <td>cell33</td>
  </tr>
</table>
EXPECTED

    assert_equal expected.gsub(%r{\s+}, ''), textilizable(raw).gsub(%r{\s+}, '')
  end
  
  def test_textile_should_not_mangle_brackets
    assert_equal '<p>[msg1][msg2]</p>', textilizable('[msg1][msg2]')
  end
  
  def test_default_formatter
    Setting.text_formatting = 'unknown'
    text = 'a *link*: http://www.example.net/'
    assert_equal '<p>a *link*: <a href="http://www.example.net/">http://www.example.net/</a></p>', textilizable(text)
    Setting.text_formatting = 'textile'
  end
  
  def test_due_date_distance_in_words
    to_test = { Date.today => 'Due in 0 days',
                Date.today + 1 => 'Due in 1 day',
                Date.today + 100 => 'Due in about 3 months',
                Date.today + 20000 => 'Due in over 54 years',
                Date.today - 1 => '1 day late',
                Date.today - 100 => 'about 3 months late',
                Date.today - 20000 => 'over 54 years late',
               }
    ::I18n.locale = :en
    to_test.each do |date, expected|
      assert_equal expected, due_date_distance_in_words(date)
    end
  end
  
  def test_avatar
    # turn on avatars
    Setting.gravatar_enabled = '1'
    assert avatar(User.find_by_mail('jsmith@somenet.foo')).include?(Digest::MD5.hexdigest('jsmith@somenet.foo'))
    assert avatar('jsmith <jsmith@somenet.foo>').include?(Digest::MD5.hexdigest('jsmith@somenet.foo'))
    assert_nil avatar('jsmith')
    assert_nil avatar(nil)
    
    # turn off avatars
    Setting.gravatar_enabled = '0'
    assert_equal '', avatar(User.find_by_mail('jsmith@somenet.foo'))
  end
  
  def test_link_to_user
    user = User.find(2)
    t = link_to_user(user)
    assert_equal "<a href=\"/users/2\">#{ user.name }</a>", t
  end
                                      
  def test_link_to_user_should_not_link_to_locked_user
    user = User.find(5)
    assert user.locked?
    t = link_to_user(user)
    assert_equal user.name, t
  end
                                                                          
  def test_link_to_user_should_not_link_to_anonymous
    user = User.anonymous
    assert user.anonymous?
    t = link_to_user(user)
    assert_equal ::I18n.t(:label_user_anonymous), t
  end

  def test_link_to_project
    project = Project.find(1)
    assert_equal %(<a href="/projects/ecookbook">eCookbook</a>),
                 link_to_project(project)
    assert_equal %(<a href="/projects/ecookbook/settings">eCookbook</a>),
                 link_to_project(project, :action => 'settings')
    assert_equal %(<a href="http://test.host/projects/ecookbook?jump=blah">eCookbook</a>),
                 link_to_project(project, {:only_path => false, :jump => 'blah'})
    assert_equal %(<a href="/projects/ecookbook/settings" class="project">eCookbook</a>),
                 link_to_project(project, {:action => 'settings'}, :class => "project")
  end
end

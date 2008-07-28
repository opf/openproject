# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < HelperTestCase
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  fixtures :projects, :repositories, :changesets, :trackers, :issue_statuses, :issues, :documents, :versions, :wikis, :wiki_pages, :wiki_contents, :roles, :enabled_modules

  def setup
    super
  end
  
  def test_auto_links
    to_test = {
      'http://foo.bar' => '<a class="external" href="http://foo.bar">http://foo.bar</a>',
      'http://foo.bar/~user' => '<a class="external" href="http://foo.bar/~user">http://foo.bar/~user</a>',
      'http://foo.bar.' => '<a class="external" href="http://foo.bar">http://foo.bar</a>.',
      'This is a link: http://foo.bar.' => 'This is a link: <a class="external" href="http://foo.bar">http://foo.bar</a>.',
      'A link (eg. http://foo.bar).' => 'A link (eg. <a class="external" href="http://foo.bar">http://foo.bar</a>).',
      'http://foo.bar/foo.bar#foo.bar.' => '<a class="external" href="http://foo.bar/foo.bar#foo.bar">http://foo.bar/foo.bar#foo.bar</a>.',
      'www.foo.bar' => '<a class="external" href="http://www.foo.bar">www.foo.bar</a>',
      'http://foo.bar/page?p=1&t=z&s=' => '<a class="external" href="http://foo.bar/page?p=1&#38;t=z&#38;s=">http://foo.bar/page?p=1&#38;t=z&#38;s=</a>',
      'http://foo.bar/page#125' => '<a class="external" href="http://foo.bar/page#125">http://foo.bar/page#125</a>',
      'http://foo@www.bar.com' => '<a class="external" href="http://foo@www.bar.com">http://foo@www.bar.com</a>',
      'ftp://foo.bar' => '<a class="external" href="ftp://foo.bar">ftp://foo.bar</a>',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_auto_mailto
    assert_equal '<p><a href="mailto:test@foo.bar" class="email">test@foo.bar</a></p>', 
      textilizable('test@foo.bar')
  end
  
  def test_inline_images
    to_test = {
      '!http://foo.bar/image.jpg!' => '<img src="http://foo.bar/image.jpg" alt="" />',
      'floating !>http://foo.bar/image.jpg!' => 'floating <div style="float:right"><img src="http://foo.bar/image.jpg" alt="" /></div>',
      'with class !(some-class)http://foo.bar/image.jpg!' => 'with class <img src="http://foo.bar/image.jpg" class="some-class" alt="" />',
      'with style !{width:100px;height100px}http://foo.bar/image.jpg!' => 'with style <img src="http://foo.bar/image.jpg" style="width:100px;height100px;" alt="" />',
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_textile_external_links
    to_test = {
      'This is a "link":http://foo.bar' => 'This is a <a href="http://foo.bar" class="external">link</a>',
      'This is an intern "link":/foo/bar' => 'This is an intern <a href="/foo/bar">link</a>',
      '"link (Link title)":http://foo.bar' => '<a href="http://foo.bar" title="Link title" class="external">link</a>',
      "This is not a \"Link\":\n\nAnother paragraph" => "This is not a \"Link\":</p>\n\n\n\t<p>Another paragraph",
      # no multiline link text
      "This is a double quote \"on the first line\nand another on a second line\":test" => "This is a double quote \"on the first line<br />\nand another on a second line\":test"
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_redmine_links
    issue_link = link_to('#3', {:controller => 'issues', :action => 'show', :id => 3}, 
                               :class => 'issue', :title => 'Error 281 when updating a recipe (New)')
    
    changeset_link = link_to('r1', {:controller => 'repositories', :action => 'revision', :id => 'ecookbook', :rev => 1},
                                   :class => 'changeset', :title => 'My very first commit')
    
    document_link = link_to('Test document', {:controller => 'documents', :action => 'show', :id => 1},
                                             :class => 'document')
    
    version_link = link_to('1.0', {:controller => 'versions', :action => 'show', :id => 2},
                                  :class => 'version')

    source_url = {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :path => ['some', 'file']}
    source_url_with_ext = {:controller => 'repositories', :action => 'entry', :id => 'ecookbook', :path => ['some', 'file.ext']}
    
    to_test = {
      # tickets
      '#3, #3 and #3.'              => "#{issue_link}, #{issue_link} and #{issue_link}.",
      # changesets
      'r1'                          => changeset_link,
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
      # escaping
      '!#3.'                        => '#3.',
      '!r1'                         => 'r1',
      '!document#1'                 => 'document#1',
      '!document:"Test document"'   => 'document:"Test document"',
      '!version#2'                  => 'version#2',
      '!version:1.0'                => 'version:1.0',
      '!version:"1.0"'              => 'version:"1.0"',
      '!source:/some/file'          => 'source:/some/file',
      # invalid expressions
      'source:'                     => 'source:',
      # url hash
      "http://foo.bar/FAQ#3"       => '<a class="external" href="http://foo.bar/FAQ#3">http://foo.bar/FAQ#3</a>',
    }
    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_wiki_links
    to_test = {
      '[[CookBook documentation]]' => '<a href="/wiki/ecookbook/CookBook_documentation" class="wiki-page">CookBook documentation</a>',
      '[[Another page|Page]]' => '<a href="/wiki/ecookbook/Another_page" class="wiki-page">Page</a>',
      # link with anchor
      '[[CookBook documentation#One-section]]' => '<a href="/wiki/ecookbook/CookBook_documentation#One-section" class="wiki-page">CookBook documentation</a>',
      '[[Another page#anchor|Page]]' => '<a href="/wiki/ecookbook/Another_page#anchor" class="wiki-page">Page</a>',
      # page that doesn't exist
      '[[Unknown page]]' => '<a href="/wiki/ecookbook/Unknown_page" class="wiki-page new">Unknown page</a>',
      '[[Unknown page|404]]' => '<a href="/wiki/ecookbook/Unknown_page" class="wiki-page new">404</a>',
      # link to another project wiki
      '[[onlinestore:]]' => '<a href="/wiki/onlinestore/" class="wiki-page">onlinestore</a>',
      '[[onlinestore:|Wiki]]' => '<a href="/wiki/onlinestore/" class="wiki-page">Wiki</a>',
      '[[onlinestore:Start page]]' => '<a href="/wiki/onlinestore/Start_page" class="wiki-page">Start page</a>',
      '[[onlinestore:Start page|Text]]' => '<a href="/wiki/onlinestore/Start_page" class="wiki-page">Text</a>',
      '[[onlinestore:Unknown page]]' => '<a href="/wiki/onlinestore/Unknown_page" class="wiki-page new">Unknown page</a>',
      # striked through link
      '-[[Another page|Page]]-' => '<del><a href="/wiki/ecookbook/Another_page" class="wiki-page">Page</a></del>',
      # escaping
      '![[Another page|Page]]' => '[[Another page|Page]]',
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
      "<!-- opening comment" => "<p>&lt;!-- opening comment</p>"
    }
    to_test.each { |text, result| assert_equal result, textilizable(text) }
  end
  
  def test_allowed_html_tags
    to_test = {
      "<pre>preformatted text</pre>" => "<pre>preformatted text</pre>",
      "<notextile>no *textile* formatting</notextile>" => "no *textile* formatting",
    }
    to_test.each { |text, result| assert_equal result, textilizable(text) }
  end
  
  def test_wiki_links_in_tables
    to_test = {"|[[Page|Link title]]|[[Other Page|Other title]]|\n|Cell 21|[[Last page]]|" =>
                 '<tr><td><a href="/wiki/ecookbook/Page" class="wiki-page new">Link title</a></td>' +
                 '<td><a href="/wiki/ecookbook/Other_Page" class="wiki-page new">Other title</a></td>' +
                 '</tr><tr><td>Cell 21</td><td><a href="/wiki/ecookbook/Last_page" class="wiki-page new">Last page</a></td></tr>'
    }
    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<table>#{result}</table>", textilizable(text).gsub(/[\t\n]/, '') }
  end
  
  def test_text_formatting
    to_test = {'*_+bold, italic and underline+_*' => '<strong><em><ins>bold, italic and underline</ins></em></strong>',
               '(_text within parentheses_)' => '(<em>text within parentheses</em>)'
              }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_wiki_horizontal_rule
    assert_equal '<hr />', textilizable('---')
    assert_equal '<p>Dashes: ---</p>', textilizable('Dashes: ---')
  end
  
  def test_table_of_content
    raw = <<-RAW
{{toc}}

h1. Title

Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

h2. Subtitle

Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.

h2. Subtitle with %{color:red}red text%

h1. Another title

RAW

    expected = '<ul class="toc">' +
               '<li class="heading1"><a href="#Title">Title</a></li>' +
               '<li class="heading2"><a href="#Subtitle">Subtitle</a></li>' + 
               '<li class="heading2"><a href="#Subtitle-with-red-text">Subtitle with red text</a></li>' +
               '<li class="heading1"><a href="#Another-title">Another title</a></li>' +
               '</ul>'
               
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
  
  def test_macro_hello_world
    text = "{{hello_world}}"
    assert textilizable(text).match(/Hello world!/)
    # escaping
    text = "!{{hello_world}}"
    assert_equal '<p>{{hello_world}}</p>', textilizable(text)
  end
  
  def test_macro_include
    @project = Project.find(1)
    # include a page of the current project wiki
    text = "{{include(Another page)}}"
    assert textilizable(text).match(/This is a link to a ticket/)
    
    @project = nil
    # include a page of a specific project wiki
    text = "{{include(ecookbook:Another page)}}"
    assert textilizable(text).match(/This is a link to a ticket/)

    text = "{{include(ecookbook:)}}"
    assert textilizable(text).match(/CookBook documentation/)

    text = "{{include(unknowidentifier:somepage)}}"
    assert textilizable(text).match(/Unknow project/)
  end
  
  def test_date_format_default
    today = Date.today
    Setting.date_format = ''    
    assert_equal l_date(today), format_date(today)
  end
  
  def test_date_format
    today = Date.today
    Setting.date_format = '%d %m %Y'
    assert_equal today.strftime('%d %m %Y'), format_date(today)
  end
  
  def test_time_format_default
    now = Time.now
    Setting.date_format = ''
    Setting.time_format = ''    
    assert_equal l_datetime(now), format_time(now)
    assert_equal l_time(now), format_time(now, false)
  end
  
  def test_time_format
    now = Time.now
    Setting.date_format = '%d %m %Y'
    Setting.time_format = '%H %M'
    assert_equal now.strftime('%d %m %Y %H %M'), format_time(now)
    assert_equal now.strftime('%H %M'), format_time(now, false)
  end
end

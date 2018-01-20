#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe ApplicationHelper, type: :helper do
  include OpenProject::StaticRouting
  include WorkPackagesHelper

  before do
    # @project variable is used by helper
    @project = FactoryGirl.create :valid_project
    @project.reload # reload references to indirectly created entities (e.g. wiki)

    @admin = FactoryGirl.create :admin
    @anonymous = FactoryGirl.create :anonymous
    @non_member = FactoryGirl.create :user
    @project_member = FactoryGirl.create :user,
                                         member_in_project: @project,
                                         member_through_role: FactoryGirl.create(:role,
                                                                                 permissions: [:view_work_packages, :edit_work_packages,
                                                                                               :browse_repository, :view_changesets, :view_wiki_pages])

    @issue = FactoryGirl.create :work_package, project: @project, author: @project_member, type: @project.types.first

    file = LegacyFileHelpers.mock_uploaded_file name: 'logo.gif',
                                          content_type: 'image/gif',
                                          content: 'not actually a gif',
                                          binary: true
    @attachment = FactoryGirl.create :attachment,
                                     author: @project_member,
                                     file: file,
                                     content_type: 'image/gif',
                                     container: @issue,
                                     description: 'This is a logo'

    allow(User).to receive(:current).and_return(@project_member)
  end

  it 'should auto links' do
    to_test = {
      'http://foo.bar' => '<a class="external icon-context icon-copy" href="http://foo.bar">http://foo.bar</a>',
      'http://foo.bar/~user' => '<a class="external icon-context icon-copy" href="http://foo.bar/~user">http://foo.bar/~user</a>',
      'http://foo.bar.' => '<a class="external icon-context icon-copy" href="http://foo.bar">http://foo.bar</a>.',
      'https://foo.bar.' => '<a class="external icon-context icon-copy" href="https://foo.bar">https://foo.bar</a>.',
      'This is a link: http://foo.bar.' => 'This is a link: <a class="external icon-context icon-copy" href="http://foo.bar">http://foo.bar</a>.',
      'A link (eg. http://foo.bar).' => 'A link (eg. <a class="external icon-context icon-copy" href="http://foo.bar">http://foo.bar</a>).',
      'http://foo.bar/foo.bar#foo.bar.' => '<a class="external icon-context icon-copy" href="http://foo.bar/foo.bar#foo.bar">http://foo.bar/foo.bar#foo.bar</a>.',
      'http://www.foo.bar/Test_(foobar)' => '<a class="external icon-context icon-copy" href="http://www.foo.bar/Test_(foobar)">http://www.foo.bar/Test_(foobar)</a>',
      '(see inline link : http://www.foo.bar/Test_(foobar))' => '(see inline link : <a class="external icon-context icon-copy" href="http://www.foo.bar/Test_(foobar)">http://www.foo.bar/Test_(foobar)</a>)',
      '(see inline link : http://www.foo.bar/Test)' => '(see inline link : <a class="external icon-context icon-copy" href="http://www.foo.bar/Test">http://www.foo.bar/Test</a>)',
      '(see inline link : http://www.foo.bar/Test).' => '(see inline link : <a class="external icon-context icon-copy" href="http://www.foo.bar/Test">http://www.foo.bar/Test</a>).',
      '(see "inline link":http://www.foo.bar/Test_(foobar))' => '(see <a href="http://www.foo.bar/Test_(foobar)" class="external">inline link</a>)',
      '(see "inline link":http://www.foo.bar/Test)' => '(see <a href="http://www.foo.bar/Test" class="external">inline link</a>)',
      '(see "inline link":http://www.foo.bar/Test).' => '(see <a href="http://www.foo.bar/Test" class="external">inline link</a>).',
      'www.foo.bar' => '<a class="external icon-context icon-copy" href="http://www.foo.bar">www.foo.bar</a>',
      'http://foo.bar/page?p=1&t=z&s=' => '<a class="external icon-context icon-copy" href="http://foo.bar/page?p=1&#38;t=z&#38;s=">http://foo.bar/page?p=1&#38;t=z&#38;s=</a>',
      'http://foo.bar/page#125' => '<a class="external icon-context icon-copy" href="http://foo.bar/page#125">http://foo.bar/page#125</a>',
      'http://foo@www.bar.com' => '<a class="external icon-context icon-copy" href="http://foo@www.bar.com">http://foo@www.bar.com</a>',
      'http://foo:bar@www.bar.com' => '<a class="external icon-context icon-copy" href="http://foo:bar@www.bar.com">http://foo:bar@www.bar.com</a>',
      'ftp://foo.bar' => '<a class="external icon-context icon-copy" href="ftp://foo.bar">ftp://foo.bar</a>',
      'ftps://foo.bar' => '<a class="external icon-context icon-copy" href="ftps://foo.bar">ftps://foo.bar</a>',
      'sftp://foo.bar' => '<a class="external icon-context icon-copy" href="sftp://foo.bar">sftp://foo.bar</a>',
      # two exclamation marks
      'http://example.net/path!602815048C7B5C20!302.html' => '<a class="external icon-context icon-copy" href="http://example.net/path!602815048C7B5C20!302.html">http://example.net/path!602815048C7B5C20!302.html</a>',
      # escaping
      'http://foo"bar' => '<a class="external icon-context icon-copy" href="http://foo&quot;bar">http://foo&quot;bar</a>',
      # wrap in angle brackets
      '<http://foo.bar>' => '&lt;<a class="external icon-context icon-copy" href="http://foo.bar">http://foo.bar</a>&gt;'
    }
    to_test.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text) }
  end

  it 'should auto mailto' do
    assert_dom_equal '<p><a class="email" href="mailto:test@foo.bar">test@foo.bar</a></p>',
                     helper.format_text('test@foo.bar')
  end

  it 'should inline images' do
    to_test = {
      '!http://foo.bar/image.jpg!' => '<img src="http://foo.bar/image.jpg" alt="" />',
      'floating !>http://foo.bar/image.jpg!' => 'floating <div style="float:right"><img src="http://foo.bar/image.jpg" alt="" /></div>',
      'with class !(some-class)http://foo.bar/image.jpg!' => 'with class <img src="http://foo.bar/image.jpg" class="some-class" alt="" />',
      # inline styles should be stripped
      'with style !{width:100px;height100px}http://foo.bar/image.jpg!' => 'with style <img src="http://foo.bar/image.jpg" alt="" />',
      'with title !http://foo.bar/image.jpg(This is a title)!' => 'with title <img src="http://foo.bar/image.jpg" title="This is a title" alt="This is a title" />',
      'with title !http://foo.bar/image.jpg(This is a double-quoted "title")!' => 'with title <img src="http://foo.bar/image.jpg" title="This is a double-quoted &quot;title&quot;" alt="This is a double-quoted &quot;title&quot;" />',
    }
    to_test.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text) }
  end

  it 'should inline images inside tags' do
    raw = <<-RAW
h1. !foo.png! Heading

Centered image:

p=. !bar.gif!
RAW

    assert helper.format_text(raw).include?('<img src="foo.png" alt="" />')
    assert helper.format_text(raw).include?('<img src="bar.gif" alt="" />')
  end

  it 'should attached images' do
    to_test = {
      'Inline image: !logo.gif!' => "Inline image: <img src=\"/attachments/#{@attachment.id}\" title=\"This is a logo\" alt=\"This is a logo\" />",
      'Inline image: !logo.GIF!' => "Inline image: <img src=\"/attachments/#{@attachment.id}\" title=\"This is a logo\" alt=\"This is a logo\" />",
      'No match: !ogo.gif!' => 'No match: <img src="ogo.gif" alt="" />',
      'No match: !ogo.GIF!' => 'No match: <img src="ogo.GIF" alt="" />',
      # link image
      '!logo.gif!:http://foo.bar/' => "<a href=\"http://foo.bar/\"><img src=\"/attachments/#{@attachment.id}\" title=\"This is a logo\" alt=\"This is a logo\" /></a>",
    }
    to_test.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text, attachments: [@attachment]) }
  end

  it 'should textile external links' do
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
    to_test.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text) }
  end

  it 'should textile relative to full links in a controller', :with_mock_request_for_helper do
    {
      # shouldn't change non-relative links
      'This is a "link":http://foo.bar' => 'This is a <a href="http://foo.bar" class="external">link</a>',
      'This is an intern "link":/foo/bar' => 'This is an intern <a href="http://test.host/foo/bar">link</a>',
      'This is an intern "link":/foo/bar and an extern "link":http://foo.bar' => 'This is an intern <a href="http://test.host/foo/bar">link</a> and an extern <a href="http://foo.bar" class="external">link</a>',
    }.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text, only_path: false) }
  end

  it 'should textile relative to full links in the mailer' do
    # mimic the mailer default_url_options
    @controller.class.class_eval do
      def self.default_url_options
        ::UserMailer.default_url_options
      end
    end

    {
      # shouldn't change non-relative links
      'This is a "link":http://foo.bar' => 'This is a <a href="http://foo.bar" class="external">link</a>',
      'This is an intern "link":/foo/bar' => 'This is an intern <a href="http://test.host/foo/bar">link</a>',
      'This is an intern "link":/foo/bar and an extern "link":http://foo.bar' => 'This is an intern <a href="http://test.host/foo/bar">link</a> and an extern <a href="http://foo.bar" class="external">link</a>',
    }.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text, only_path: false) }
  end

  it 'should cross project redmine links' do
    version = FactoryGirl.create :version,
                                 name: '1.0',
                                 project: @project

    to_test = {
      # versions
      'version:"1.0"'                         => 'version:"1.0"',
      "#{@project.identifier}:version:\"1.0\"" => "<a class=\"version\" href=\"/versions/#{version.id}\">1.0</a>",
      'invalid:version:"1.0"'                 => 'invalid:version:"1.0"'
    }

    repository = FactoryGirl.create :repository_subversion,
                                    project: @project

    changeset = FactoryGirl.create :changeset,
                                   repository: repository,
                                   comments: 'This commit fixes #1, #2 and references #1 & #3'
    identifier = @project.identifier

    source_link = link_to("#{identifier}:source:/some/file",
                          { controller: 'repositories',
                            action: 'entry',
                            project_id: identifier,
                            path: 'some/file' },
                          class: 'source')
    changeset_link = link_to("#{identifier}:r#{changeset.revision}",
                             { controller: 'repositories',
                               action: 'revision',
                               project_id: identifier,
                               rev: changeset.revision },
                             class: 'changeset',
                             title: 'This commit fixes #1, #2 and references #1 & #3')

    to_test.merge!(
      # changeset
      "r#{changeset.revision}"                => "r#{changeset.revision}",
      "#{@project.identifier}:r#{changeset.revision}"  => changeset_link,
      "invalid:r#{changeset.revision}"        => "invalid:r#{changeset.revision}",
      # source
      'source:/some/file'                     => 'source:/some/file',
      "#{@project.identifier}:source:/some/file"       => source_link,
      'invalid:source:/some/file'             => 'invalid:source:/some/file',
    )

    # helper.format_text "sees" the text is parses from the_other_project (and not @project)
    the_other_project = FactoryGirl.create :valid_project

    to_test.each do |text, result|
      assert_dom_equal "<p>#{result}</p>",
                       helper.format_text(text, project: the_other_project), "#{text} failed"
    end
  end

  it 'should redmine links git commit' do
    allow(User).to receive(:current).and_return(@admin)
    changeset_link = link_to('abcd',
                             {
                               controller: 'repositories',
                               action:     'revision',
                               project_id: @project.identifier,
                               rev:        'abcd',
                             },
                             class: 'changeset', title: 'test commit')
    to_test = {
      'commit:abcd' => changeset_link,
    }
    r = Repository::Git.create!(project: @project, scm_type: 'local', url: '/tmp/test/git')
    assert r
    c = Changeset.new(repository: r,
                      committed_on: Time.now,
                      revision: 'abcd',
                      scmid: 'abcd',
                      comments: 'test commit')
    assert(c.save)
    @project.reload
    to_test.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text) }
  end

  it 'should attachment links' do
    attachment_link = link_to('logo.gif', { controller: 'attachments', action: 'download', id: @attachment }, class: 'attachment')
    to_test = {
      'attachment:logo.gif' => attachment_link
    }
    to_test.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text, attachments: [@attachment]), "#{text} failed" }
  end

  it 'should html tags' do
    to_test = {
      '<div>content</div>' => '<p>&lt;div&gt;content&lt;/div&gt;</p>',
      "<div class=\"bold\">content</div>" => "<p>&lt;div class=\"bold\"&gt;content&lt;/div&gt;</p>",
      '<script>some script;</script>' => '<p>&lt;script&gt;some script;&lt;/script&gt;</p>',
      # do not escape pre/code tags
      "<pre>\nline 1\nline2</pre>" => "<pre>\nline 1\nline2</pre>",
      "<pre><code>\nline 1\nline2</code></pre>" => "<pre><code>\nline 1\nline2</code></pre>",
      '<pre><div>content</div></pre>' => '<pre>&lt;div&gt;content&lt;/div&gt;</pre>',
      'HTML comment: <!-- no comments -->' => '<p>HTML comment: &lt;!-- no comments --&gt;</p>',
      '<!-- opening comment' => '<p>&lt;!-- opening comment</p>',
      # remove attributes except class
      "<pre class='foo'>some text</pre>" => "<pre class='foo'>some text</pre>",
      '<pre class="foo">some text</pre>' => '<pre class="foo">some text</pre>',
      "<pre class='foo bar'>some text</pre>" => "<pre class='foo bar'>some text</pre>",
      '<pre class="foo bar">some text</pre>' => '<pre class="foo bar">some text</pre>',
      "<pre onmouseover='alert(1)'>some text</pre>" => '<pre>some text</pre>',
      # xss
      '<pre><code class=""onmouseover="alert(1)">text</code></pre>' => '<pre><code>text</code></pre>',
      '<pre class=""onmouseover="alert(1)">text</pre>' => '<pre>text</pre>',
    }
    to_test.each { |text, result| assert_dom_equal result, helper.format_text(text) }
  end

  it 'should allowed html tags' do
    to_test = {
      '<pre>preformatted text</pre>' => '<pre>preformatted text</pre>',
      '<notextile>no *textile* formatting</notextile>' => 'no *textile* formatting',
      '<notextile>this is <tag>a tag</tag></notextile>' => 'this is &lt;tag&gt;a tag&lt;/tag&gt;'
    }
    to_test.each { |text, result| assert_dom_equal result, helper.format_text(text) }
  end

  it 'should pre tags' do
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

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), helper.format_text(raw).gsub(%r{[\r\n\t]}, '')
  end

  it 'should syntax highlight' do
    raw = <<-RAW
<pre><code class="ruby">
# Some ruby code here
</code></pre>
RAW

    expected = <<-EXPECTED
<pre><code class="ruby CodeRay"><span class=\"CodeRay\"><span class="line-numbers"><a href=\"#n1\" name=\"n1\">1</a></span><span class="comment"># Some ruby code here</span></span>
</code></pre>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), helper.format_text(raw).gsub(%r{[\r\n\t]}, '')
  end

  it 'should wiki links in tables' do
    @project.wiki.start_page = 'Page'
    @project.wiki.save!
    FactoryGirl.create :wiki_page_with_content, wiki: @project.wiki, title: 'Other page'
    FactoryGirl.create :wiki_page_with_content, wiki: @project.wiki, title: 'Last page'

    to_test = { "|[[Page|Link title]]|[[Other Page|Other title]]|\n|Cell 21|[[Last page]]|" =>
                 "<tr><td><a class=\"wiki-page new\" href=\"/projects/#{@project.identifier}/wiki/page\">Link title</a></td>" +
                 "<td><a class=\"wiki-page\" href=\"/projects/#{@project.identifier}/wiki/other-page\">Other title</a></td>" +
                 "</tr><tr><td>Cell 21</td><td><a class=\"wiki-page\" href=\"/projects/#{@project.identifier}/wiki/last-page\">Last page</a></td></tr>"
    }

    to_test.each { |text, result| assert_dom_equal "<table>#{result}</table>", helper.format_text(text).gsub(/[\t\n]/, '') }
  end

  it 'should text formatting' do
    to_test = { '*_+bold, italic and underline+_*' => '<strong><em><ins>bold, italic and underline</ins></em></strong>',
                '(_text within parentheses_)' => '(<em>text within parentheses</em>)',
                'a *Humane Web* Text Generator' => 'a <strong>Humane Web</strong> Text Generator',
                'a H *umane* W *eb* T *ext* G *enerator*' => 'a H <strong>umane</strong> W <strong>eb</strong> T <strong>ext</strong> G <strong>enerator</strong>',
                'a *H* umane *W* eb *T* ext *G* enerator' => 'a <strong>H</strong> umane <strong>W</strong> eb <strong>T</strong> ext <strong>G</strong> enerator',
              }
    to_test.each { |text, result| assert_dom_equal "<p>#{result}</p>", helper.format_text(text) }
  end

  it 'should wiki horizontal rule' do
    assert_equal '<hr />', helper.format_text('---')
    assert_equal '<p>Dashes: ---</p>', helper.format_text('Dashes: ---')
  end

  it 'should footnotes' do
    raw = <<-RAW
This is some text[1].

fn1. This is the foot note
RAW

    expected = <<-EXPECTED
<p>This is some text<sup><a href=\"#fn1\">1</a></sup>.</p>
<p id="fn1" class="footnote"><sup>1</sup> This is the foot note</p>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), helper.format_text(raw).gsub(%r{[\r\n\t]}, '')
  end

  it 'should headings without url' do
    raw = 'h1. Some heading'
    expected = %|<a name="Some-heading"></a>\n<h1 >Some heading<a href="#Some-heading" class="wiki-anchor">&para;</a></h1>|

    assert_equal expected, helper.format_text(raw)
  end

  it 'should table of content' do
    @project.wiki.start_page = 'Wiki'
    @project.wiki.save!
    FactoryGirl.create :wiki_page_with_content, wiki: @project.wiki, title: 'Wiki'
    FactoryGirl.create :wiki_page_with_content, wiki: @project.wiki, title: 'another Wiki'

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

h2. "Project Name !/attachments/#{@attachment.id}/#{@attachment.filename}!":/projects/#{@project.identifier}/issues

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
                '<li><a href="#Project-Name">Project Name </a></li>' +
                '</ul>' +
                '</li>' +
                '</ul>'

    assert helper.format_text(raw).gsub("\n", '').include?(expected), helper.format_text(raw)
  end

  it 'should table of content should contain included page headings' do
    @project.wiki.start_page = 'Wiki'
    @project.save!
    page  = FactoryGirl.create :wiki_page_with_content, wiki: @project.wiki, title: 'Wiki'
    child = FactoryGirl.create :wiki_page, wiki: @project.wiki, title: 'Child_1', parent: page
    child.content = FactoryGirl.create :wiki_content, page: child, text: "h1. Child page 1\n\nThis is a child page"
    child.save!

    raw = <<-RAW
{{toc}}

h1. Included

{{include(Child_1)}}
RAW

    expected = '<ul class="toc">' +
               '<li><a href="#Included">Included</a></li>' +
               '<li><a href="#Child-page-1">Child page 1</a></li>' +
               '</ul>'

    assert helper.format_text(raw).gsub("\n", '').include?(expected), helper.format_text(raw)
  end

  it 'should default formatter' do
    Setting.text_formatting = 'unknown'
    text = 'a *link*: http://www.example.net/'
    assert_equal '<p>a *link*: <a href="http://www.example.net/">http://www.example.net/</a></p>', helper.format_text(text)
    Setting.text_formatting = 'textile'
  end

  it 'should due date distance in words' do
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

  it 'should link to user' do
    t = link_to_user(@admin)
    assert_dom_equal "<a href=\"/users/#{@admin.id}\">#{@admin.name}</a>", t
  end

  it 'should link to user should not link to locked user' do
    user = FactoryGirl.build :user
    user.lock!
    assert user.locked?
    t = link_to_user(user)
    assert_equal user.name, t
  end

  it 'should link to user should not link to anonymous' do
    user = User.anonymous
    assert user.anonymous?
    t = link_to_user(user)
    assert_equal ::I18n.t(:label_user_anonymous), t
  end

  it 'should link to project' do
    p_id = @project.identifier
    p_name = @project.name
    assert_dom_equal %(<a href="/projects/#{p_id}">#{p_name}</a>),
                     link_to_project(@project)
    assert_dom_equal %(<a href="/projects/#{p_id}/settings">#{p_name}</a>),
                     link_to_project(@project, action: 'settings')
    assert_dom_equal %(<a href="/projects/#{p_id}/settings/members">#{p_name}</a>),
                     link_to_project(@project, action: 'settings', tab: 'members')
    assert_dom_equal %(<a href="#{root_url}projects/#{p_id}?jump=blah">#{p_name}</a>),
                     link_to_project(@project, only_path: false, jump: 'blah')
    assert_dom_equal %(<a class="project" href="/projects/#{p_id}/settings">#{p_name}</a>),
                     link_to_project(@project, { action: 'settings' }, class: 'project')
  end
end

---
  title: OpenProject 7.4.3
  sidebar_navigation:
      title: 7.4.3
  release_version: 7.4.3
  release_date: 2018-04-03
---


# OpenProject 7.4.3

Several security fixes have been made as part of the Ruby 2.4.4 release
as well as in gems used by OpenProject. We urge users to update their
Ruby installations. If you’re using the packaged installation, this
package will contain all necessary fixes.

## Security fixes

  - Updates rails-html-sanitizer to 1.0.4 to
    address [CVE-2018-3741](http://seclists.org/oss-sec/2018/q1/262)
  - Updates loofah to 2.2.2 to
    address [CVE-2018-8048](http://seclists.org/oss-sec/2018/q1/253)
  - Updates Ruby 2.4.4 to address the following CVEs:
      - [CVE-2017-17742: HTTP response splitting in
        WEBrick](https://www.ruby-lang.org/en/news/2018/03/28/http-response-splitting-in-webrick-cve-2017-17742/)
      - [CVE-2018-6914: Unintentional file and directory creation with
        directory traversal in tempfile and
        tmpdir](https://www.ruby-lang.org/en/news/2018/03/28/unintentional-file-and-directory-creation-with-directory-traversal-cve-2018-6914/)
      - [CVE-2018-8777: DoS by large request in
        WEBrick](https://www.ruby-lang.org/en/news/2018/03/28/large-request-dos-in-webrick-cve-2018-8777/)
      - [CVE-2018-8778: Buffer under-read in
        String\#unpack](https://www.ruby-lang.org/en/news/2018/03/28/buffer-under-read-unpack-cve-2018-8778/)
      - [CVE-2018-8779: Unintentional socket creation by poisoned NUL
        byte in UNIXServer and
        UNIXSocket](https://www.ruby-lang.org/en/news/2018/03/28/poisoned-nul-byte-unixsocket-cve-2018-8779/)
      - [CVE-2018-8780: Unintentional directory traversal by poisoned
        NUL byte in
        Dir](https://www.ruby-lang.org/en/news/2018/03/28/poisoned-nul-byte-dir-cve-2018-8780/)

For more information, please refer to the [Ruby 2.4.4 release
announcement](https://www.ruby-lang.org/en/news/2018/03/28/ruby-2-4-4-released/).

## Changes

  - A separate icon has been included for the Two-factor authentication
    plugin ([\#27150](https://community.openproject.com/wp/27150))
  - SMTP authentication *none* can now be configured through the system
    settings. ([\#27284](https://community.openproject.com/wp/27284))
  - For further information on the 7.4.3 release, please refer to
    the [Changelog
    v7.4.3](https://community.openproject.com/versions/890)<span style="font-size: 1.125rem;"> or take
    a look
    at </span>[GitHub](https://github.com/opf/openproject/tree/v7.4.3)<span style="font-size: 1.125rem;">.</span>



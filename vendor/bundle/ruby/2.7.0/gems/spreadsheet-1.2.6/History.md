### 1.2.6 22.1.2020
Author: tetsuya-ogawa <tetsuya.ogawa87@gmail.com>
Date:   Wed Jan 22 15:18:00 2020 +0900

* add instance method "<<" to Spreadsheet::Worksheet

### 1.2.5 23.10.2019
Author: Jesús Manuel García Muñoz <jesus@bebanjo.com>
Date:   Wed Oct 23 20:26:01 2019 +0200

* Fixes unrecognized date format

### 1.2.4 24.05.2019
Author: Cyril Champier <cyril.champier@doctolib.com>
Date:   Fri May 24 12:56:52 2019 +0200

* correct ruby version check
* can read frozen string io

### 1.2.3 12.03.2019
Author: taichi <taichi730@gmail.com>
Date:   Tue Mar 12 22:29:12 2019 +0900

* Remove workaround for ruby-ole gem

### 1.2.2 01.03.2019
Author: taichi <taichi730@gmail.com>
Date:   Fri Mar 1 13:00:28 2019 +0900

* fixed unit test errors caused by frozen-string-literal
* removed ruby 2.3.8 with frozen-string-literal from CI regression
  (It seems that standard libraries for this version does not support the
  feature enough.)
* enable '--enable-frozen-string-literal' option on CI test

### 1.2.1 28.02.2019
Author: taichi <taichi730@gmail.com>
Date:   Thu Feb 28 10:30:46 2019 +0900

* Merge pull request #231 from taichi-ishitani/separated_version_file  
* Merge pull request #230 from taichi-ishitani/frozen_string_literal_support
    
### 1.2.0 17.2.2019
Author: James McLaren <jamesmclaren555@gmail.com>
* spreadsheet-1.2.0.gem released

### 1.1.9 26.1.2019
Author: Nick Weiland <nickweiland@gmail.com>
* spreadsheet-1.1.9.gem released.

### 1.1.8 / 20.08.2018
Author: VitaliyAdamkov <adamkov@tex.ua>
Date:   Mon Aug 20 09:48:31 2018 +0300

* Cancel :lazy usage
* Use lazy select to speed up a little
* Omit rails :try usage
* stub for :postread_worksheet method
* sometimes it selects empty array..

Author: 545ch4 <s@rprojekt.org>
Date:   Wed Mar 28 15:33:04 2018 +0200

* [ruby-2.4] Fix weird first line of spreadsheet.gemspec
* Doesn't seem to be a valid .gemspec command/field.

### 1.1.7 / 15.03.2018

Author: Maarten Brouwers <github@murb.nl>
Date:   Thu Mar 15 15:10:23 2018 +0100

* shadowing outer local variable - i
    
* Running rake resulted in the following warning: `lib/spreadsheet/worksheet.rb:345: warning: shadowing outer local variable - i`; this patch fixes that.

### 1.1.6 / 12.03.2018

Author: Todd Hambley <thambley@travelleaders.com>
Date:   Mon Mar 12 14:20:39 2018 -0400

* fix reject for ruby 1.8.7
* fix using invalid code pages when writing workbook

### 1.1.5 / 20.11.2017

Author: Paco Guzmán <pacoguzman@users.noreply.github.com>
Date:   Sun Nov 19 18:10:57 2017 +0100

* Avoid creating a class variable, that variable cannot be garbage collected and it retains a lot of memory

### 1.1.4 / 02.12.2016

Author: Richard Lee <dlackty@gmail.com>
Date:   Mon Jan 16 03:52:42 2017 +0800

* Update Travis CI rubies

Author: Zeno R.R. Davatz <zdavatz@ywesee.com>
Date:   Fri Dec 2 10:36:20 2016 +0100

* updated Gem to use the correct License on Rubygems to GPL-3.0 as stated in the LICENSE File.

### 1.1.3 / 06.08.2016

Author: Alexandre Balon-Perin <abalonperin@gilt.jp>
Date:   Fri Aug 5 17:19:29 2016 +0900

* Fix issue with iconv on Ubuntu 12.04
* This fix is related to a bug in the iconv implementation packaged in libc6 on Ubuntu 12.04
* For some reasons, the encoding options //TRANSLIT//IGNORE are improperly applied.
* When //TRANSLIT is specified, instead of rescuing errors related to //TRANSLIT and checking if the //IGNORE is set, the code simply crashes.

### 1.1.2 / 29.03.2016

Author: Aleksandr Boykov <aleksandr.boykov@parelio.com>
Date:   Mon Mar 28 14:07:35 2016 -0400

fixes compact! method when the excel document has dates

### 1.1.1 / 03.01.2016

Author: ChouAndy <chouandy@ecoworkinc.com>
Date:   Sun Jan 3 17:26:18 2016 +0800

Fixed Unknown Codepage 0x5212

### 1.1.0 / 08.12.2015

Author: Matthew Boeh <matt@crowdcompass.com>
Date:   Mon Dec 7 11:18:55 2015 -0800

* Disregard locale indicators when determining whether a cell contains a date/time.

### 1.0.9 / 18.11.2015

Author: 545ch4 <s@rprojekt.org>
Date:   Mon Nov 16 10:26:27 2015 +0100

* Add smart method compact! to worksheet
* Use compact! to reduce the number of rows and columns by striping empty one at both ends.

### 1.0.8 / 20.10.2015

commit e9bd1dd34998803b63460f4951e9aa34e569bd8f
Author: Pierre Laprée <pilap82@users.noreply.github.com>
Date:   Tue Oct 20 03:12:22 2015 +0200

* Remove stray `puts`
* A `puts` instruction pollutes the log and doesn't serve any purpose. As such, we propose its removal.

### 1.0.7 / 23.09.2015

Author: Leopoldo Lee Agdeppa III <leopoldo.agdeppa@gmail.com>
Date:   Wed Sep 23 08:24:16 2015 +0800

* Update worksheet.rb
* Adding Test for Freeze panels
* Update worksheet.rb
* Added freeze (freeze panel) functionality
* Update worksheet.rb
* Freeze (freeze window) functionality added to worksheet

### 1.0.6 / 14.09.2015

Author: Yann Plancqueel <yplancqueel@gmail.com>
Date:   Sat Sep 12 15:32:49 2015 +0200

* bugfix opening a spreadsheet with missing format

### 1.0.5 / 01.09.2015

Author: kunashir <kunashir@list.ru>
Date:   Tue Sep 1 13:12:49 2015 +0300

* add format for nubmer with out #

### 1.0.4 / 18.07.2015

Author: Edmund Mai <edmundm@crowdtap.com>
Date:   Fri Jul 17 15:32:47 2015 -0400

* Fixes slow Spreadsheet.open response in console

### 1.0.3 / 10.03.2015

Author: Robert Eshleman <c.robert.eshleman@gmail.com>
Date:   Mon Mar 9 09:47:59 2015 -0400

* Update `ruby-ole` to `1.2.11.8`
** `ruby-ole` <= `1.2.11.7` throws a duplicated key warning in Ruby 2.2.
** This commit updates `ruby-ole` to `1.2.11.8`, which fixes this warning.
** Related discussion: [aquasync/ruby-ole#15] - [aquasync/ruby-ole#15]: https://github.com/aquasync/ruby-ole/issues/15

### 1.0.2 / 05.03.2015

Author: cantin <cantin2010@gmail.com>
Date:   Thu Mar 5 16:13:59 2015 +0800

* add Rational support
* add rational requirement
* use old rational syntax in test

### 1.0.1 / 22.01.2015

Author: Sergey Konotopov <lalalalalala@gmail.com>
Date:   Wed Jan 21 13:19:56 2015 +0300

* Fixing Excel::Worksheet#dimensions

### 1.0.0 / 29.08.2014

* added spreadsheet/errors.rb to Manifest.txt

### 0.9.9 / 28.08.2014

Author: PikachuEXE <pikachuexe@gmail.com>
Date:   Wed Aug 27 09:55:41 2014 +0800

* Add custom error classes
* Raise custom error for unknown code page or unsupported encoding

### 0.9.8 / 19.08.2014

Author: PikachuEXE <pikachuexe@gmail.com>
Date:   Tue Aug 19 09:54:30 2014 +0800

* Fix Encoding for MRI 2.1.0

### 0.9.7 / 04.02.2014

* Avoid exception when reading text objects
* Add test for drawings with text (currenty broken)
* Restore xlsopcodes script which had been mangled in previous commits
* Remove ruby 1.9 from roadmap, it's already working fine
* Fix excel file format documentation which had been mangled in previous commits

### 0.9.6 / 02.12.2013

Author: Malcolm Blyth <trashbat@co.ck>
Date:   Mon Dec 2 11:44:25 2013 +0000

* Fixed issue whereby object author being null caused a gross failure.
* Now returns object author as an empty string

### 0.9.5 / 20.11.2013

Author: Malcolm Blyth <trashbat@co.ck>
Date:   Tue Nov 19 15:14:31 2013 +0000

* Bumped revision
* Fixed author stringname error (damn this 1 based counting)
* Updating integration test to check for comments contained within the cells. 
* Checking also for multiple comments in a sheet

### 0.9.4 / 12.11.2013

* Updated Manifest.txt

### 0.9.3 / 12.11.2013

commit e15d8b45d7587f7ab78c7b7768de720de9961341 (refs/remotes/gguerrero/master)
Author: Guillermo Guerrero <g.guerrero.bus@gmail.com>
Date:   Tue Nov 12 11:50:30 2013 +0100

* Refactor update_format for cloning format objects
* Added lib/spreadsheet/note.rb to Manifest.txt file
* 'update_format' methods now receive a hash of key => values to update

Author: Przemysław Ciąćka <przemyslaw.ciacka@gmail.com>
Date:   Tue Nov 12 00:07:57 2013 +0100

* Added lib/spreadsheet/note.rb to Manifest.txt file

### 0.9.2 / 11.11.2013

commit e70dc0dbbc966ce312b45b0d44d0c3b1dc10aad6
Author: Malcolm Blyth <trashbat@co.ck>
Date:   Mon Nov 11 15:53:58 2013 +0000

*Corrected compressed string formatting - *U (UTF-8) should have been *S (16-bit string)
*Completed addition of notes hash to worksheet
*Bumped revision
*Updated reader and note
Note class no longer extends string for simplicity and debug of class (pp now works a bit more easily)
Reader has had loads of changes (still WIP) to allow objects of class
Note and NoteObject to be created and combined in the postread_worksheet function
*Adding noteObject to deal with the Object (and ultimately text comment field) created by excel's madness

### 0.9.1 / 24.10.2013

* Author: Matti Lehtonen <matti.lehtonen@puujaa.com>
Date:   Thu Oct 24 09:41:50 2013 +0300

* Add support for worksheet visibility

### 0.9.0 / 16.09.2013

* Author: Pavel <pavel.evst@gmail.com>
Date:   Mon Sep 16 14:02:49 2013 +0700

* Test cases for Worksheet#margins, Worksheet#pagesetup, Workbook#delete_worksheet. Fix bugs related to it.
* Page margins reader/writter
* Markdownify GUIDE
* Add page setup options (landscape or portrait and adjust_to)

### 0.8.9 / 24.08.2013

Author: Doug Renn <renn@nestegg.com>
Date:   Fri Aug 23 17:10:24 2013 -0600

* Work around to handle number formats that are being mistaken time formats

### 0.8.8 / 02.08.2013

Author: Nathan Colgate <nathancolgate@gmail.com>
Date:   Thu Aug 1 15:01:57 2013 -0500

* Update excel/internals.rb to reference a valid Encoding type
* Encoding.find("MACINTOSH") was throwing an error. Encoding.find("MACROMAN") does not.

### 0.8.7 / 24.07.2013

Author: Yasuhiro Asaka <yasaka@ywesee.com>
Date:   Wed Jul 24 11:31:12 2013 +0900

* Remove warnings for test suite      
* warning: mismatched indentations at 'end' with 'class' at xxx
* warning: method redefined; discarding old xxx
* warning: assigned but unused variable xxx
* warning: previous definition of xxx was here
* The source :rubygems is deprecated because HTTP
* requests are insecure. (Gemfile)

### 0.8.6 / 11.07.2013

Author: Arjun Anand and Robert Stern <dev+arjuna+rstern@reenhanced.com>
Date:   Wed Jul 10 13:45:30 2013 -0400 

* Allow editing of an existing worksheet.

### 0.8.5 / 24.04.2013

* Applied Patch by Joao Almeida: When editing an existing sheet, cells merge was not working.
* https://github.com/voraz/spreadsheet/pull/14.patch

### 0.8.4 / 20.04.2013

* Applied Patch by boss@airbladesoftware.com
* https://groups.google.com/d/msg/rubyspreadsheet/73IoEwSx69w/barE7uVnIzwJ

### 0.8.3 / 12.03.2013
 
Author: Keith Walsh <keith.walsh@adtegrity.com>
Date:   Mon Mar 11 16:48:25 2013 -0400

* Typo correction in guide example.  

### 0.8.2 / 28.02.2013

Author: Roque Pinel <roque.pinel@infotechfl.com>
Date:   Wed Feb 27 12:10:29 2013 -0500

* Requiring BigDecimal for checking.
* Made API friendly to BigDecimal precision.
* Changes introduced by the user 'valeriusjames'.

### 0.8.1 / 18.02.2013

* Updated Manifest.txt to include lib/spreadsheet/excel/rgb.rb

### 0.8.0 / 18.02.2013

* Adding support for converting color palette values to RGB values (not vice-versa..yet)
* by https://github.com/dancaugherty/spreadsheet/compare/master...rgb

### 0.7.9 / 06.02.2013

Author: Eugeniy Belyaev (zhekanax)

* You can merge if you are interested in perl-like Workbook.set_custom_color
  implementation. I know it is not really a proper way to deal with custom colors, but
  nevertheless it makes it possible.
* https://github.com/zdavatz/spreadsheet/pull/27

### 0.7.8 / 06.02.2013

Author: Kenichi Kamiya <kachick1@gmail.com>
Date:   Wed Feb 6 11:23:35 2013 +0900

* Link to Travis CI on README
* Remove warnings "assigned but unused variable" in test
* Remove warnings "assigned but unused variable"
* Enable $VERBOSE flag when running test

### 0.7.7 / 22.01.2013

Author: DeTeam <timur.deteam@gmail.com>
Date:   Tue Jan 22 19:11:52 2013 +0400

* Make tests pass
* Readme updated
* RuntimeError when file is empty
* Hoe in dev deps
* Finish with bundler
* Add a Gemfile

also see: https://github.com/zdavatz/spreadsheet/pull/24

### 0.7.6 / 15.01.2013

Author: Kenichi Kamiya <kachick1@gmail.com>
Date:   Tue Jan 15 15:52:58 2013 +0900

* Remove warnings "method redefined; discarding old default_format"
* Remove warnings "`*' interpreted as argument prefix"
* Remove warnings "instance variable @{ivar} not initialized"
* Remove warnings "assigned but unused variable"

also see: https://github.com/zdavatz/spreadsheet/pull/21

### 0.7.5 / 06.12.2012

* Add error tolerant values for Iconv when writing spreadsheet
* by andrea@spaghetticode.it

### 0.7.4 / 06.10.2012

* Adds Spreadsheet::Excel::Row#to_a method to properly decode Date and DateTime data.
* patches by https://github.com/mdgreenfield/spreadsheet

### 0.7.3 / 26.06.2012

* Fix Format borders
* see https://github.com/zdavatz/spreadsheet/pull/6 for full details.
* patches by uraki66@gmail.com

### 0.7.2 / 14.06.2012

* many changes by Mina Naguib <mina.git@naguib.ca>
* see git log for full details

### 0.7.1 / 08.05.2012

* Author: Artem Ignatiev <zazubrik@gmail.com>
* remove require and rake altogether
* gem build and rake gem both work fine without those requires,
* and requiring 'rake' broke bundler
* add rake as development dependency
* Somehow it broken rake on my other project

### 0.7.0 / 07.05.2012

* Author: Artem Ignatiev <zazubrik@gmail.com>
* use both ruby 1.8 and 1.9 compatible way of getting character code when hashing
* Fix syntax for ruby-1.9
* return gemspec so that bundler can find it
  When bundler loads gemspec, it evaluates it, and if the return value is 
  not a gem specification built, refuses to load the gem.
* Testing worksheet protection

### 0.6.9 / 28.04.2012

* Yield is more simple here too.
* No need to capture the block in Spreadsheet.open
* Rather than extending a core class, let's just use #rcompact from a helper module

### 0.6.8 / 20.01.2012

* adds the fix to allow the writing of empty rows, by ClemensP.
* Test also by ClemensP.

### 0.6.7 / 18.01.2012

* http://dev.ywesee.com/wiki.php/Gem/Spreadsheet points point 2.
* Tests by Michal
* Patches by Timon

### 0.6.6 / 18.01.2012

* http://dev.ywesee.com/wiki.php/Gem/Spreadsheet points 8 and 9. 
* Fixes byjsaak@napalm.hu
* Patches by Vitaly Klimov

### 0.6.5.9 / 7.9.2011

* Fixed a frozen string bug thanks to dblock (Daniel Doubrovkine),
* dblock@dblock.org

  * https://github.com/dblock/spreadsheet/commit/164dcfbb24097728f1a7453702c270107e725b7c

### 0.6.5.8 / 30.8.2011

* This patch is about adding a sheet_count method to workbook so that it returns
* the total no of worksheets for easy access. Please check. By
* tamizhgeek@gmail.com

        * https://gist.github.com/1180625

### 0.6.5.7 / 20.7.2011

* Fixed the bug introduced by Roel van der Hoorn and updated the test cases.

  * https://github.com/vanderhoorn/spreadsheet/commit/c79ab14dcf40dee1d6d5ad2b174f3fe31414ca28

### 0.6.5.6 / 20.7.2011

* Added a fix from Roel van der Hoorn to sanitize_worksheets if 'sheets' is empty.

  * https://github.com/vanderhoorn/spreadsheet/commit/c109f2ac5486f9a38a6d93267daf560ab4b9473e

### 0.6.5.5 / 24.6.2011

* updated the color code for orange to 0x0034 => :orange, thanks to the hint of Jonty

  * https://gist.github.com/1044700

### 0.6.5.4 / 18.4.2011

* Updated worksheet.rb according to the Patch of Björn Andersson.

  * https://gist.github.com/925007#file_test.patch
  * http://url.ba/09p9

### 0.6.5.3 / 23.3.2011

* Updated Txt lib/spreadsheet/excel/writer/biff8.rb with a Patch from Alexandre Bini

  * See this for full detail: http://url.ba/6r1z

### 0.6.5.2 / 14.2.2011

* Updated test/integration.rb to work with Ruby ruby 1.9.2p136 (2010-12-25 revision 30365) [i686-linux]
  
  * Thanks for the hint tomiacannondale@gmail.com

### 0.6.5.1 / 17.1.2011

* One enhancement thanks to Qiong Peng, Moo Yu, and Thierry Thelliez

  * http://dev.ywesee.com/wiki.php/Gem/Spreadsheet

### 0.6.5 / 07.12.2010

* 2 Enhancements courtesy to ISS AG.

  * Outlining (Grouping) of lines and columns is now possible. The outlining 
    maximum is 8. This means you can do 8 subgroups in a group.

  * Hiding and Unhiding of lines and columns is now possible. 

  * Both of above two points is now possible by creating a new Excel File from 
    scratch or editing an existing XLS and adding groups or hiding lines to it.

### 0.6.4.1 / 2009-09-17

* 3 Bugfixes

  * Fixes the issue reported by Thomas Preymesser and tracked down most of the
    way by Hugh McGowan in
    http://rubyforge.org/tracker/index.php?func=detail&aid=26647&group_id=678&atid=2677
    where reading the value of the first occurrence of a shared formula
    failed.

  * Fixes the issue reported by Anonymous in
    http://rubyforge.org/tracker/index.php?func=detail&aid=26546&group_id=678&atid=2677
    where InvalidDate was raised for some Dates.

  * Fixes the issue reported by John Lee in
    http://rubyforge.org/tracker/index.php?func=detail&aid=27110&group_id=678&atid=2677
    which is probably a duplicate of the Bug previously reported by Kadvin XJ in
    http://rubyforge.org/tracker/index.php?func=detail&aid=26182&group_id=678&atid=2677
    where unchanged rows were marked as changed in the Excel-Writer while the
    File was being written, triggering an Error.

* 1 minor enhancement

  * Detect row offsets from Cell data if Row-Ops are missing
    This fixes a bug reported by Alexander Logvinov in
    http://rubyforge.org/tracker/index.php?func=detail&aid=26513&group_id=678&atid=2677


### 0.6.4 / 2009-07-03

* 5 Bugfixes

  * Fixes the issue reported by Harley Mackenzie in
    http://rubyforge.org/tracker/index.php?func=detail&aid=24119&group_id=678&atid=2677
    where in some edge-cases numbers were stored incorrectly

  * Fixes the issue reported and fixed by someone23 in
    http://rubyforge.org/tracker/index.php?func=detail&aid=25732&group_id=678&atid=2677
    where using Row-updater methods with blocks caused LocalJumpErrors

  * Fixes the issue reported and fixed by Corey Burrows in
    http://rubyforge.org/tracker/index.php?func=detail&aid=25784&group_id=678&atid=2677
    where "Setting the height of a row, either in Excel directly, or via the
    Spreadsheet::Row#height= method results in a row that Excel displays with
    the maximum row height (409)."

  * Fixes the issue reported by Don Park in
    http://rubyforge.org/tracker/index.php?func=detail&aid=25968&group_id=678&atid=2677
    where some Workbooks could not be parsed due to the OLE-entry being all
    uppercase

  * Fixes the issue reported by Iwan Buetti in
    http://rubyforge.org/tracker/index.php?func=detail&aid=24414&group_id=678&atid=2677
    where parsing some Workbooks failed with an Invalid date error.


* 1 major enhancement

  * Spreadsheet now runs on Ruby 1.9

### 0.6.3.1 / 2009-02-13

* 3 Bugfixes

  * Only selects the First Worksheet by default
    This deals with an issue reported by Biörn Andersson in
    http://rubyforge.org/tracker/?func=detail&atid=2677&aid=23736&group_id=678
    where data-edits in OpenOffice were propagated through all selected
    sheets.

  * Honors Row, Column, Worksheet and Workbook-formats
    and thus fixes a Bug introduced in
    http://scm.ywesee.com/?p=spreadsheet;a=commit;h=52755ad76fdda151564b689107ca2fbb80af3b78
    and reported in
    http://rubyforge.org/tracker/index.php?func=detail&aid=23875&group_id=678&atid=2678
    and by Joachim Schneider in
    http://rubyforge.org/forum/forum.php?thread_id=31056&forum_id=2920

  * Fixes a bug reported by Alexander Skwar in
    http://rubyforge.org/forum/forum.php?thread_id=31403&forum_id=2920
    where the user-defined formatting of Dates and Times was overwritten with
    a default format, and other issues connected with writing Dates and Times
    into Spreadsheets.

* 1 minor enhancements

  * Spreadsheet shold now be completely warning-free,
    as requested by Eric Peterson in
    http://rubyforge.org/forum/forum.php?thread_id=31346&forum_id=2920

### 0.6.3 / 2009-01-14

* 1 Bugfix

  * Fixes the issue reported by Corey Martella in
    http://rubyforge.org/forum/message.php?msg_id=63651
    as well as other issues engendered by the decision to always shorten
    Rows to the last non-nil value.

* 2 minor enhancements

  * Added bin/xlsopcodes, a tool for examining Excel files

  * Documents created by Spreadsheet can now be Printed in Excel and
    Excel-Viewer.
    This issue was reported by Spencer Turner in
    http://rubyforge.org/tracker/index.php?func=detail&aid=23287&group_id=678&atid=2677

### 0.6.2.1 / 2008-12-18

* 1 Bugfix

  * Using Spreadsheet together with 'jcode' could lead to broken Excel-Files
    Thanks to Eugene Mikhailov for tracking this one down in:
    http://rubyforge.org/tracker/index.php?func=detail&aid=23085&group_id=678&atid=2677

### 0.6.2 / 2008-12-11

* 14 Bugfixes

  * Fixed a bug where #<boolean>! methods did not trigger a call to
    #row_updated

  * Corrected the Row-Format in both Reader and Writer (was Biff5 for some
    reason)

  * Populates Row-instances with @default_format, @height, @outline_level
    and @hidden attributes

  * Fixed a Bug where Workbooks deriving from a Template-Workbook without
    SST could not be saved
    Reported in
    http://rubyforge.org/tracker/index.php?func=detail&aid=22863&group_id=678&atid=2678

  * Improved handling of Numeric Values (writes a RK-Entry for a Float
    only if it can be encoded with 4 leading zeroes, and a Number-Entry for an
    Integer only if it cannot be encoded as an RK)

  * Fixes a bug where changes to a Row were ignored if they were
    outside of an existing Row-Block.

  * Fixes a bug where MULRK-Entries sometimes only contained a single RK

  * Fixes a bug where formatting was ignored if it was applied to empty Rows
    Reported by Zomba Lumix in
    http://rubyforge.org/forum/message.php?msg_id=61985

  * Fixes a bug where modifying a Row in a loaded Workbook could lead to Rows
    with smaller indices being set to nil.
    Reported by Ivan Samsonov in
    http://rubyforge.org/forum/message.php?msg_id=62816

  * Deals with rounding-problems when calculating Time
    Reported by Bughunter extraordinaire Bjørn Hjelle

  * Correct splitting of wide characters in SST
    Reported by Michel Ziegler and by Eugene Mikhailov in
    http://rubyforge.org/tracker/index.php?func=detail&aid=23085&group_id=678&atid=2677

  * Fix an off-by-one error in write_mulrk that caused Excel to complain that
    'Data may be lost', reported by Emma in
    http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/321979
    and by Chris Lowis in
    http://rubyforge.org/tracker/index.php?func=detail&aid=22892&group_id=678&atid=2677


  * Read formats correctly in read_mulrk
    Reported by Ivan Samsonov
    Fixes that part of http://rubyforge.org/forum/message.php?msg_id=62821
    which is a bug. Does nothing for the disappearance of Rich-Text
    formatting, which will not be addressed until 0.7.0

  * Fixes a (benign?) bug, where adding text to a template-file resulted in
    a duplicate extsst-record.

* 2 minor enhancements

  * Improved recognition of Time-Formats

  * Improvement to Robustness: allow Spreadsheet::Workbook.new
    Takes care of http://rubyforge.org/forum/message.php?msg_id=62941
    Reported by David Chamberlain

### 0.6.1.9 / 2008-11-07

* 1 Bugfix

  * Fixes a precision-issue in Excel::Row#datetime: Excel records Time-Values
    with more significant bits (but not necessarily more precise) than
    DateTime can handle.
    (Thanks to Bjørn Hjelle for the Bugreport)

* 1 minor enhancement

  * Added support for appending Worksheets to a Workbook
    (Thanks to Mohammed Rabbani for the report)

### 0.6.1.8 / 2008-10-31

* 1 Bugfix

  * Fixes a bug where out-of-sequence reading of multiple Worksheets could
    lead to data from the wrong Sheet being returned.
    (Thanks to Bugreporter extraordinaire Bjørn Hjelle)

### 0.6.1.7 / 2008-10-30

* 1 Bugfix

  * Fixes a bug where all Formulas were ignored.
    (Thanks to Bjørn Hjelle for the report)

* 1 minor enhancement

  * Allow the substitution of an IO object with a StringIO.
    (Thanks to luxor for the report)

### 0.6.1.6 / 2008-10-28

* 2 Bugfixes

  * Fixed encoding and decoding of BigNums, negative and other large Numbers
    http://rubyforge.org/tracker/index.php?func=detail&aid=22581&group_id=678&atid=2677
  * Fix a bug where modifications to default columns weren't stored
    http://rubyforge.org/forum/message.php?msg_id=61567

* 1 minor enhancement

  * Row#enriched_data won't return a Bogus-Date if the data isn't a Numeric
    value
    (Thanks to Bjørn Hjelle for the report)

### 0.6.1.5 / 2008-10-24

* 2 Bugfixes

  * Removed obsolete code which triggered Iconv::InvalidEncoding
    on Systems with non-gnu Iconv:
    http://rubyforge.org/tracker/index.php?func=detail&aid=22541&group_id=678&atid=2677
  * Handle empty Worksheets
    (Thanks to Charles Lowe for the Patches)

### 0.6.1.4 / 2008-10-23

* 1 Bugfix

  * Biff8#wide now works properly even if $KCODE=='UTF-8'
    (Thanks to Bjørn Hjelle for the Bugreport)

* 1 minor enhancement

  * Read/Write functionality for Links (only URLs can be written as of now)

### 0.6.1.3 / 2008-10-21

* 2 Bugfixes

  * Renamed UTF8 to UTF-8 to support freebsd
    (Thanks to Jacob Atzen for the Patch)
  * Fixes a Bug where only the first Rowblock was read correctly if there were
    no DBCELL records terminating the Rowblocks.
    (Thanks to Bjørn Hjelle for the Bugreport)

### 0.6.1.2 / 2008-10-20

* 2 Bugfixes

  * Corrected the Font-Encoding values in Excel::Internals
    (Thanks to Bjørn Hjelle for the Bugreport)
  * Spreadsheet now skips Richtext-Formatting runs and Asian Phonetic 
    Settings when reading the SST, fixing a problem where the presence of
    Richtext could lead to an incomplete SST.

### 0.6.1.1 / 2008-10-20

* 1 Bugfix

  * Corrected the Manifest - included column.rb

### 0.6.1 / 2008-10-17

* 3 minor enhancements

  * Adds Column formatting and Worksheet#format_column
  * Reads and writes correct Fonts (Font-indices > 3 appear to be 1-based)
  * Reads xf data

### 0.6.0 / 2008-10-13

* 1 major enhancement

  * Initial upload of the shiny new Spreadsheet Gem after three weeks of
    grueling labor in the dark binary mines of Little-Endian Biff and long
    hours spent polishing the surfaces of documentation.



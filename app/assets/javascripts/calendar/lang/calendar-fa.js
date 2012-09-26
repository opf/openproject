// ** I18N

// Calendar FA language
// Author: Behrang Noroozinia, behrangn at g mail
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("یک‌شنبه",
 "دوشنبه",
 "سه‌شنبه",
 "چهارشنبه",
 "پنج‌شنبه",
 "آدینه",
 "شنبه",
 "یک‌شنبه");

// Please note that the following array of short day names (and the same goes
// for short month names, _SMN) isn't absolutely necessary.  We give it here
// for exemplification on how one can customize the short day names, but if
// they are simply the first N letters of the full name you can simply say:
//
//   Calendar._SDN_len = N; // short day name length
//   Calendar._SMN_len = N; // short month name length
//
// If N = 3 then this is not needed either since we assume a value of 3 if not
// present, to be compatible with translation files that were written before
// this feature.

// short day names
Calendar._SDN = new Array
("یک",
 "دو",
 "سه",
 "چهار",
 "پنج",
 "آدینه",
 "شنبه",
 "یک");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("ژانویه",
 "فوریه",
 "مارس",
 "آوریل",
 "مه",
 "ژوئن",
 "ژوئیه",
 "اوت",
 "سپتامبر",
 "اکتبر",
 "نوامبر",
 "دسامبر");

// short month names
Calendar._SMN = new Array
("ژان",
 "فور",
 "مار",
 "آور",
 "مه",
 "ژوئن",
 "ژوئیه",
 "اوت",
 "سپت",
 "اکت",
 "نوا",
 "دسا");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "درباره گاهشمار";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Date selection:\n" +
"- Use the \xab, \xbb buttons to select year\n" +
"- Use the " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " buttons to select month\n" +
"- Hold mouse button on any of the above buttons for faster selection.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Time selection:\n" +
"- Click on any of the time parts to increase it\n" +
"- or Shift-click to decrease it\n" +
"- or click and drag for faster selection.";

Calendar._TT["PREV_YEAR"] = "سال پیشین (برای فهرست نگه دارید)";
Calendar._TT["PREV_MONTH"] = "ماه پیشین ( برای فهرست نگه دارید)";
Calendar._TT["GO_TODAY"] = "برو به امروز";
Calendar._TT["NEXT_MONTH"] = "ماه پسین (برای فهرست نگه دارید)";
Calendar._TT["NEXT_YEAR"] = "سال پسین (برای فهرست نگه دارید)";
Calendar._TT["SEL_DATE"] = "گزینش";
Calendar._TT["DRAG_TO_MOVE"] = "برای جابجایی بکشید";
Calendar._TT["PART_TODAY"] = " (امروز)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "آغاز هفته از %s";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "4,5";

Calendar._TT["CLOSE"] = "بسته";
Calendar._TT["TODAY"] = "امروز";
Calendar._TT["TIME_PART"] = "زدن (با Shift) یا کشیدن برای ویرایش";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "هفته";
Calendar._TT["TIME"] = "زمان:";

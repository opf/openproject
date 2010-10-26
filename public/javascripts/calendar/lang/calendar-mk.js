// ** I18N

// Calendar МК language
// Author: Ilin Tatabitovski, <itatabitovski@gmail.com>
// Encoding: UTF-8
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("недела",
 "понеделник",
 "вторник",
 "среда",
 "четврток",
 "петок",
 "сабота",
 "недела");

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
("нед",
 "пон",
 "вто",
 "сре",
 "чет",
 "пет",
 "саб",
 "нед");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("јануари",
 "февруари",
 "март",
 "април",
 "мај",
 "јуни",
 "јули",
 "август",
 "септември",
 "октомври",
 "ноември",
 "декември");

// short month names
Calendar._SMN = new Array
("јан",
 "фев",
 "мар",
 "апр",
 "мај",
 "јун",
 "јул",
 "авг",
 "сеп",
 "окт",
 "ное",
 "дек");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "За календарот";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"За последна верзија посети: http://www.dynarch.com/projects/calendar/\n" +
"Дистрибуирано под GNU LGPL.  Види http://gnu.org/licenses/lgpl.html за детали." +
"\n\n" +
"Бирање на дата:\n" +
"- Користи ги \xab, \xbb копчињата за да избереш година\n" +
"- Користи ги " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " копчињата за да избере месеци\n" +
"- Држи го притиснато копчето на глувчето на било кое копче за побрзо бирање.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Бирање на време:\n" +
"- Клик на временските делови за да го зголемиш\n" +
"- или Shift-клик да го намалиш\n" +
"- или клик и влечи за побрзо бирање.";

Calendar._TT["PREV_YEAR"] = "Претходна година (држи за мени)";
Calendar._TT["PREV_MONTH"] = "Претходен месец (држи за мени)";
Calendar._TT["GO_TODAY"] = "Go Today";
Calendar._TT["NEXT_MONTH"] = "Следен месец (држи за мени)";
Calendar._TT["NEXT_YEAR"] = "Следна година (држи за мени)";
Calendar._TT["SEL_DATE"] = "Избери дата";
Calendar._TT["DRAG_TO_MOVE"] = "Влечи да поместиш";
Calendar._TT["PART_TODAY"] = " (денес)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Прикажи %s прво";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Затвори";
Calendar._TT["TODAY"] = "Денес";
Calendar._TT["TIME_PART"] = "(Shift-)Клик или влечи за да промениш вредност";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d-%m-%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %e %b";

Calendar._TT["WK"] = "нед";
Calendar._TT["TIME"] = "Време:";


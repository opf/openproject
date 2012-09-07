// ** I18N

// Calendar SR language
// Author: Dragan Matic, <kkid@panforma.co.yu>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("недеља",
 "понедељак",
 "уторак",
 "среда",
 "четвртак",
 "петак",
 "субота",
 "недеља");

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
 "уто",
 "сре",
 "чет",
 "пет",
 "суб",
 "нед");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("јануар",
 "фебруар",
 "март",
 "април",
 "мај",
 "јун",
 "јул",
 "август",
 "септембар",
 "октобар",
 "новембар",
 "децембар");

// short month names
Calendar._SMN = new Array
("јан",
 "феб",
 "мар",
 "апр",
 "мај",
 "јун",
 "јул",
 "авг",
 "сеп",
 "окт",
 "нов",
 "дец");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "О календару";

Calendar._TT["ABOUT"] =
"DHTML бирач датума/времена\n" +
"(c) dynarch.com 2002-2005 / Аутор: Mihai Bazon\n" + // don't translate this this ;-)
"За новију верзију посетите: http://www.dynarch.com/projects/calendar/\n" +
"Дистрибуира се под GNU LGPL.  Погледајте http://gnu.org/licenses/lgpl.html за детаљe." +
"\n\n" +
"Избор датума:\n" +
"- Користите \xab, \xbb тастере за избор године\n" +
"- Користите " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " тастере за избор месеца\n" +
"- Задржите тастер миша на било ком тастеру изнад за бржи избор.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Избор времена:\n" +
"- Кликните на било који део времена за повећање\n" +
"- или Shift-клик за умањење\n" +
"- или кликните и превуците за бржи одабир.";

Calendar._TT["PREV_YEAR"] = "Претходна година (задржати за мени)";
Calendar._TT["PREV_MONTH"] = "Претходни месец (задржати за мени)";
Calendar._TT["GO_TODAY"] = "На данашњи дан";
Calendar._TT["NEXT_MONTH"] = "Наредни месец (задржати за мени)";
Calendar._TT["NEXT_YEAR"] = "Наредна година (задржати за мени)";
Calendar._TT["SEL_DATE"] = "Избор датума";
Calendar._TT["DRAG_TO_MOVE"] = "Превуците за премештање";
Calendar._TT["PART_TODAY"] = " (данас)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "%s као први дан у седмици";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "6,7";

Calendar._TT["CLOSE"] = "Затвори";
Calendar._TT["TODAY"] = "Данас";
Calendar._TT["TIME_PART"] = "(Shift-) клик или превлачење за измену вредности";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d.%m.%Y.";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %e. %b";

Calendar._TT["WK"] = "сед.";
Calendar._TT["TIME"] = "Време:";

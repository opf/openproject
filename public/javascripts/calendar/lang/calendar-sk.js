// ** I18N

// Calendar Slovak (SK) language
// Author: Stanislav Pach, <stano.pach@seznam.cz>
// Encoding: UTF-8
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// 

// full day names
Calendar._DN = new Array
("Nedeľa",
 "Pondelok",
 "Utorok",
 "Streda",
 "Štvrtok,
 "Piatok",
 "Sobota",
 "Nedeľa");

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
("Ne",
 "Po",
 "Ut",
 "St",
 "Št",
 "Pi",
 "So",
 "Ne");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Január",
 "Február",
 "Marec",
 "Apríl",
 "Máj",
 "Jún",
 "Júl",
 "August",
 "September",
 "Október",
 "November",
 "December");

// short month names
Calendar._SMN = new Array
("Jan",
 "Feb",
 "Mar",
 "Apr",
 "Maj",
 "Jun",
 "Jul",
 "Aug",
 "Sep",
 "Okt",
 "Nov",
 "Dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "O komponente kalendár";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Nastavenie dátumu:\n" +
"- Použijte klávesy \xab, \xbb pre voľbu roku\n" +
"- Použijte tlačítka " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " pre voľbu mesiaca\n" +
"- Podržte tlačitko myši na hociakej časti týchto tlačítiek pre rychlú voľbu.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Nastavenie času:\n" +
"- Kliknite na hociakú časť času pre jeho zvýšenie\n" +
"- alebo kliknite spolu so Shiftom, aby ste ho znížil\n" +
"- alebo kliknite a ťahajte pre rýchlejší výber.";

Calendar._TT["PREV_YEAR"] = "Predchádzajúci rok (pridrž pre menu)";
Calendar._TT["PREV_MONTH"] = "Predchádzajúci mesiac (pridrž pre menu)";
Calendar._TT["GO_TODAY"] = "Dnešný dátum";
Calendar._TT["NEXT_MONTH"] = "Daľší mesiac (pridrž pre menu)";
Calendar._TT["NEXT_YEAR"] = "Daľší rok (pridrž pre menu)";
Calendar._TT["SEL_DATE"] = "Zvoľ dátum";
Calendar._TT["DRAG_TO_MOVE"] = "Chyť a ťahaj pre presun";
Calendar._TT["PART_TODAY"] = " (dnes)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Zobraz %s prvý";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Zavrieť";
Calendar._TT["TODAY"] = "Dnes";
Calendar._TT["TIME_PART"] = "(Shift-)Klikni alebo ťahaj pre zmenu hodnoty";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Čas:";

// ** I18N

// Calendar LV language
// Translation: Dzintars Bergs, dzintars.bergs@gmail.com
// Encoding: UTF-8
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Svētdiena",
 "Pirmdiena",
 "Otrdiena",
 "Trešdiena",
 "Ceturtdiena",
 "Piektdiena",
 "Sestdiena",
 "Svētdiena");

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
("Sv",
 "Pr",
 "Ot",
 "Tr",
 "Ct",
 "Pk",
 "St",
 "Sv");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Janvāris",
 "Februāris",
 "Marts",
 "Aprīlis",
 "Maijs",
 "Jūnijs",
 "Jūlijs",
 "Augusts",
 "Septembris",
 "Oktobris",
 "Novembris",
 "Decembris");

// short month names
Calendar._SMN = new Array
("Jan",
 "Feb",
 "Mar",
 "Apr",
 "Mai",
 "Jūn",
 "Jūl",
 "Aug",
 "Sep",
 "Okt",
 "Nov",
 "Dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Par kalendāru";

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

Calendar._TT["PREV_YEAR"] = "Iepriekšējais gads (pieturēt, lai atvērtu izvēlni)";
Calendar._TT["PREV_MONTH"] = "Iepriekšējais mēnesis (pieturēt, lai atvērtu izvēlni)";
Calendar._TT["GO_TODAY"] = "Iet uz šodienu";
Calendar._TT["NEXT_MONTH"] = "Nākošais mēnesis (pieturēt, lai atvērtu izvēlni)";
Calendar._TT["NEXT_YEAR"] = "Nākošais gads (pieturēt, lai atvērtu izvēlni)";
Calendar._TT["SEL_DATE"] = "Izvēlieties datumu";
Calendar._TT["DRAG_TO_MOVE"] = "Vilkt, lai pārvietotu";
Calendar._TT["PART_TODAY"] = "(šodiena)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Rādīt %s pirmo";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Aizvērt";
Calendar._TT["TODAY"] = "Šodiena";
Calendar._TT["TIME_PART"] = "(Shift-)Click vai ievilkt, lai mainītu vērtību";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d.%m.%Y";
Calendar._TT["TT_DATE_FORMAT"] = " %b, %a %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Laiks:";

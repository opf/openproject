// ** I18N

// Calendar EN language
// Author: Mihai Bazon, <mihai_bazon@yahoo.com>
// Encoding: any
// Translater: Mads N. Vestergaard <mnv@coolsms.dk>
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Søndag",
 "Mandag",
 "Tirsdag",
 "Onsdag",
 "Torsdag",
 "Fredag",
 "Lørdag",
 "Søndag");

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
("Søn",
 "Man",
 "Tir",
 "Ons",
 "Tor",
 "Fre",
 "Lør",
 "Søn");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Januar",
 "Februar",
 "Marts",
 "April",
 "Maj",
 "Juni",
 "Juli",
 "August",
 "September",
 "Oktober",
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
Calendar._TT["INFO"] = "Om denne kalender";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For seneste version, besøg: http://www.dynarch.com/projects/calendar/\n" +
"Distribueret under GNU LGPL.  Se http://gnu.org/licenses/lgpl.html for detaljer." +
"\n\n" +
"Dato valg:\n" +
"- Benyt \xab, \xbb tasterne til at vælge år\n" +
"- Benyt " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " tasterne til at vælge måned\n" +
"- Hold musetasten inde på punkterne for at vælge hurtigere.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Tids valg:\n" +
"- Klik på en af tidsrammerne for at forhøje det\n" +
"- eller Shift-klik for at mindske det\n" +
"- eller klik og træk for hurtigere valg.";

Calendar._TT["PREV_YEAR"] = "Forrige år (hold for menu)";
Calendar._TT["PREV_MONTH"] = "Forrige måned (hold for menu)";
Calendar._TT["GO_TODAY"] = "Gå til dags dato";
Calendar._TT["NEXT_MONTH"] = "Næste måned (hold for menu)";
Calendar._TT["NEXT_YEAR"] = "Næste år (hold for menu)";
Calendar._TT["SEL_DATE"] = "Vælg dato";
Calendar._TT["DRAG_TO_MOVE"] = "Træk for at flytte";
Calendar._TT["PART_TODAY"] = " (dags dato)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Vis %s først";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "6,7";

Calendar._TT["CLOSE"] = "Luk";
Calendar._TT["TODAY"] = "I dag";
Calendar._TT["TIME_PART"] = "(Shift-)Klik eller træk for at ændre værdi";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "uge";
Calendar._TT["TIME"] = "Tid:";

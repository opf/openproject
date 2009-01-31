// ** I18N

// Calendar SL language
// Author: Jernej Vidmar, <jernej.vidmar@vidmarboehm.com>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Nedelja",
 "Ponedeljek",
 "Torek",
 "Sreda",
 "Četrtek",
 "Petek",
 "Sobota",
 "Nedelja");

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
("Ned",
 "Pon",
 "Tor",
 "Sre",
 "Čet",
 "Pet",
 "Sob",
 "Ned");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("Januar",
 "Februar",
 "Marec",
 "April",
 "Maj",
 "Junij",
 "Julij",
 "Avgust",
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
 "Avg",
 "Sep",
 "Okt",
 "Nov",
 "Dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "O koledarju";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Izbira datuma:\n" +
"- Uporabite \xab, \xbb gumbe za izbiro leta\n" +
"- Uporabite " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " gumbe za izbiro meseca\n" +
"- Za hitrejšo izbiro držite miškin gumb nad enim od zgornjih gumbov.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Izbira časa:\n" +
"- Kliknite na katerikoli del časa da ga povečate\n" +
"- oziroma kliknite s Shiftom za znižanje\n" +
"- ali kliknite in vlecite za hitrejšo izbiro.";

Calendar._TT["PREV_YEAR"] = "Prejšnje leto (držite za meni)";
Calendar._TT["PREV_MONTH"] = "Prejšnji mesec (držite za meni)";
Calendar._TT["GO_TODAY"] = "Pojdi na danes";
Calendar._TT["NEXT_MONTH"] = "Naslednji mesec (držite za meni)";
Calendar._TT["NEXT_YEAR"] = "Naslednje leto (držite za meni)";
Calendar._TT["SEL_DATE"] = "Izberite datum";
Calendar._TT["DRAG_TO_MOVE"] = "Povlecite za premik";
Calendar._TT["PART_TODAY"] = " (danes)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Najprej prikaži %s";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Zapri";
Calendar._TT["TODAY"] = "Danes";
Calendar._TT["TIME_PART"] = "(Shift-)klik ali povleči, da spremeniš vrednost";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Time:";

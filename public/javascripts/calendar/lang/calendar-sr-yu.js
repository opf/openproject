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
("nedelja",
 "ponedeljak",
 "utorak",
 "sreda",
 "četvrtak",
 "petak",
 "subota",
 "nedelja");

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
("ned",
 "pon",
 "uto",
 "sre",
 "čet",
 "pet",
 "sub",
 "ned");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("januar",
 "februar",
 "mart",
 "april",
 "maj",
 "jun",
 "jul",
 "avgust",
 "septembar",
 "oktobar",
 "novembar",
 "decembar");

// short month names
Calendar._SMN = new Array
("jan",
 "feb",
 "mar",
 "apr",
 "maj",
 "jun",
 "jul",
 "avg",
 "sep",
 "okt",
 "nov",
 "dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "O kalendaru";

Calendar._TT["ABOUT"] =
"DHTML birač datuma/vremena\n" +
"(c) dynarch.com 2002-2005 / Autor: Mihai Bazon\n" + // don't translate this this ;-)
"Za noviju verziju posetite: http://www.dynarch.com/projects/calendar/\n" +
"Distribuira se pod GNU LGPL.  Pogledajte http://gnu.org/licenses/lgpl.html za detalje." +
"\n\n" +
"Izbor datuma:\n" +
"- Koristite \xab, \xbb tastere za izbor godine\n" +
"- Koristite " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " tastere za izbor meseca\n" +
"- Zadržite taster miša na bilo kom tasteru iznad za brži izbor.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Izbor vremena:\n" +
"- Kliknite na bilo koji deo vremena za povećanje\n" +
"- ili Shift-klik za umanjenje\n" +
"- ili kliknite i prevucite za brži odabir.";

Calendar._TT["PREV_YEAR"] = "Prethodna godina (zadržati za meni)";
Calendar._TT["PREV_MONTH"] = "Prethodni mesec (zadržati za meni)";
Calendar._TT["GO_TODAY"] = "Na današnji dan";
Calendar._TT["NEXT_MONTH"] = "Naredni mesec (zadržati za meni)";
Calendar._TT["NEXT_YEAR"] = "Naredna godina (zadržati za meni)";
Calendar._TT["SEL_DATE"] = "Izbor datuma";
Calendar._TT["DRAG_TO_MOVE"] = "Prevucite za premeštanje";
Calendar._TT["PART_TODAY"] = " (danas)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "%s kao prvi dan u sedmici";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "6,7";

Calendar._TT["CLOSE"] = "Zatvori";
Calendar._TT["TODAY"] = "Danas";
Calendar._TT["TIME_PART"] = "(Shift-) klik ili prevlačenje za izmenu vrednosti";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d.%m.%Y.";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %e. %b";

Calendar._TT["WK"] = "sed.";
Calendar._TT["TIME"] = "Vreme:";

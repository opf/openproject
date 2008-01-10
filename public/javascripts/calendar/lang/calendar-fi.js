// ** I18N

// Calendar FI language
// Author: Antti Perkiömäki <antti.perkiomaki@gmail.com>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Sunnuntai",
 "Maanantai",
 "Tiistai",
 "Keskiviikko",
 "Torstai",
 "Perjantai",
 "Lauantai",
 "Sunnuntai");

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
("Su",
 "Ma",
 "Ti",
 "Ke",
 "To",
 "Pe",
 "La",
 "Su");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Tammikuu",
 "Helmikuu",
 "Maaliskuu",
 "Huhtikuu",
 "Toukokuu",
 "Kesäkuu",
 "Heinäkuu",
 "Elokuu",
 "Syyskuu",
 "Lokakuu",
 "Marraskuu",
 "Joulukuu");

// short month names
Calendar._SMN = new Array
("Tammi",
 "Helmi",
 "Maalis",
 "Huhti",
 "Touko",
 "Kesä",
 "Heinä",
 "Elo",
 "Syys",
 "Loka",
 "Marras",
 "Dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Tietoa kalenterista";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Tekijä: Mihai Bazon\n" + // don't translate this this ;-)
"Viimeisin versio: http://www.dynarch.com/projects/calendar/\n" +
"Jaettu GNU LGPL alaisena. Katso lisätiedot http://gnu.org/licenses/lgpl.html" +
"\n\n" +
"Päivä valitsin:\n" +
"- Käytä \xab, \xbb painikkeita valitaksesi vuoden\n" +
"- Käytä " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " painikkeita valitaksesi kuukauden\n" +
"- Pidä alhaalla hiiren painiketta missä tahansa yllämainituissa painikkeissa valitaksesi nopeammin.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Ajan valinta:\n" +
"- Paina mitä tahansa ajan osaa kasvattaaksesi sitä\n" +
"- tai Vaihtonäppäin-paina laskeaksesi sitä\n" +
"- tai paina ja raahaa valitaksesi nopeammin.";

Calendar._TT["PREV_YEAR"] = "Edellinen vuosi (valikko tulee painaessa)";
Calendar._TT["PREV_MONTH"] = "Edellinen kuukausi (valikko tulee painaessa)";
Calendar._TT["GO_TODAY"] = "Siirry Tänään";
Calendar._TT["NEXT_MONTH"] = "Seuraava kuukausi (valikko tulee painaessa)";
Calendar._TT["NEXT_YEAR"] = "Seuraava vuosi (valikko tulee painaessa)";
Calendar._TT["SEL_DATE"] = "Valitse päivä";
Calendar._TT["DRAG_TO_MOVE"] = "Rahaa siirtääksesi";
Calendar._TT["PART_TODAY"] = " (tänään)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Näytä %s ensin";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "6,0";

Calendar._TT["CLOSE"] = "Sulje";
Calendar._TT["TODAY"] = "Tänään";
Calendar._TT["TIME_PART"] = "(Vaihtonäppäin-)Paina tai raahaa vaihtaaksesi arvoa";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "vko";
Calendar._TT["TIME"] = "Aika:";

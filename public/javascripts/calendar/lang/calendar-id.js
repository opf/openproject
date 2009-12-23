// ** I18N

// Calendar EN language
// Author: Mihai Bazon, <mihai_bazon@yahoo.com>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// Translator: Raden Prabowo, <cakbowo@gmail.com> 

// full day names
Calendar._DN = new Array
("Minggu",
 "Senin",
 "Selasa",
 "Rabu",
 "Kamis",
 "Jumat",
 "Sabtu",
 "Minggu");

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
("Ming",
 "Sen",
 "Sel",
 "Rab",
 "Kam",
 "Jum",
 "Sab",
 "Ming");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("Januari",
 "Februari",
 "Maret",
 "April",
 "Mei",
 "Juni",
 "Juli",
 "Agustus",
 "September",
 "Oktober",
 "November",
 "Desember");

// short month names
Calendar._SMN = new Array
("Jan",
 "Feb",
 "Mar",
 "Apr",
 "Mei",
 "Jun",
 "Jul",
 "Agu",
 "Sep",
 "Okt",
 "Nov",
 "Des");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Mengenai kalender";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"Versi terbaru terdapat di: http://www.dynarch.com/projects/calendar/\n" +
"Disebarkan dibawah lisensi GNU LGPL.  Lihat http://gnu.org/licenses/lgpl.html untuk detil." +
"\n\n" +
"Pemilihan tanggal:\n" +
"- Gunakan tombol \xab, \xbb untuk memilih tahun\n" +
"- Gunakan tombol " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " untuk memilih bulan\n" +
"- Tekan terus tombol kanan pada mouse atau salah satu tombol diatas untuk memilih lebih cepat.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Pemilihan waktu:\n" +
"- Klik bagian waktu untuk menaikkan\n" +
"- atau Shift-klick untuk menurunkan\n" +
"- atau klik dan geser untuk pemilihan yang lebih cepat.";

Calendar._TT["PREV_YEAR"] = "Tahun sebelumnya. (tekan terus untuk menu)";
Calendar._TT["PREV_MONTH"] = "Bulan sebelumnya. (tekan terus untuk menu)";
Calendar._TT["GO_TODAY"] = "Ke Hari ini";
Calendar._TT["NEXT_MONTH"] = "Bulan berikutnya. (tekan terus untuk menu)";
Calendar._TT["NEXT_YEAR"] = "Tahun berikutnya. (tekan terus untuk menu)";
Calendar._TT["SEL_DATE"] = "Pilih tanggal";
Calendar._TT["DRAG_TO_MOVE"] = "Geser untuk menggerakkan";
Calendar._TT["PART_TODAY"] = " (hari ini)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Tampilkan %s lebih dulu";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Tutup";
Calendar._TT["TODAY"] = "Hari ini";
Calendar._TT["TIME_PART"] = "(Shift-)Click atau geser untuk mengubah nilai";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d-%m-%Y";
//Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %e %b";

Calendar._TT["WK"] = "mg";
Calendar._TT["TIME"] = "Waktu:";

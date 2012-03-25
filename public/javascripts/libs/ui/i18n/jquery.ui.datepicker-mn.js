/* Mongolian initialisation for the jQuery UI date picker plugin. */
/* Found on http://pl-developer.blogspot.de/2010/11/jquery-ui-datepicker-mn-mongolia.html */
jQuery(function($){
  $.datepicker.regional['mn'] = {
    closeText: 'Хаах',
    prevText: 'Өмнөх',
    nextText: 'Дараах',
    currentText: 'Өнөөдөр',
    monthNames: ['1-р сар','2-р сар','3-р сар','4-р сар','5-р сар','6-р сар',
    '7-р сар','8-р сар','9-р сар','10-р сар','11-р сар','12-р сар'],
    monthNamesShort: ['1 сар', '2 сар', '3 сар', '4 сар', '5 сар', '6 сар',
    '7 сар', '8 сар', '9 сар', '10 сар', '11 сар', '12 сар'],
    dayNames: ['Ням', 'Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба'],
    dayNamesShort: ['Ням', 'Дав', 'Мяг', 'Лха', 'Пүр', 'Баа', 'Бям'],
    dayNamesMin: ['Ня','Да','Мя','Лх','Пү','Ба','Бя'],
    weekHeader: '7 хоног',
    dateFormat: 'yy.mm.dd',
    firstDay: 1,
    isRTL: false,
    showMonthAfterYear: false,
    yearSuffix: ''};
  $.datepicker.setDefaults($.datepicker.regional['mn']);
});

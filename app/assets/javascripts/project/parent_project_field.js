jQuery(document).ready(function($) {
    var spp = $('#project_parent_id');
    var path = spp.data('protocol') + spp.data('root') + '/projects/' + spp.data('projectid') + '/project_tree';
    $.ajax({
        type: 'GET',
        url: path
    })
    .done(function( data ) {
        spp.empty().append(data).select2();
    });
});

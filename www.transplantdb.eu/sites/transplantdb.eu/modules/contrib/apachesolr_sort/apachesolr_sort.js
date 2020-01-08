jQuery(document).ready(function() {
  var groupClasses = new Array();
  jQuery('.search-result.solr-grouped').each(function(index, item){
    item = jQuery(item)
    currentGroupClass = item.attr('class').substr(item.attr('class').lastIndexOf('solr-group-'));
    if(jQuery.inArray(currentGroupClass, groupClasses) < 0) {
      groupClasses.push(currentGroupClass);
    }
  });
  
  // Note, this way it's already encoded!
  queryTerm = window.location.pathname.split('/').slice(-1)[0];
  
  jQuery.each(groupClasses, function(index, item) {
    currentGroup = jQuery('.search-result.solr-grouped.' + item);
    currentGroup.wrapAll('<li id="' + item + '-all" />');
    currentGroup.wrapAll('<ol class="apachesolr_search-results-grouped search-results-grouped">');
    itemName = item.replace('solr-group-', '');
    itemName = itemName.replace('Ensembl-Plants', 'Ensembl Plants'); // Kill me
    jQuery('#' + item + '-all').prepend('<span>Results from ' + itemName +':</span>');
    jQuery('#' + item + '-all').append('<a href="/ext/search/db/' + itemName + '/' + queryTerm + '">More results in ' + itemName + '... </a>');
  });
});

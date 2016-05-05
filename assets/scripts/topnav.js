var Search = Search || {};

Search.doSearchButton = function() {
  Search.doSearch($("#query-box").val());
}

Search.doSearch = function(query) {
  $('#search-results').empty();
  var folders=$("ul label:contains(\"" + query + "\")");
  folders.each(function(idx, item) {
    Search.appendResult($(item).parent());
  });
  Search.showResults();
}

Search.appendResult = function(e) {
  var cloned = $(e).clone();
  cloned.find('input[type="checkbox"], label').each(function(idx, item) {
    if (typeof($(item).attr('id')) != 'undefined') {
      var oldId = $(item).attr('id');
      $(item).attr('id', 'srch-' + oldId);
    } else if (typeof($(item).attr('for')) != 'undefined') {
      var oldId = $(item).attr('for');
      $(item).attr('for', 'srch-' + oldId);
    }
  });
  $('#search-results').append(cloned);
}

Search.showResults = function() {
  $('#search-0')[0].checked = true;
  $('#search-results input').each(function(idx, e) {e.checked=true;})
  $('#search-0')[0].scrollIntoView(true);
}

function locateTree(component) {
  $('#search-results').empty();

  $('[name="' + component + '"]').each(function(idx, e) {
    Search.appendResult(e);
  });
  Search.showResults();
};

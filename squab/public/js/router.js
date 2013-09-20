var EventRouter = Backbone.Router.extend({
  initialize: function() {
    var events = new Events();

    this.searchView = new SearchView({ collection: events });
    new EventsView({ collection: events, searchView: this.searchView });
  },
  routes: {
    '(:source)(/:uid)(/:from)(/:to)(/:value)(/:url)': 'search'
  },
  _decodeParam: function(param) {
    return param ? decodeURIComponent(param) : '';
  },
  search: function(source, uid, from, to, value, url) {
    var query = {
      source: this._decodeParam(source) || this.searchView.EMPTY_QUERY_SYMBOL,
      uid: this._decodeParam(uid)  || this.searchView.EMPTY_QUERY_SYMBOL,
      from: from  || this.searchView.EMPTY_QUERY_SYMBOL,
      to: to || this.searchView.EMPTY_QUERY_SYMBOL,
      value: this._decodeParam(value) || this.searchView.EMPTY_QUERY_SYMBOL,
      url: this._decodeParam(url) || this.searchView.EMPTY_QUERY_SYMBOL
    }
    _.each(query, function(value, key) {
      if (value === this.searchView.EMPTY_QUERY_SYMBOL) {
        query[key] = value = '';
      }
      if ( (key === 'to' || key === 'from')) {
        if (!value) {
          delete query[key];
          return;
        }
        value = this.searchView._toISOString(new Date(value * 1000));
      }
      $('input[name="' + key + '"]').val(value);
    }, this);
    this.searchView.search(query);
  }
});

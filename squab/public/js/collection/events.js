var Events = Backbone.Collection.extend({
  _END_OF_DAY: (23 * 60 * 60) + (59 * 60) + 59,
  model: Event,
  initialize: function(opts) {
    _.bindAll(this, 'handleSearch', 'startPolling', 'stopPolling', 'poll');
    this.defaultQuery = {
      uid: '',
      source: '',
      value: '',
      url: ''
    };
  },
  url: '/api/v1/events',
  searchUrl: '/api/v1/events/search',
  comparator: function(model) {
    return model.get('date');
  },
  groupedByDay: function() {
    return this.groupBy(function(event) {
      return event.formattedDate();
    });
  },
  searchReq: function(query) {
    return $.ajax({
      type: 'POST',
      url: this.searchUrl,
      data: JSON.stringify(query),
      processData: false,
      dataType: 'json'
    });
  },
  search: function(query) {
    var self = this;
    this.currentQuery = query || _.clone(this.defaultQuery);
    this.trigger('search');
    // Set "to" to 11:59:59pm by default
    // TODO: Add time pickers
    if (query.to) {
      query.to = parseInt(query.to, 10) + this._END_OF_DAY;
    }
    this.stopPolling();
    return this.searchReq(query)
      .done(this.handleSearch)
      .always(function() { self.trigger('searched'); });
  },
  handleSearch: function(res, status) {
    this.reset(res);
    this.startPolling();
  },
  startPolling: function(interval) {
    this.stopPolling();
    var last = this.last();
    if (!last && (this.currentQuery.lastId || this.currentQuery.to)) return;
    interval = interval || 5000;
    this.poller = setInterval(this.poll, interval);
    this.trigger('startedPolling');
  },
  stopPolling: function() {
    if (this.poller) clearInterval(this.poller);
    this.trigger('stoppedPolling');
  },
  poll: function() {
    var self = this,
        query = this.currentQuery,
        last = this.last();

    if (last && last.id) query.fromId = last.id + 1;
    return this.searchReq(query)
      .done(function(res, status) {
        self.add(res);
        self.trigger('polled');
      });
  }
});

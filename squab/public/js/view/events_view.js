var EventsView = Backbone.View.extend({
  el: '#events',
  dayViews: null,
  initialize: function(opts) {
    if (!this.collection) {
      this.collection = new Events();
    }
    this.searchView = opts.searchView || new SearchView({ collection: this.collection });
    this.dayViews = [];

    this.listenTo(this.collection, 'add', this.addEvent);
    this.listenTo(this.collection, 'reset', this.render);
  },
  events: {
    'click .source': 'searchSource',
    'click .user'  : 'searchUser'
  },
  addDayView: function(event) {
    var date = event.localeDateString(),
        formattedDate = event.formattedDate();
    if (_.contains(_.pluck(this.dayViews, 'date'), date)) return;
    var dayView = new DayView({
      date: date,
      formattedDate: formattedDate,
      collection: this.collection
    });
    this.dayViews.push(dayView);
    this.$el.prepend(dayView.render().el);
  },
  render: function() {
    _.each(this.dayViews, function(dayView) {
      dayView.remove();
    });
    this.dayViews = [];
    this.collection.each(this.addDayView, this);
    return this;
  },
  searchSource: function(e) {
    $('input[name=source]').val($(e.target).text());
    this.searchView.submit();
  },
  searchUser: function(e) {
    $('input[name=uid]').val($(e.target).text());
    this.searchView.submit();
  }
});

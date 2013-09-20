// Assign a collection of events for a single day
var DayView = Backbone.View.extend({
  tagName: 'div',
  className: 'day',
  template: _.template($('#day-template').html()),
  initialize: function(opts) {
    _.extend(this, opts);
    this.render();
    this.listenTo(this.collection, 'add', this.addEvent);
  },
  date: null,
  addEvent: function(event) {
    if (event.localeDateString() !== this.date) return;
    var eventView = new EventView({model: event});
    this.$el.find('.day-events').prepend(eventView.render().el);
  },
  render: function() {
    this.$el.html(this.template({ formattedDate: this.formattedDate }));
    this.collection.each(this.addEvent, this);
    return this;
  }
});
var EventView = Backbone.View.extend({
  tagName: 'li',
  template: _.template($('#event-template').html()),
  formattedModel: function() {
    var data = this.model.toJSON();
    data.time = this.model.localeTimeString();
    data.dateString = this.model.formattedDateTime();
    return data;
  },
  render: function() {
    this.$el.html(this.template(this.formattedModel()));
    return this;
  }
});

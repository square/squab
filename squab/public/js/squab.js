var initialize = function() {
  new EventRouter();
  Backbone.history.start({ pushState: true });
}

$(initialize);

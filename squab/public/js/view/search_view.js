var SearchView = Backbone.View.extend({
  EMPTY_QUERY_SYMBOL: 'Ø',
  el: '#search-form',
  events: {
    'submit'             : 'submit',
    'change #autorefresh': 'toggleAutoRefresh'
  },
  initialize: function() {
    this.listenTo(this.collection, 'search', function() {
      this.$el.find('input[type="submit"]')
        .val('Searching...')
        .addClass('searching');
    });
    this.listenTo(this.collection, 'searched', function() {
      this.$el.find('input[type="submit"]')
        .val('Search')
        .removeClass('searching');
    });
    this.listenTo(this.collection, 'reset polled', function() {
      $('#update-time').text(new Date().toLocaleTimeString());
    });
    this.listenTo(this.collection, 'startedPolling', function() {
      $('#update-notice').addClass('visible');
    });
    this.listenTo(this.collection, 'stoppedPolling', function() {
      $('#update-notice').removeClass('visible');
    });
    this.initTypeahead();
    if (this.browserSupportsDateInputs()) {
      var today = new Date();
      $('#js-datepickers').remove();
      $('input[type="date"]').attr('max', this._toISOString(today));
    } else {
      this.initDatepickers();
      $('#native-datepickers').remove();
    }
  },
  submit: function(e) {
    e && e.preventDefault();
    var fields = this.$el.serializeArray();
    var query = {};

    _.each(fields, function(field) {
      if (field.name === "from" || field.name === "to") {
        if (!field.value) return;
        query[field.name] =  new Date(field.value).getTime()/1000;
      } else {
        query[field.name] = field.value;
      }
    });
    this.setRoute(query);
    this.search(query);
  },
  search: function(query) {
    return this.collection.search(query);
  },
  _encodeParam: function(param) {
    return param ? encodeURIComponent(param) : this.EMPTY_QUERY_SYMBOL;
  },
  setRoute: function(query) {
    var routeString = this._encodeParam(query.source)
      + '/' + this._encodeParam(query.uid)
      + '/' + this._encodeParam(query.from)
      + '/' + this._encodeParam(query.to)
      + '/' + this._encodeParam(query.value)
      + '/' + this._encodeParam(query.url);
    Backbone.history.navigate(routeString);
  },
  toggleAutoRefresh: function() {
    if ($('#autorefresh').attr('checked')) {
      this.collection.poll();
      this.collection.startPolling();
    } else {
      this.collection.stopPolling();
    }
  },
  initTypeahead: function() {
    this.$el.find('input[name="source"]').typeahead({
      name: 'sources',
      prefetch: '/api/v1/sources'
    });
    this.$el.find('input[name="uid"]').typeahead({
      name: 'users',
      prefetch: '/api/v1/users'
    });
  },
  browserSupportsDateInputs: function() {
     var dateInput = $('input[type="date"]')[0];

     dateInput.value = "test";
     return dateInput.value != "test";
  },
  initDatepickers: function() {
    this.initDatepicker('#from-text', '#from-date');
    this.initDatepicker('#to-text', '#to-date');
  },
  initDatepicker: function(textFieldSelector, dateFieldSelector) {
    var pickerOpts = {
          format: 'mmmm d, yyyy',
          max: new Date()
        },
        $dateField = $(dateFieldSelector).pickadate(pickerOpts),
        picker = $dateField.pickadate('picker'),
        $textField = $(textFieldSelector);
    $textField.on({
      change: function() {
        var parsedDate = Date.parse(this.value);
        if (parsedDate) {
          picker.set('select', [parsedDate.getFullYear(), parsedDate.getMonth(), parsedDate.getDate()]);
        }
        else {
          console.error('Invalid date')
        }
      },
      focus: function() {
        // picker.open(false);
      },
      blur: function() {
        picker.close();
      }
    });
    picker.on('set', function() {
      $textField.val(this.get('value'))
    });
    return picker;
  },
  _toISOString: function(dateObject) {
    return dateObject.toISOString().split('T')[0];
  }
});

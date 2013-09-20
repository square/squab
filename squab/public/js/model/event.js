var MONTH_NAMES = [ "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December" ];

var Event = Backbone.Model.extend({
  initialize: function() {
    this.initDate();
    this.on('change:date', this.initDate);
  },
  dateObject: null,
  initDate: function() {
    var date = this.get('date');
    if (!date) return false;
    this.dateObject = new Date(this.get('date') * 1000);
  },
  formattedDate: function() {
    var date = this.dateObject,
        today = new Date(),
        yesterday = new Date(today),
        dateString = '';
    yesterday.setDate(today.getDate() - 1);
    if (date.toLocaleDateString() === today.toLocaleDateString()) {
      dateString += "Today, ";
    } else if (date.toLocaleDateString() === yesterday.toLocaleDateString()) {
      dateString += "Yesterday, ";
    }
    dateString += MONTH_NAMES[date.getMonth()] + ' ' + date.getDate() + ', ' + date.getFullYear();
    return dateString;
  },
  localeDateString: function() {
    return this.dateObject.toLocaleDateString();
  },
  localeTimeString: function() {
    return this.dateObject.toLocaleTimeString();
  },
  formattedDateTime: function() {
    return this.formattedDate() + ' ' + this.localeTimeString();
  }
});

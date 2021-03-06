Travis.Views.Build.Matrix.Row = Backbone.View.extend({
  initialize: function() {
    _.bindAll(this, 'render', 'setStatus', 'setDuration', 'setFinishedAt', 'setLastBuild', 'setSelected');

    this.model.bind('change:status', this.setStatus);
    this.model.bind('change:duration', this.setDuration);
    this.model.bind('change:finished_at', this.setFinishedAt);

    this.template = Travis.app.templates['build/matrix/row'];
  },
  render: function() {
    this.el = $(this.template(this.model.toJSON()));
    this.el.updateTimes();
    return this;
  },
  setStatus: function() {
    $(this.el).removeClass('red green').addClass(this.model.color());
  },
  setDuration: function() {
    this.$('.duration').attr('title', this.model.get('duration'));
    this.el.updateTimes();
  },
  setFinishedAt: function() {
    this.$('.finished_at').attr('title', this.model.get('finishedAt'));
    this.el.updateTimes();
  },
});

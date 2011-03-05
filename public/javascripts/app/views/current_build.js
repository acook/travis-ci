Travis.Views.CurrentBuild = Travis.Views.Build.extend({
  initialize: function(args) {
    this.selectors = this.selectors || {
      element: '#tab_current div'
    };
    this.templates = this.templates || {
      show: args.templates['builds/current'],
      summary: args.templates['builds/_summary']
    };
    Travis.Views.Build.prototype.initialize.apply(this, arguments);
  },
  element: function() {
    return $('#tab_current div');
  },
  connect: function(build) {
    Travis.Views.Build.prototype.connect.apply(this, arguments);
    build.collection.bind('add', this.connect);
    this.element().activateTab('current');
  },
  updateTab: function(repository) {
    $('h5 a', this.element().closest('li')).attr('href', '#!/' + repository.user.get('login') + '/' + repository.get('name'));
  },
});

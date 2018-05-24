export default {
  resource: 'admin',
  map() {
    this.route('adminLegal', { path: '/legal', resetNamespace: true }, function() {
      this.route('digest', { path: '/digest'});
    });
  }
};

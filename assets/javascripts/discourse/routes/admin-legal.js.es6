export default Ember.Route.extend({
  redirect() {
    this.replaceWith('adminLegal.consent');
  }
})

var alreadyEdited = false;

App.messages = App.cable.subscriptions.create('TestsChannel', {
  received: function(data) {
    if (alreadyEdited === false ) {
      $('#test-pre').text('');
      alreadyEdited = true;
    }
    $('#test-pre').append(this.renderMessage(data));
  },

  renderMessage: function(data) {
    return data.output;
  }
});

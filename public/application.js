$(document).ready(function() {
  // Handles Message pub-sub
  var client = new Faye.Client('//' + window.location.host + '/faye');
  var subscription = client.subscribe(Settings.current_channel, function(message) {
    var messages = $("#messages");

    messages.prepend(message);

    var children = messages.children(".row");

    if(children.length > Settings.max_messages) {
      children.last().remove();
    }
  });

  // Handles AJAX message updating
  var form = $("#message");
  form.submit(function(event) {
    $.ajax(form.attr("action"), {
      method: "POST",
      data: form.serialize()
    }).done(function() {
      form.children().val("");
    });

    event.preventDefault();
  });
});

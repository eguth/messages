$(document).ready(function() {
  var replying = $("#message #replying");
    // Handles Message pub-sub
  if(typeof Settings != 'undefined') {
    var client = new Faye.Client('//' + window.location.host + '/faye');
    var subscription = client.subscribe(Settings.current_channel, function(message) {
      var messages = $("#messages");

      message = JSON.parse(message);

      var parent_message = $("#message-" + message.parent_id);

      if(message.parent_id && parent_message.length > 0) {
        var children = parent_message.find(".children");
        children.append(message.body);

        var num_children = children.children(".message-child").length;
        parent_message.find(".toggle-children > span").html(num_children);

        replying.children(".close").click();

        children.show();
        parent_message.effect("highlight", { color: "#8aaf19" });
      } else {
        messages.prepend(message.body)

        var children = messages.children(".message");
        children.first().effect("highlight", { color: "#8aaf19" });

        if(children.length > Settings.max_messages) {
          children.last().remove();
        }
      };
    });
  }
});

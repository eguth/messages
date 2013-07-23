function alert_error(message) {
  return "<div class='alert alert-error'><button type='button' class='close' data-dismiss='alert'>&times;</button>" + message + "</div>";
};

$(document).ready(function() {
  var form = $("#message");
  var preview = $("#preview");
  var parent_id = $("#message #parent-id");
  var replying = $("#message #replying");
  var preview_close = $("#preview-area .close");

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

  $(".toggle-children").on('click', function(event) {
    event.preventDefault();

    $(this).parents(".message").find(".children").toggle();
  });

  $(".reply-to").on('click', function(event) {
    event.preventDefault();

    parent_id.val($(this).data("id"));

    replying.show()
    replying.children("span").html('Replying to "' + $(this).data("trunc") + '"');
    window.scrollTo(0, 0);
  });

  replying.children(".close").on('click', function(event) {
    event.preventDefault();

    parent_id.val("");

    replying.hide();
    replying.children("span").html("");
  });

  preview_close.click(function(event) {
    event.preventDefault();

    $("#preview-area").hide();
    $("#preview-area div").html("");
  });

  preview.click(function(event) {
    event.preventDefault();

    if(form.children("textarea").val() === "")
      return;

    $.ajax(preview.data("action"), {
      method: "POST",
      data: form.serialize()
    }).done(function(data, textStatus, xhr) {
      $("#preview-area").show();
      $("#preview-area div").html(data);
    }).fail(function(xhr, text, error) {
      $("#sidebar").prepend(alert_error("Could not generate preview. Please try again or contact sdavidovtz@zendesk.com"));
    });
  });

  form.submit(function(event) {
    $.ajax(form.attr("action"), {
      method: "POST",
      data: form.serialize()
    }).done(function() {
      form.children().val("");
    }).fail(function(xhr, text, error) {
      $("#sidebar").prepend(alert_error(xhr.responseText));
    }).always(function() {
      preview_close.click();
      replying.children(".close").click();
    });

    event.preventDefault();
  });

  $(".like").on('click', function(event) {
    var element = $(this);

    $.ajax(element.data("action"), {
      method: "PUT"
    }).done(function(data, textStatus, xhr) {
      element.children("span").html(data);
      element.attr("disabled", "disabled");
    });

    event.preventDefault();
  });

  $(".toggle").click(function(event) {
    event.preventDefault();

    var element = $(this).data("toggle");
    $(element).toggle();
    $(this).children("i").toggle();
  });
});

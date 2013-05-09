module Helpers
  def alert
    if @alert
      alert_for_type("alert", @alert)
    elsif @success
      alert_for_type("alert alert-success", @success)
    elsif @error
      alert_for_type("alert alert-error", @error)
    elsif @info
      alert_for_type("alert alert-info", @info)
    end
  end

  def alert_for_type(type, message)
    "<div class=\"#{type}\">"+
    "<button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button>"+
    "#{message}</div>"
  end
end

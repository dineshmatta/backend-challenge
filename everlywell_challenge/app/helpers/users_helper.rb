module UsersHelper

  def show_connection(user, experts)
    str = "#{user.name}"
    logger.info "LLLLLLLLLL#{experts}"
    if experts.nil?
      return
    end

    if experts.empty?
      return "No Connection Found"
    end

    experts.each do |expert|
      str += " -> #{expert}"
    end

    return str
  end
end

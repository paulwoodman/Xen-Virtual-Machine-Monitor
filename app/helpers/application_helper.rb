# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def check_authenticated
    @userid = Digest::MD5.hexdigest(@username)
    @getsessionid = User.find(:all, :select => 'sessionid,gid', :conditions => ["username = ?", @username])
    for getsessionid in @getsessionid
      @cookieinfo = getsessionid.sessionid + "-" + @userid
    end
    @cookie = cookies[:auth_token]
    if(@cookieinfo == @cookie)
      if(getsessionid.gid == 0)
        @admin = 1
      else
        @admin = 0
      end
      @loggedin = 1
    else
      @loggedin = 0
    end
  end

end

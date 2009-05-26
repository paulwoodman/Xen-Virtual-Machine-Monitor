class UsersController < ApplicationController
  helper_method :redirect_to
  
  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      redirect_back_or_default('/userinfo')
      flash[:notice] = "Thanks for signing up!"
    else
      render :controller => 'new'
    end
  end
  
  def change_password
    @userlist = User.find(:all, :order => "login ASC")
    @userinfo = User.find(:all, :conditions => [ "login = ?", params[:pwusername] ])
    for userinfo in @userinfo
      @rbname = userinfo.name
      if (userinfo.gid == 0)
        @rbusertype = "Administrator"
      else
        @rbusertype = "User"
      end
    end
  end

end

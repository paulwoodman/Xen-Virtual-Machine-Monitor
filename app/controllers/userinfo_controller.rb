class UserinfoController < ApplicationController
  protect_from_forgery :only => [:create, :update, :destroy]
  helper_method :redirect_to
  
  def index
  
    if(params[:attribute] == "password")
      
      @chuserinfo = User.find(:all, :conditions => [ "login = ?", params[:username] ])
      for user in @chuserinfo
        @salt1 = user.salt
        @oldcrypto = Digest::SHA1.hexdigest("--#{@salt1}--#{params[:oldpassword]}--")
        if (user.crypted_password == @oldcrypto)
          @goodpw = 1
          if (params[:newpassword] == params[:newpasswordcheck])
            @newcrypto = Digest::SHA1.hexdigest("--#{@salt1}--#{params[:newpassword]}--")
            @match = 1
          else
            @match = 0
          end
        else
          @goodpw = 0
        end

        if (@goodpw == 1 && @match == 1)
          User.update(user.id, {:crypted_password => @newcrypto})
          @message = params[:username] + " changed password"
          XenLog.create( :logtype => '9', :message => @message )
        end
      end
    
    end
    
    if(params[:attribute] == "adminpassword")
      
      @chuserinfo = User.find(:all, :conditions => [ "login = ?", params[:username] ])
      for user in @chuserinfo
        @salt1 = user.salt
        if (params[:newpassword] == params[:newpasswordcheck])
          @newcrypto = Digest::SHA1.hexdigest("--#{@salt1}--#{params[:newpassword]}--")
          @match = 1
        else
          @match = 0
        end

        if (@match == 1)
          User.update(user.id, {:crypted_password => @newcrypto})
          @message = current_user.login + " changed " + params[:username] + "'s password"
          XenLog.create( :logtype => '9', :message => @message )
          @passwordchanged = 1
          @dest = "/userinfo/" + params[:username]
          redirect_to @dest
        end
      end
    
    end
    
    if(params[:attribute] == "grant" && current_user.gid == 0)
      
      @chuserinfo = User.find(:all, :conditions => [ "login = ?", params[:username] ])
      for user in @chuserinfo
        User.update(user.id, {:gid => 0})
        @message = current_user.login + " granted " + params[:username] + " admin permissions"
        XenLog.create( :logtype => '9', :message => @message )
      end
      @dest = "/userinfo/" + params[:username]
      redirect_to @dest

    end
    
    if(params[:attribute] == "revoke" && current_user.gid == 0)
      
      @chuserinfo = User.find(:all, :conditions => [ "login = ?", params[:username] ])
      for user in @chuserinfo
        User.update(user.id, {:gid => 1})
        @message = current_user.login + " revoked " + params[:username] + "'s admin permissions"
        XenLog.create( :logtype => '9', :message => @message )
      end
      @dest = "/userinfo/" + params[:username]
      redirect_to @dest

    end
    
    if(params[:username])
      @userinfo = User.find(:all, :conditions => [ "login = ?", params[:username] ])
      for chuser in @userinfo
        @chusername = chuser.login
        @chname = chuser.name
        if(chuser.gid == 0)
          @chtype = "Administrator"
        else
          @chtype = "User"
        end
      end
    else
      @userinfo = User.find(:all, :conditions => [ "login = ?", current_user.login ])
      for userinfo in @userinfo
        @rbname = userinfo.name
        if (userinfo.gid == 0)
          @rbusertype = "Administrator"
        else
          @rbusertype = "User"
        end
      end
    end

    @userlist = User.find(:all, :order => "login ASC")
  end
  
  def execdelete
    @userinfo = User.find(:all, :conditions => [ "login = ?", params[:username] ])
    for user in @userinfo
      User.delete(user.id)
      @message = current_user.login + " deleted " + params[:username]
      XenLog.create( :logtype => '8', :message => @message )
    end
    @dest = "/userinfo"
    redirect_to @dest
  end
  
  def adduser
    @userlist = User.find(:all, :order => "login ASC")
  end
  
end

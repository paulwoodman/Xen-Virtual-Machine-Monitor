class MonitorController < ApplicationController
  helper_method :redirect_to

  def index
    @grouplist = Group.find(:all, :conditions => [ "id != '1' AND groups.available = '1'" ], :order => "name ASC")
    @runningmachines = Machine.find(:all, :conditions => [ "state = '1'"], :order => "name ASC")
  end

  def machines
    @runningmachines = Machine.find(:all, :conditions => [ "state = '1' "], :order => "name ASC")
  end

  def focus
    @focus = User.find(:all, :conditions => [ "login = ?", current_user.login])
  end

  def unfocus
    @userid = User.find(:all, :select => 'id', :conditions => [ "login = ?", current_user.login])
    for userinfo in @userid
      User.update(userinfo.id, { :activevm => '' })
    end

    @redirect = "/monitor"
    redirect_to @redirect
  end

  def alerts
    @count = Alert.count(:all)
    @alerts = Alert.find(:all)
  end

  def available
    @grouplist = Group.find(:all, :conditions => [ "id != '1' AND groups.available = '1'" ], :order => "name ASC")
  end

  def start
    @getip = Host.find(:all, :conditions => [ "live = '1'" ], :limit => 1)
    @countfree = Machine.count(:all, :conditions => [ "state = '0' AND machines.group = ?", params[:groupname]])
    @getfirst = Machine.find(:all, :conditions => [ "state = '0' AND machines.group = ?", params[:groupname]], :order => "name", :limit => 1)
    @countexist = Machine.count(:all, :conditions => [ "machines.group = ?", params[:groupname]])

    for getip in @getip
      @ip = getip.ip
    end

    @time = Time.now.strftime("%Y-%m-%d %H:%M")

    if(@countfree == 0)
      @newcount = @countexist + 1
      @newmachinename = params[:groupname] + @newcount.to_s

      @clonecmd = "ssh root@" + @ip + " xe vm-install new-name-label=" + @newmachinename + " template=Template-" + params[:groupname]
      @startcmd = "ssh root@" + @ip + " xe vm-start vm=" + @newmachinename
      Machine.create(:ip => '', :name => @newmachinename, :username => current_user.login, :group => params[:groupname], :hdsize => '4', :ram => '0', :state => '1', :vncport => '0', :freemem => '0', :starttime => @time)
      User.update(current_user.id, { :activevm => @newmachinename })
      @message = current_user.login + " started VM: " + @newmachinename + "."
      XenLog.create( :logtype => '1', :message => @message )
      system(@clonecmd)
      system(@startcmd)

    else
      for machine in @getfirst
        @clonecmd = "ssh root@" + @ip + " xe vm-install new-name-label=" + machine.name + " template=Template-" + params[:groupname]
        @startcmd = "ssh root@" + @ip + " xe vm-start vm=" + machine.name
        Machine.update(machine.id, { :username => current_user.login, :starttime => @time })
        User.update(current_user.id, { :activevm => machine.name })
        @message = current_user.login + " started VM: " + machine.name + "."
        XenLog.create( :logtype => '1', :message => @message )
        system(@clonecmd)
        system(@startcmd)
      end
    end
  end

  def yourvms
    @yourvms = Machine.find(:all, :conditions => [ "username = ?", current_user.login], :order => "name ASC")
  end

end

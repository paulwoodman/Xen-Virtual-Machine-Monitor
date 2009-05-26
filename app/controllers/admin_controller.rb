class AdminController < ApplicationController
  helper_method :redirect_to
  include AuthenticatedSystem
    
  def index
    @getip = Host.find(:all, :conditions => [ "live = '1'" ], :limit => 1)
    @grouplist = Group.find(:all, :conditions => [ "id != '1'" ], :order => "name ASC")
    @alerts = Alert.find(:all, :order => "id ASC")

    for getip in @getip
      @ip = getip.ip
    end

    if(params[:addalert])
      Alert.create( :message => params[:addalert], :username => current_user.login )
      @message = current_user.login + " added alert: '" + params[:addalert] + "'"
      XenLog.create( :logtype => '13', :message => @message )
    end

    if(params[:delalert])
      @alert = Alert.find( :all, :conditions => [ "id = ?", params[:delalert] ] )
      for alert in @alert
        @alertmessage = alert.message
      end
      Alert.delete(params[:delalert])
      @message = current_user.login + " deleted alert: '" + @alertmessage + "'"
      XenLog.create( :logtype => '14', :message => @message )
    end

    if(params[:groupname])
      if params[:groupname] =~ /\W/
        @valid = 0
      else
        @valid = 1
        @groupcount = Group.count(:all, :select => 'name', :conditions => ["name =?", params[:groupname]])
        if @groupcount == 0
          @tname = "Template-" + params[:groupname]
          Group.create( :name => params[:groupname], :tname => @tname, :lock => 1, :owner => current_user.login, :available => 0 )
          @message = current_user.login + " created group: " + params[:groupname] + "."
          XenLog.create( :logtype => '2', :message => @message )
          @runningname = "Running" + @tname
          Machine.create(:name => @tname, :state => '0', :ip => '', :vncport => '0')
          Machine.create(:name => @runningname, :state => '0', :ip => '', :vncport => '0')
          User.update(current_user.id, {:activetemplate => params[:groupname]})
          @clonecmd = "ssh root@" + @ip + " xe vm-clone new-name-label=" + @tname + " name-label=Template-WindowsMaster"
          system(@clonecmd)
        end
      end
      @showpage = 1
    end

    if(params[:dgroupname])
      @wait = 1
      @machineid = Group.find(:all, :select => 'id', :conditions => ["name = ?", params[:dgroupname]])
      for machine in @machineid
        Group.update(machine.id, { :available => 0 })
        @message = current_user.login + " disabled group: " + params[:dgroupname] + "."
        XenLog.create( :logtype => '5', :message => @message )
      end

    elsif(params[:egroupname])
      @wait = 1
      @machineid = Group.find(:all, :select => 'id', :conditions => ["name = ?", params[:egroupname]])
      for machine in @machineid
        Group.update(machine.id, { :available => 1 })
        @message = current_user.login + " enabled group: " + params[:egroupname] + "."
        XenLog.create( :logtype => '4', :message => @message )
      end

    elsif(params[:ugroupname])
      @wait = 1
      @machineid = Group.find(:all, :select => 'id', :conditions => ["name = ?", params[:ugroupname]])
      for machine in @machineid
        Group.update(machine.id, { :lock => 0 })
        @message = current_user.login + " unlocked group: " + params[:ugroupname] + "."
        XenLog.create( :logtype => '12', :message => @message )
      end

    elsif(params[:lgroupname])
      @wait = 1
      @machineid = Group.find(:all, :select => 'id', :conditions => ["name = ?", params[:lgroupname]])
      for machine in @machineid
        Group.update(machine.id, { :lock => 1, :owner => current_user.login })
        @message = current_user.login + " locked group: " + params[:lgroupname] + "."
        XenLog.create( :logtype => '11', :message => @message )
      end

    elsif(params[:sgroupname])
      @wait = 1
      User.update(current_user.id, { :activetemplate => params[:sgroupname] })

    elsif(params[:lock])
      @wait = 1
      if(params[:lock] == 0.to_s )
        Group.update(1, { :lock => 0 , :owner => '' })
        @message = current_user.login + " unlocked master image."
        XenLog.create( :logtype => '11', :message => @message )
      else
        Group.update(1, { :lock => 1, :owner => current_user.login })
        @message = current_user.login + " locked master image."
        XenLog.create( :logtype => '12', :message => @message )
      end

    elsif(params[:cdetails])
      @wait = 1
      User.update(current_user.id, { :activetemplate => '' })

    else
      @showpage = 1
    end
  end

  def grouplist
    @grouplist = Group.find(:all, :conditions => [ "id != '1'" ], :order => "name ASC")
  end

  def master
    @masterlock = Group.find(:all, :select => "groups.lock, " + "groups.owner", :conditions => [ "id = 1" ])
    @machine = Machine.find(:all, :conditions => [ "name = 'RunningTemplate-WindowsMaster'" ])
  end

  def details
    @templatecount = User.count(:all, :conditions => [ "login = ? AND users.activetemplate != ''", current_user.login])
    @templateinfo = User.find(:all, :conditions => [ "login = ? AND users.activetemplate != ''", current_user.login])
    for template in @templateinfo
      @tmachinename = "Template-" + template.activetemplate
      @rmachinename = "RunningTemplate-" + template.activetemplate
    end
    @rmachine = Machine.find(:all, :conditions => [ "name = ?", @rmachinename ])
  end

  def hosts
    @hosts = Host.find(:all)
  end

  def alerts
    @alertcount = Alert.count(:all)
    @alerts = Alert.find(:all, :order => "id ASC")
  end


  def deletegroup
    @group = Group.find(:all, :conditions => [ "name = ?", params[:dgroup]])
    @templatename = "Template-" + params[:dgroup]
    @runningname = "RunningTemplate-" + params[:dgroup]
    @machine = Machine.find(:all, :conditions => [ "name = ?", @templatename ])
    @machiner = Machine.find(:all, :conditions => [ "name = ?", @runningname ])
    for group in @group
      Group.delete(group.id)
      @message = current_user.login + " deleted group: " + params[:dgroup] + "."
      XenLog.create( :logtype => '3', :message => @message )
    end
    for machine in @machine
      Machine.delete(machine.id)
      @uuid = machine.uuid
    end
    for machine in @machiner
      Machine.delete(machine.id)
    end

    @time = Time.now.strftime("%Y-%m-%d %H:%M")

    @getip = Host.find(:all, :conditions => [ "live = '1'" ], :limit => 1)
    for getip in @getip
      @ip = getip.ip
    end

    @convertcmd = "ssh root@" + @ip + " xe template-param-set is-a-template=false uuid=" + @uuid
    @deletecmd = "ssh root@" + @ip + " xe vm-uninstall force=true uuid=" + @uuid
    system(@convertcmd)
    system(@deletecmd)
  end

  def start
    @message = current_user.login + " powered on " + params[:templatename] + "."
    XenLog.create( :logtype => '1', :message => @message )

    @getip = Host.find(:all, :conditions => [ "live = '1'" ], :limit => 1)
    @machine = Machine.find(:all, :conditions => [ "name = ?", params[:templatename] ])

    @time = Time.now.strftime("%Y-%m-%d %H:%M")

    for getip in @getip
      @ip = getip.ip
    end

    for machine in @machine
      Machine.update(machine.id, { :username => current_user.login, :state => 1, :used => 1, :starttime => @time })
    end

    @clonecmd = "ssh root@" + @ip + " xe vm-install new-name-label=Running" + machine.name + " template=" + params[:templatename]
    @startcmd = "ssh root@" + @ip + " xe vm-start vm=Running" + params[:templatename]

    system(@clonecmd)
    system(@startcmd)
  end

  def copy
    @message = current_user.login + " committed " + params[:templatename] + "."
    XenLog.create( :logtype => '10', :message => @message )
    @getip = Host.find(:all, :conditions => [ "live = '1'" ], :limit => 1)

    @machine = Machine.find(:all, :conditions => [ "name = ?", params[:templatename] ])
    @runningname = "Running" + params[:templatename]
    @machiner = Machine.find(:all, :conditions => [ "name = ?", @runningname ])
    for machineupdate in @machiner
      Machine.update(machineupdate.id, {:ip => ''})
    end

    for getip in @getip
      @ip = getip.ip
    end

    @time = Time.now.strftime("%Y-%m-%d %H:%M")
    
    for machine in @machine
      @convertcmd = "ssh root@" + @ip + " xe template-param-set is-a-template=false uuid=" + machine.uuid
      @deletecmd = "ssh root@" + @ip + " xe vm-uninstall force=true uuid=" + machine.uuid
      @newmachinename = machine.name
    end

    for machine in @machiner
      @templatecmd = "ssh root@" + @ip + " xe vm-param-set is-a-template=true name-label=" + @newmachinename + " force=true uuid=" + machine.uuid
    end

    system(@convertcmd)
    system(@deletecmd)
    system(@templatecmd)

  end

  def commit
    if( params[:templatename] == "Template-WindowsMaster")
      @machinename = "Master Image"
    else
      @machinename = params[:templatename].gsub(/^Template-/, '')
    end
  end

  def poweron
    if( params[:templatename] == "Template-WindowsMaster")
      @machinename = "Master Image"
    else
      @machinename = params[:templatename].gsub(/^Template-/, '')
    end
  end

end

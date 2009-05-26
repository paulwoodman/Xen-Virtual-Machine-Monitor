class XenLogsController < ApplicationController
  # GET /xen_logs
  # GET /xen_logs.xml
  def index
    @xen_logs = XenLog.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @xen_logs }
    end
  end

  # GET /xen_logs/1
  # GET /xen_logs/1.xml
  def show
    @xen_log = XenLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @xen_log }
    end
  end

  # GET /xen_logs/new
  # GET /xen_logs/new.xml
  def new
    @xen_log = XenLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @xen_log }
    end
  end

  # GET /xen_logs/1/edit
  def edit
    @xen_log = XenLog.find(params[:id])
  end

  # POST /xen_logs
  # POST /xen_logs.xml
  def create
    @xen_log = XenLog.new(params[:xen_log])

    respond_to do |format|
      if @xen_log.save
        flash[:notice] = 'XenLog was successfully created.'
        format.html { redirect_to(@xen_log) }
        format.xml  { render :xml => @xen_log, :status => :created, :location => @xen_log }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @xen_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /xen_logs/1
  # PUT /xen_logs/1.xml
  def update
    @xen_log = XenLog.find(params[:id])

    respond_to do |format|
      if @xen_log.update_attributes(params[:xen_log])
        flash[:notice] = 'XenLog was successfully updated.'
        format.html { redirect_to(@xen_log) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @xen_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /xen_logs/1
  # DELETE /xen_logs/1.xml
  def destroy
    @xen_log = XenLog.find(params[:id])
    @xen_log.destroy

    respond_to do |format|
      format.html { redirect_to(xen_logs_url) }
      format.xml  { head :ok }
    end
  end
end

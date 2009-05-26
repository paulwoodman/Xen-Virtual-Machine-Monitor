require 'test_helper'

class XenLogsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:xen_logs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_xen_log
    assert_difference('XenLog.count') do
      post :create, :xen_log => { }
    end

    assert_redirected_to xen_log_path(assigns(:xen_log))
  end

  def test_should_show_xen_log
    get :show, :id => xen_logs(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => xen_logs(:one).id
    assert_response :success
  end

  def test_should_update_xen_log
    put :update, :id => xen_logs(:one).id, :xen_log => { }
    assert_redirected_to xen_log_path(assigns(:xen_log))
  end

  def test_should_destroy_xen_log
    assert_difference('XenLog.count', -1) do
      delete :destroy, :id => xen_logs(:one).id
    end

    assert_redirected_to xen_logs_path
  end
end

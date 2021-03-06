require 'test_helper'
include Devise::TestHelpers

class MeasuresControllerTest < ActionController::TestCase
  
  setup do
    dump_database
    collection_fixtures 'measures', 'selected_measures', 'records'
    @user = Factory(:user_w_selected_measures)
    
    @selected_measure = @user.selected_measures.first
    @result = {"measure_id" => @selected_measure['id'],
               "sub_id" => @selected_measure['subs'].first,
               "effective_date" => 1293753600,
               "population" => 322,
               "denominator" => 322,
               "numerator" => 263,
               "antinumerator" => 59,
               "exclusions" => 0 }
    sign_in @user
  end
  
  test "GET 'definition'" do
    get :definition, :id => '0013'
    assert_response :success
    assert_not_nil assigns(:definition)
  end
  
  test "dashboard" do
    get :index
    assert_response :success
    assert_not_nil assigns(:core_measures)
    assert_not_nil assigns(:core_alt_measures)
    assert_not_nil assigns(:alt_measures)
  end

  test "measure_report for provider" do
      @user.stubs(registry_name: 'registry')
      @user.stubs(registry_id: '1234')
      @user.stubs(npi: '456')
      @user.stubs(tin: '789')
      
      @controller.define_singleton_method(:extract_result) do |id, sub_id, effective_date|
        { :id => id, :sub_id => sub_id, :population => 5,
          :denominator => 4, :numerator => 2,
          :exclusions => 0
        }
      end
      
      get :measure_report, :format => :xml, :type => "provider"
      assert_response :success
      d = Digest::SHA1.new
      checksum = d.hexdigest(response.body)
      l = Log.first(:conditions => {:checksum => checksum})
      assert_not_nil l
      assert_equal @user.username, l.username
  end
  
#  test "get providers json uncalculated" do
#    provider_count = 5
#    provider_count.times { Factory(:provider) }
#    
#    QME::QualityReport.any_instance.expects(:result).never
#    QME::QualityReport.any_instance.stubs(:calculated?).returns(false).times(provider_count)
#
#    @providers = Provider.all
#
#    xhr :get, :providers, id: @selected_measure['id'], :format => :json, :provider => @providers.map(&:id)
#  end
  
  test "get providers calculated" do
    provider_count = 5
    provider_count.times { Factory(:provider) }
    
    QME::QualityReport.any_instance.stubs(:result).returns(@result).times(provider_count)
    QME::QualityReport.any_instance.stubs(:calculated?).returns(true).times(provider_count)

    @providers = Provider.all

    xhr :get, :providers, id: @selected_measure['id'], :format => :json, :provider => @providers.map(&:id)
  end
  
  def get_measure_report_and_test
    
  end
  
end
  

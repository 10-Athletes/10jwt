require 'test_helper'

class TokensControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get tokens_create_url
    assert_response :success
  end

end

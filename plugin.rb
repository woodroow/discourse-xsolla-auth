# name: discourse-xsolla-auth
# about: Auth with xsolla login widget
# version: 0.1
# author: Veshkurov Artem
# url: https://github.com/woodroow/discourse-xsolla-auth
# used JWT plugin: https://github.com/discourse/discourse-jwt

enabled_site_setting :xsolla_auth_enabled
enabled_site_setting :xsolla_auth_login
enabled_site_setting :xsolla_auth_secret

require_dependency 'auth/oauth2_authenticator'

gem "discourse-omniauth-jwt-xsolla", "0.1.1", require: false
gem "http", require: false

require 'omniauth/jwt'

class XsollaAuthenticator < ::Auth::OAuth2Authenticator

  def name
    "xsolla"
  end

  def enabled?
    SiteSetting.xsolla_auth_enabled
  end

  def register_middleware(omniauth)
    omniauth.provider :jwt,
                      :name => 'xsolla',
                      :uid_claim => 'id',
                      :required_claims => ['email'],
                      :secret => SiteSetting.xsolla_auth_secret,
                      :auth_url => "https://xl-widget.xsolla.com/?projectId=#{SiteSetting.xsolla_auth_login}&login_url=https://#{GlobalSetting.hostname}/forum/auth/xsolla/callback"
  end

  def after_authenticate(auth)
    result = Auth::Result.new

    uid = auth[:uid]
    result.name = auth[:info].name
    result.username = auth[:info].name
    result.email = auth[:info].email
    result.email_valid = true

    current_info = ::PluginStore.get("xsolla", "xsolla_user_#{uid}")
    if current_info
      result.user = User.where(id: current_info[:user_id]).first
    end
    result.extra_data = { jwt_user_id: uid }
    result
  end

  def after_create_account(user, auth)
    ::PluginStore.set("xsolla", "xsolla_user_#{auth[:extra_data][:jwt_user_id]}", {user_id: user.id })
  end

end

title = "Xsolla Login"
button_title = "with Xsolla"

auth_provider :title => button_title,
              :authenticator => XsollaAuthenticator.new('xsolla'),
              :message => "Authorizing with #{title} (make sure pop up blockers are not enabled)",
              :frame_width => 920,
              :frame_height => 800

register_css <<CSS
.btn-social.xsolla {
  background: #ff005b;
}
CSS
              
              
Redmine::Plugin.register :redmine_ssl_auth do
  name 'modified Redmine SSL auth plugin'
  author 'Malte Jan Kaffenberger'
  description 'Enable authentication using SSL client certificates'
  version '0.0.1'
end

# encrypt outgoing mails
ActionDispatch::Callbacks.to_prepare do
  require_dependency 'account_controller'
  AccountController.send(:include, AccountControllerPatch)
end
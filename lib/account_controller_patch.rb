require_dependency 'account_controller'

module AccountControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      before_filter :try_ssl_auth, :only => :login
    end
  end

  module InstanceMethods
    def try_ssl_auth
      if not params[:skip_ssl]
        logger.debug ">>> Trying ssl_auth... "
        session[:email] = request.env["SSL_CLIENT_S_DN_CN"]
        if session[:email].nil? and request.env['HTTP_SSL_CLIENT_S_DN']
          logger.debug ">>> try_ssl_auth: HTTP_SSL_CLIENT_S_DN = " + request.env['HTTP_SSL_CLIENT_S_DN']
          tmp = request.env['HTTP_SSL_CLIENT_S_DN'].scan(/emailAddress=([\w\d\-\.]+@[\w\d\-\.]+\.[\w\d]+)/).flatten
          session[:email] = tmp.first
        end
      end
      if session[:email]
        logger.info ">>> Login with certificate email: " + session[:email]
        user = User.find_by_mail(session[:email])
        # TODO: try to register on the fly
        unless user.nil?
          # Valid user
          return false if !user.active?
          user.update_attribute(:last_login_on, Time.now) if user && !user.new_record?
          self.logged_user = user
          return true
        end
      end
      return false
    end
  end
end

AccountController.send(:include, AccountControllerPatch)

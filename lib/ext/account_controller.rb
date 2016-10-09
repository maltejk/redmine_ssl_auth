class AccountController < ApplicationController
  def try_ssl_auth
    logger.debug ">>> Trying ssl_auth... "
    session[:email] = request.env["SSL_CLIENT_S_DN_CN"]
    if session[:email].nil? and request.env['HTTP_SSL_CLIENT_S_DN']
      logger.debug ">>> try_ssl_auth: HTTP_SSL_CLIENT_S_DN = " + request.env['HTTP_SSL_CLIENT_S_DN']
      tmp = request.env['HTTP_SSL_CLIENT_S_DN'].scan(/emailAddress=([\w\d\-\.]+@[\w\d\-\.]+\.[\w\d]+)/).flatten
      session[:email] = tmp.first
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

  def ssl_login
    if params[:force_ssl]
      if try_ssl_auth
        redirect_back_or_default :controller => 'my', :action => 'page'
        return
      else
        render_403
        return
      end
    end
    if !User.current.logged? and not params[:skip_ssl]
      if try_ssl_auth
        redirect_back_or_default :controller => 'my', :action => 'page'
        return
      end
    end

    login
  end
end

class Spree::UserRegistrationsController < Devise::RegistrationsController
  helper 'spree/base', 'spree/store'

  if Spree::Auth::Engine.dash_available?
    helper 'spree/analytics'
  end

  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::SSL
  include Spree::Core::ControllerHelpers::Store

  ssl_required
  before_filter :check_permissions, :only => [:edit, :update]
  skip_before_filter :require_no_authentication, :only => [:new, :register_phone, :verify_phone, :create_password]

  # GET /resource/sign_up
  def new
    # binding.pry
    super
    @user = resource
  end

  # POST /resource/register_phone
  def register_phone
    @user = build_resource(phone_sign_up_params)
    if resource.save
      # resource.generate_sms_token
      resource.resend_sms_token
    else
      render :new
    end
  end

  # POST /resource/verify_phone
  def verify_phone
    # TODO: this seems risky as it only relies on the token to retrieve the user record
    self.resource = resource_class.confirm_by_sms_token(params[:sms_token])
    if resource.errors.empty?
      set_flash_message :notice, :confirmed
      # sign_in_and_redirect(resource_name, resource)
      binding.pry
      sign_in resource_name, resource, bypass: true
      # warden.set_user( resource, scope: resource_name , run_callbacks: false)
      session[:spree_user_signup] = true
      associate_user
      render :create_password
    else
      render :register_phone
    end
  end


  def create_password
    binding.pry
    # FIXME: this is highly insecure
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    # resource = resource_class.find_by(phone: params[resource_name][:phone])
    # if resource.update_without_password(spree_user_params)
    #   update_attributes
    if resource.reset_password!(params[:spree_user][:password], params[:spree_user][:password_confirmation])
      sign_in resource_name, resource #, bypass: true
      redirect_back_or_default(root_url)
      # respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      respond_with resource
    end
    # update
  end

  # POST /resource/register_phone. this should be ajax
  def register_with_phone
    # binding.pry
    if params[:create_sms_token]
      @user = build_resource(phone_sign_up_params)
      # resource.
      if resource.save
        resource.resend_sms_token
      end
      render :new
    else
      # TODO: this seems risky as it only relies on the token to retrieve the user record
      self.resource = resource_class.confirm_by_sms_token(params[:sms_token])
      if resource.errors.empty? && resource.reset_password!(params[:spree_user][:password], params[:spree_user][:password_confirmation])
        # set_flash_message :notice, :confirmed
        #  # sign_in_and_redirect(resource_name, resource)
        # binding.pry
        # # sign_in resource_name, resource, bypass: true
        # # warden.set_user( resource, scope: resource_name , run_callbacks: false)
        # session[:spree_user_signup] = true
        # associate_user
        # render :create_password
        set_flash_message(:notice, :signed_up)
        sign_in(resource_name, resource)
        session[:spree_user_signup] = true
        associate_user
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        render :new
      end
    end
  end

  # POST /resource/register_phone. this should be ajax
  def register_with_email
    binding.pry
    @user = build_resource(spree_user_params)
    if resource.save
      binding.pry
      set_flash_message(:notice, :signed_up)
      sign_in(:spree_user, @user)
      session[:spree_user_signup] = true
      associate_user
      respond_with resource, location: after_sign_up_path_for(resource)
      # redirect_to spree.root
    else
      binding.pry
      clean_up_passwords(resource)
      render :verify_phone
    end
  end

  # POST /resource/sign_up
  def create
    binding.pry
    @user = build_resource(spree_user_params)
    if resource.save
      binding.pry
      set_flash_message(:notice, :signed_up)
      sign_in(:spree_user, @user)
      session[:spree_user_signup] = true
      associate_user
      respond_with resource, location: after_sign_up_path_for(resource)
      # redirect_to spree.root
    else
      binding.pry
      clean_up_passwords(resource)
      render :new
    end
  end

  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  def update
    super
  end

  # DELETE /resource
  def destroy
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    super
  end

  protected
  def check_permissions
    binding.pry
    authorize!(:create, resource)
  end
  def xafter_sign_up_path_for(resource)

  end

  private
  def spree_user_params
    binding.pry
    params.require(:spree_user).permit(Spree::PermittedAttributes.user_attributes)
  end

  def phone_sign_up_params
    params.require(:spree_user).permit(:phone)
  end

  def create_password_params
    params.require(:spree_user).permit([:password, :password_confirmation])
  end
end

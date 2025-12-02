# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :require_no_authentication, only: [ :new, :create ]
  before_action :authorize_admin, only: [ :new, :create ]

  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  def create
    build_resource(sign_up_params)

    if resource.save
      flash[:notice] = "USUARIO CREADO"
      redirect_to users_path and return
    else
      Rails.logger.error resource.errors.full_messages
      clean_up_passwords(resource)
      set_minimum_password_length
      respond_with resource
    end
  end

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  def authorize_admin
    unless user_signed_in? && current_user.admin?
        flash[:alert]= "NO ESTÁ AUTORIZADO PARA REALIZAR ESTA ACCIÓN"
        redirect_to root_path
    end
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name_community, :type_community, :saldo_inicial, :name, :role ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name_community, :type_community, :saldo_inicial, :name, :role ])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end

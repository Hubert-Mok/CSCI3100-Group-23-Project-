# frozen_string_literal: true

class StripeAccountsController < ApplicationController
  before_action :require_login

  def new
    if current_user.stripe_account_id.present?
      redirect_to profile_path, notice: "Your Stripe account is already connected."
      return
    end

    account_id = session[:stripe_connect_account_id]
    unless account_id.present?
      account = ::Stripe::Account.create(
        type: "express",
        country: "HK",
        email: current_user.email
      )
      account_id = account.id
      session[:stripe_connect_account_id] = account_id
    end

    account_link = ::Stripe::AccountLink.create(
      account: account_id,
      refresh_url: stripe_account_url,
      return_url: callback_stripe_account_url,
      type: "account_onboarding"
    )
    redirect_to account_link.url, allow_other_host: true
  end

  def callback
    account_id = session[:stripe_connect_account_id]
    if account_id.blank?
      redirect_to profile_path, alert: "Stripe onboarding session expired. Please try again."
      return
    end

    current_user.update!(stripe_account_id: account_id)
    session.delete(:stripe_connect_account_id)
    redirect_to profile_path, notice: "Stripe account connected successfully. You can now receive payments."
  end
end

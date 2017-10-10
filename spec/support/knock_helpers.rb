module KnockHelpers
  def token_for_user(user)
    Knock::AuthToken.new(payload: {sub: user.id}).token
  end

  def claim_token(token)
    Knock::AuthToken.new(token: token).payload
  end
end

class Ability
  include CanCan::Ability

  def initialize(user)
    if user
      manager_abilities(user) if user.manager?
      client_abilities(user) if user.client?
    else
      visitor_abilities(user)
    end
  end

  def manager_abilities(_user)
    can :manage, :all
  end

  def client_abilities(user)
    can :create, Issue
    can :manage, Issue, author_id: user.id
    can :read, User, id: user.id
  end

  def visitor_abilities(_user)
    can :create, User
  end
end

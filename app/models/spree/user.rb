module Spree
  class User < ActiveRecord::Base
    include UserAddress
    include UserPaymentSource

    # attr_accessor :login
#    binding.pry
    devise :database_authenticatable, :registerable, :recoverable,
           :rememberable, :trackable, :validatable, :encryptable, :encryptor => 'authlogic_sha512'
    devise :confirmable if Spree::Auth::Config[:confirmable]
    devise :sms_activable

    acts_as_paranoid
    after_destroy :scramble_email_and_password

    has_many :orders

    before_validation :set_login
    # before_validation :set_sms_confirmation_token if trying_phone_registration

    users_table_name = User.table_name
    roles_table_name = Role.table_name

    scope :admin, -> { includes(:spree_roles).where("#{roles_table_name}.name" => "admin") }

    def self.admin_created?
      User.admin.count > 0
    end

    def self.find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions.to_h).where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
      else
        where(conditions.to_h).first
      end
    end

    def admin?
      has_spree_role?('admin')
    end

    def login
      @login || self.email || self.phone
    end

    validates :phone,
      # presence: true,
      allow_blank: true,
      uniqueness: { case_sensitive: false },
      numericality: true,
      length: { is: 11 }

    validate :phone_or_email

    protected
    #   def password_required?
    #     binding.pry
    #     # user_authentications.empty? &&
    #     !persisted? || !(phone? && sms_confirmatio_token? ) || password.present? || password_confirmation.present?
    #   end

      # determines if am SMS is automatically sent after signup
      def sms_confirmation_required?
        self.phone ? super : false
      end

      # this is for email
      def confirmation_required?
        self.email ? super : false
      end

    # if using oauth, that module should set the "login"
    def email_required?
      (self.phone.present? || self.login.present? ) ? false : super
    end

    def password_required?
      binding.pry
      awaiting_phone_verification? ? false : super
    end

    def awaiting_phone_verification?
      # binding.pry
      !persisted? && self.phone?
      # (self.phone? && self.sms_confirmation_token?)
    end

    def root_path
      '/'
    end


    private

      def set_login
        # for now force login to be same as email, eventually we will make this configurable, etc.
        self.login ||= self.email if self.email
      end

      def scramble_email_and_password
        self.email = SecureRandom.uuid + "@example.net"
        self.login = self.email
        self.password = SecureRandom.hex(8)
        self.password_confirmation = self.password
        self.save
      end

      def phone_or_email
        if (phone.blank? && email.blank?)
          errors.add(:base, '手机号或Email地址')
        end
      end
  end
end

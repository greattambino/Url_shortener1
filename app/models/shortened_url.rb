# == Schema Information
#
# Table name: shortened_urls
#
#  id           :integer          not null, primary key
#  long_url     :text             not null
#  short_url    :string           not null
#  submitter_id :integer          not null
#  created_at   :datetime
#  updated_at   :datetime
#

require 'securerandom'

class ShortenedUrl < ActiveRecord::Base
  validates :short_url, uniqueness: true, presence: true
  validates :long_url, presence: true
  validates :submitter_id, presence: true

  belongs_to :submitter,
    class_name: "User",
    foreign_key: :submitter_id,
    primary_key: :id

  has_many :visits,
    class_name: "Visit",
    foreign_key: :shortened_url_id,
    primary_key: :id

  has_many :visitors,
    Proc.new { distinct },
    through: :visits,
    source: :users

  def self.random_code
    random_code = ""
    while random_code == "" || ShortenedUrl.find_by_short_url(random_code)
      random_code = SecureRandom::urlsafe_base64(16)
    end
    random_code
  end

  def self.create_for_user_and_long_url!(user, long_url)
    ShortenedUrl.create!(submitter_id: user.id,
      long_url: long_url,
      short_url: random_code
    )
  end

  def num_clicks
    visits.count
  end

  def num_uniques
    visitors.count
  end

  def num_recent_uniques(mins = 10)
    Visit.select('user_id').where(
      "shortened_url_id = ? AND created_at > ?",
      self.id, mins.minutes.ago
    ).distinct.count(:user_id)
  end
end

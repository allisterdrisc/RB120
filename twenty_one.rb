require 'yaml'
MESSAGES = YAML.load_file('twenty_one_text.yml')

module Hand
  def display_hand
    puts "~*oO{ #{name}'s hand }Oo*~"
    hand.each(&:display_card)
    puts "Total: #{total}"
    puts ''
  end

  def add_card(new_card)
    hand << new_card
  end

  # rubocop:disable Metrics/MethodLength
  def total
    total = 0
    hand.each do |card|
      if card.ace?
        total += 11
      elsif card.ten_pointer?
        total += 10
      else
        total += card.value.to_i
      end
    end

    hand.select(&:ace?).count.times do
      break if total <= 21
      total -= 10
    end
    total
  end
  # rubocop:enable Metrics/MethodLength

  def busted?
    total > 21
  end
end

class Participant
  include Hand
  attr_accessor :name, :hand, :score

  def initialize
    @hand = []
    @score = 0
  end

  def increase_score
    self.score += 1
  end

  def reset_score
    self.score = 0
  end
end

class Dealer < Participant
  def initialize
    super
    @name = ['Gus', 'Shark', 'Big Guy'].sample
  end

  def display_initial_hand
    puts "~*oO{ #{name}'s initial hand }Oo*~"
    hand.first.display_card
    puts "#{name} has #{hand.first} and a mystery card..."
    puts ''
  end
end

class Player < Participant
  def choose_name
    name = ''
    loop do
      puts "What's your name?"
      name = gets.chomp
      break unless name.strip.empty?

      puts MESSAGES['invalid']
    end
    self.name = name
  end

  def display_initial_hand
    puts "~*oO{ #{name}'s initial hand }Oo*~"
    hand.each(&:display_card)
    puts "You have #{hand[0]} and #{hand[1]}."
    puts "This gives you a total of #{total}!"
    puts ''
  end
end

class Deck
  attr_accessor :cards

  def initialize
    @cards = full_shuffled_deck
  end

  def deal_card
    cards.pop
  end

  private

  def full_shuffled_deck
    deck = []
    suits = %w(Hearts Diamonds Clubs Spades)
    values = %w(2 3 4 5 6 7 8 9 10 J Q K A)
    suits.each do |suit|
      values.each do |value|
        deck << Card.new(suit, value)
      end
    end
    deck.shuffle
  end
end

class Card
  attr_accessor :suit, :value

  def initialize(suit, value)
    @suit = suit
    @value = value
  end

  def to_s
    "the #{value_full_name(value)} of #{suit}"
  end

  # rubocop:disable Metrics/MethodLength
  def display_card
    puts '+--------+'
    puts "|#{suit[0]}       |"
    puts '|        |'
    if value.size < 2
      puts "|   #{value}    |"
    else
      puts "|   #{value}   |"
    end
    puts '|        |'
    puts "|       #{suit[0]}|"
    puts '+--------+'
  end
  # rubocop:enable Metrics/MethodLength

  def ace?
    value == 'A'
  end

  def ten_pointer?
    (value == 'J') || (value == 'Q') || (value == 'K')
  end

  private

  def value_full_name(value)
    case value
    when 'J' then 'Jack'
    when 'Q' then 'Queen'
    when 'K' then 'King'
    when 'A' then 'Ace'
    else
      value
    end
  end
end

class TwentyOneGame
  attr_accessor :player, :dealer, :deck

  ROUNDS_TO_WIN = 3

  def initialize
    @player = Player.new
    @dealer = Dealer.new
    @deck = Deck.new
  end

  def start
    display_opening
    loop do
      game_round_loop
      display_champion
      break unless play_again?
      reset_game
    end
    display_goodbye
  end

  private

  def game_round_loop
    loop do
      deal_and_display_cards
      player_turn
      dealer_turn unless player.busted?
      update_scores
      display_round_result
      break if champion?
      play_next_round? ? reset_round : break
    end
  end

  def display_opening
    display_welcome
    return unless see_rules?
    input = nil
    loop do
      display_rules
      input = gets.chomp.downcase
      break if input == ' '
    end
  end

  def display_welcome
    clear
    puts MESSAGES['welcome']
    puts "You're playing against the dealer, #{dealer.name}."
    player.choose_name
    puts ''
    puts "First to #{ROUNDS_TO_WIN} is the champion!"
  end

  def display_rules
    clear
    puts MESSAGES['rules']
  end

  def clear
    system 'clear'
  end

  def see_rules?
    choice = nil
    loop do
      puts MESSAGES['read_rules']
      choice = gets.chomp.downcase
      break if ['y', 'n'].include?(choice)
      puts MESSAGES['invalid']
    end
    choice == 'y'
  end

  def deal_and_display_cards
    deal_cards
    display_initial_hands
  end

  def deal_cards
    2.times do
      player.add_card(deck.deal_card)
      dealer.add_card(deck.deal_card)
    end
  end

  def display_initial_hands
    clear
    player.display_initial_hand
    dealer.display_initial_hand
  end

  # rubocop:disable Metrics/MethodLength
  def player_turn
    puts "--#{player.name}'s turn--"
    loop do
      puts MESSAGES['hit_or_stay']
      if player_hit_or_stay == 's'
        display_player_stays
        break
      elsif player.busted?
        break
      else # chose to hit
        player_hits
        break if player.busted?
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def player_hit_or_stay
    choice = nil
    loop do
      choice = gets.chomp.downcase
      break if ['h', 's'].include?(choice)
      puts MESSAGES['invalid']
    end
    choice
  end

  def display_player_stays
    clear
    puts "#{player.name} stays!"
  end

  def player_hits
    clear
    player.add_card(deck.deal_card)
    puts "#{player.name} hits!"
    player.display_hand
  end

  # rubocop:disable Metrics/MethodLength
  def dealer_turn
    puts "--#{dealer.name}'s turn--"
    loop do
      if dealer_stays?
        puts "#{dealer.name} stays!"
        break
      elsif dealer.busted?
        break
      else # dealer has less than 17
        puts "#{dealer.name} hits!"
        dealer_hits
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def dealer_stays?
    dealer.total >= 17 && !dealer.busted?
  end

  def dealer_hits
    dealer.add_card(deck.deal_card)
  end

  def display_player_busted
    puts "#{player.name} busted! So #{dealer.name} wins!"
  end

  def display_dealer_busted
    puts "#{dealer.name} busted! So #{player.name} wins!"
  end

  def display_final_hands
    player.display_hand
    dealer.display_hand
  end

  def display_round_result
    display_final_hands
    if player.busted?
      display_player_busted
    elsif dealer.busted?
      display_dealer_busted
    else
      display_round_winner
    end
    display_score
  end

  def update_scores
    if player.busted? || dealer.busted?
      bust_update_scores
    else
      no_bust_update_scores
    end
  end

  def bust_update_scores
    if player.busted?
      dealer.increase_score
    elsif dealer.busted?
      player.increase_score
    end
  end

  def no_bust_update_scores
    if player_hand_wins?
      player.increase_score
    elsif dealer_hand_wins?
      dealer.increase_score
    end
  end

  def display_round_winner
    if player_hand_wins?
      puts "#{player.name} wins with a hand total of #{player.total}!"
    elsif dealer_hand_wins?
      puts "#{dealer.name} wins with a hand total of #{dealer.total}!"
    else
      puts "It's a tie! Both players have a hand total of #{player.total}!"
    end
  end

  def player_hand_wins?
    player.total > dealer.total
  end

  def dealer_hand_wins?
    player.total < dealer.total
  end

  def display_score
    puts ''
    puts "--#{player.name}'s score: #{player.score} --"
    puts "--#{dealer.name}'s score: #{dealer.score} --"
  end

  def reset_round
    player.hand = []
    dealer.hand = []
  end

  def play_next_round?
    input = nil
    loop do
      puts MESSAGES['next_round']
      input = gets.chomp.downcase
      break if input == ' '
      puts MESSAGES['invalid']
    end
    input == ' '
  end

  def champion?
    player.score == ROUNDS_TO_WIN || dealer.score == ROUNDS_TO_WIN
  end

  def display_champion
    if player.score == ROUNDS_TO_WIN
      puts "Congrats! You won #{ROUNDS_TO_WIN} rounds!"
      puts "A big check addressed to #{player.name} coming soon!"
    else
      puts "The dealer won #{ROUNDS_TO_WIN} rounds!"
      puts 'Better luck next time.'
      puts "#{dealer.name} has the house on their side..."
    end
  end

  def play_again?
    choice = nil
    loop do
      puts MESSAGES['play_again']
      choice = gets.chomp.downcase
      break if ['y', 'n'].include?(choice)
      puts MESSAGES['invalid']
    end
    choice == 'y'
  end

  def reset_game
    self.deck = Deck.new
    player.hand = []
    dealer.hand = []
    player.reset_score
    dealer.reset_score
  end

  def display_goodbye
    clear
    puts MESSAGES['goodbye']
  end
end

game = TwentyOneGame.new
game.start

module Displayable
  LANGUAGE = 'en'
  require 'yaml'
  MESSAGES = YAML.load_file('rps_text.yml')
  POINTS_TO_WIN = 2

  def messages(message, lang = 'en')
    MESSAGES[lang][message]
  end

  def prompt(message_key)
    message = messages(message_key, LANGUAGE)
    puts message
  end

  def display_welcome_message
    clear
    prompt('welcome')
    puts "First to #{POINTS_TO_WIN} points wins!"
  end

  def display_rules
    prompt('rules')
  end

  def display_astroboy_info
    prompt('astroboy_info')
  end

  def display_bender_info
    prompt('bender_info')
  end

  def display_walle_info
    prompt('walle_info')
  end

  def display_rubocop_info
    prompt('rubocop_info')
  end

  def display_opponent_info(computer_name)
    puts "You're playing against #{computer_name}!"
    puts ''
    case computer_name
    when 'Astro Boy' then display_astroboy_info
    when 'Bender' then display_bender_info
    when 'Wall-E' then display_walle_info
    when 'Rubocop' then display_rubocop_info
    end
  end

  def display_moves(human, computer)
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
  end

  def display_winner(human, computer)
    if human.move.winning_move?(computer.move)
      puts "#{human.name} won!"
    elsif computer.move.winning_move?(human.move)
      puts "#{computer.name} won!"
    else
      puts "It's a tie!"
    end
  end

  def display_score(human, computer)
    puts "#{human.name}'s score: #{human.score}"
    puts "#{computer.name}'s score: #{computer.score}"
  end

  def display_grand_winner(human, computer)
    puts ''
    puts "#{winner(human, computer)} got #{POINTS_TO_WIN} points and wins!"
    puts ''
  end

  def display_players_move_history(human, computer)
    puts "#{human.name}'s moves:"
    puts human.show_move_history
    puts ''
    puts "#{computer.name}'s moves:"
    puts computer.show_move_history
    puts ''
  end

  def display_goodbye_message
    clear
    prompt('goodbye')
  end

  def clear
    system 'clear'
  end
end

class Move
  attr_accessor :value

  VALUES = ['rock', 'paper', 'scissors', 'lizard', 'spock']

  WINNING_MOVES = {
    rock: ['scissors', 'lizard'],
    paper: ['rock', 'spock'],
    scissors: ['paper', 'lizard'],
    lizard: ['paper', 'spock'],
    spock: ['scissors', 'rock']
  }

  def initialize(value)
    @value = value
  end

  def winning_move?(other_move)
    WINNING_MOVES[value.to_sym].include?(other_move.to_s)
  end

  def to_s
    @value
  end
end

class Player
  attr_accessor :move, :name, :score

  def initialize
    @score = 0
  end

  def increase_score
    self.score += 1
  end

  def winning_score?
    score == Displayable::POINTS_TO_WIN
  end

  def reset_score
    self.score = 0
  end
end

class Human < Player
  @@move_history = []

  def choose_name
    input = ""
    loop do
      puts "What's your name?"
      input = gets.chomp
      break unless input.empty?

      puts "Sorry, must enter a value."
    end
    self.name = input
  end

  def choose_move
    choice = nil
    loop do
      puts "Please choose rock, paper, scissors, lizard, or spock:"
      choice = gets.chomp
      break if Move::VALUES.include?(choice)

      puts "Sorry, please enter full spelling of your choice."
    end
    self.move = Move.new(choice)
    update_move_history(move)
  end

  def update_move_history(move)
    @@move_history << move
  end

  def show_move_history
    @@move_history
  end
end

class Computer < Player
  NAME_CHOICES = { 1 => 'Astro Boy',
                   2 => 'Bender',
                   3 => 'Wall-E',
                   4 => 'Rubocop' }

  @@move_history = []

  def assign_name
    puts 'Which robot would you like to play against?'
    puts 'Astro Boy(1), Bender(2), Wall-E(3), Rubocop(4)'
    input = nil
    loop do
      input = gets.chomp
      break if ['1', '2', '3', '4'].include?(input)

      puts 'Please type 1, 2, 3, or 4'
    end
    self.name = NAME_CHOICES[input.to_i]
  end

  def choose_move(person_move)
    case @name
    when 'Astro Boy' then astroboy_move(person_move)
    when 'Bender' then bender_move(person_move)
    when 'Wall-E' then walle_move
    when 'Rubocop' then rubocop_move
    end
    update_move_history(move)
  end

  def astroboy_move(person_move)
    self.move = Move.new(find_worst_move(person_move))
  end

  def bender_move(person_move)
    self.move = Move.new(find_best_move(person_move))
  end

  def walle_move
    self.move = Move.new('rock')
  end

  def rubocop_move
    self.move = Move.new(Move::VALUES.sample)
  end

  def find_best_move(person_move)
    person_lose_move = person_move.to_s
    Move::WINNING_MOVES.select do |_, lose_moves|
      lose_moves.include?(person_lose_move)
    end.first.first.to_s
  end

  def find_worst_move(person_move)
    person_win_move = person_move.to_s.to_sym
    Move::WINNING_MOVES[person_win_move].sample
  end

  def update_move_history(move)
    @@move_history << move
  end

  def show_move_history
    @@move_history
  end
end

class RPSGame
  include Displayable
  attr_accessor :human, :computer

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def keep_score
    if human.move.winning_move?(computer.move)
      human.increase_score
    elsif computer.move.winning_move?(human.move)
      computer.increase_score
    end
  end

  def winner(human, computer)
    if human.winning_score?
      human.name
    elsif computer.winning_score?
      computer.name
    end
  end

  def check_for_grand_winner
    display_grand_winner(human, computer) if winner(human, computer)
  end

  def play_next_round?
    puts ''
    puts 'Do you want to play the next round? (y/n)'
    input = nil
    loop do
      input = gets.chomp
      break if ['y', 'n'].include?(input)
      puts 'Sorry, invalid input.'
    end
    input == 'y'
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp
      break if ['y', 'n'].include?(answer.downcase)

      puts "Sorry, must be y or n."
    end

    return true if answer.downcase == 'y'
    return false if answer.downcase == 'n'
  end

  def reset_scores
    human.reset_score
    computer.reset_score
  end

  def setup_game
    display_welcome_message
    display_rules
    human.choose_name
    computer.assign_name
    clear
    display_opponent_info(computer.name)
  end

  def players_move
    human.choose_move
    computer.choose_move(human.move)
    clear
    display_moves(human, computer)
  end

  def players_scores
    display_winner(human, computer)
    keep_score
    display_score(human, computer)
  end

  def play_round
    players_move
    players_scores
    check_for_grand_winner
  end

  # rubocop:disable Metrics/MethodLength
  def play
    setup_game
    loop do
      reset_scores
      loop do
        play_round
        break if winner(human, computer)
        break unless play_next_round?
        clear
      end
      display_players_move_history(human, computer)
      break unless play_again?
      clear
    end
    display_goodbye_message
  end
  # rubocop:enable Metrics/MethodLength
end

RPSGame.new.play

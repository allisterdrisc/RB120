module Displayable
  WINNING_ROUNDS = 3

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts "First to win #{WINNING_ROUNDS} rounds wins the game!"
    puts ''
  end

  def display_board
    puts "#{human.name}: #{human.marker}"
    puts "#{computer.name}: #{computer.marker}"
    board.draw
    puts ''
  end

  def display_score
    puts "#{human.name}'s score: #{human.score}"
    puts "#{computer.name}'s score: #{computer.score}"
    puts ''
  end

  def display_round_results
    display_board
    display_score
    case board.winning_marker
    when human.marker
      puts "#{human.name} won!"
    when computer.marker
      puts "#{computer.name} won!"
    else
      puts "It's a tie."
    end
  end

  def display_grand_winner
    puts "#{grand_winner} won #{WINNING_ROUNDS} rounds and wins the game!"
    puts ''
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ''
  end

  def display_goodbye_message
    puts 'Thanks for playing Tic Tac Toe, bye!'
    puts ''
  end
end

module Formatable
  def prompt(message)
    puts "==> #{message}"
    puts ''
  end

  def joiner(arr = unmarked_keys, delimiter = ', ', word = 'or')
    size = arr.size
    case size
    when 0 then ''
    when 1 then arr.join
    when 2 then arr.join(" #{word} ")
    else
      arr[-1] = "#{word} #{arr[-1]}"
      arr.join(delimiter)
    end
  end

  def clear
    system 'clear'
  end
end

class Board
  attr_reader :squares

  include Formatable
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]
  def initialize
    @squares = {}
    reset
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts ""
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def someone_won?
    !!winning_marker
  end

  def tie?
    unmarked_keys.empty?
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3

    markers.min == markers.max
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def to_s
    @marker
  end
end

class Player
  include Displayable
  include Formatable
  attr_accessor :name, :marker, :score

  def initialize
    @score = 0
  end

  def increase_score
    self.score += 1
  end

  def reset_score
    self.score = 0
  end
end

class Human < Player
  def choose_name
    prompt "What's your name?: "
    input = nil
    loop do
      input = gets.chomp
      break unless input.empty?

      prompt 'Please type your name: '
    end
    self.name = input
  end

  def choose_marker
    prompt 'Choose a marker from A-Z: '
    input = nil
    loop do
      input = gets.chomp
      break if ('A'..'Z').include?(input)

      prompt 'Sorry, invalid input.'
    end
    self.marker = input
  end

  def choose_move(board)
    prompt "Choose a square (#{board.joiner(board.unmarked_keys)}):"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)

      puts "Sorry that's not a valid choice."
    end
    board[square] = marker
  end
end

class Computer < Player
  attr_accessor :difficulty

  def initialize
    super
    @name = ['Astro Boy', 'Wall-E', 'Rubocop', 'Bender'].sample
    @difficulty = 'e'
  end

  def assign_marker(human_marker)
    self.marker = if name[0] == human_marker
                    (('A'..'Z').to_a - [human_marker]).sample
                  else
                    name[0]
                  end
  end

  def set_difficulty
    prompt "Choose a difficulty: easy, medium, hard (e/m/h): "
    input = nil
    loop do
      input = gets.chomp
      break if ['e', 'm', 'h'].include?(input)

      prompt 'Sorry, invalid input.'
    end
    self.difficulty = input
  end

  def easy_move(board)
    square = board.unmarked_keys.sample
    board[square] = marker
  end

  def medium_move(board, human_marker)
    if find_defensive_move(board, human_marker)
      board[find_defensive_move(board, human_marker)] = marker
    else
      board[board.unmarked_keys.sample] = marker
    end
  end

  def hard_move(board, comp_marker, human_marker)
    if find_offensive_move(board, comp_marker)
      board[find_offensive_move(board, comp_marker)] = marker
    elsif find_defensive_move(board, human_marker)
      board[find_defensive_move(board, human_marker)] = marker
    else
      board[board.unmarked_keys.sample] = marker
    end
  end

  def find_defensive_move(board, human_marker)
    lines_marked_twice = find_lines_marked_twice(board, human_marker)
    return nil unless lines_marked_twice
    lines_marked_twice.flatten.select do |square_key|
      board.squares[square_key].marker == Square::INITIAL_MARKER
    end.first
  end

  def find_offensive_move(board, comp_marker)
    lines_marked_twice = find_lines_marked_twice(board, comp_marker)
    return nil unless lines_marked_twice
    lines_marked_twice.flatten.select do |square_key|
      board.squares[square_key].marker == Square::INITIAL_MARKER
    end.first
  end

  def find_lines_marked_twice(board, player_marker)
    lines_marked_twice = Board::WINNING_LINES.select do |line|
      current_squares = board.squares.values_at(*line)
      current_squares.map(&:marker).count(player_marker) == 2
    end
    lines_marked_twice.empty? ? nil : lines_marked_twice
  end
end

class TTTGame
  include Displayable
  include Formatable
  WINNING_ROUNDS = 3
  attr_reader :board, :human, :computer
  attr_accessor :current_marker, :grand_winner

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
  end

  def play
    clear
    display_welcome_message
    set_up_game
    main_game
    clear
    display_goodbye_message
  end

  # rubocop:disable Metrics/MethodLength
  def main_game
    loop do
      loop do
        play_round
        if detect_grand_winner
          display_grand_winner
          break
        end
        play_next_round? ? reset_round : break
      end
      play_again? ? reset_game : break
    end
  end
  # rubocop:enable Metrics/MethodLength

  def set_up_game
    gather_human_preferences
    computer.assign_marker(human.marker)
    clear
  end

  def gather_human_preferences
    human.choose_name
    human.choose_marker
    computer.set_difficulty
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def play_round
    setup_round
    players_move
    update_score
    clear
    display_round_results
  end

  def setup_round
    choose_first_player
    clear_screen_and_display_board
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def choose_first_player
    prompt 'Would you like to go 1st or 2nd? (1 or 2): '
    input = nil
    loop do
      input = gets.chomp
      break if ['1', '2'].include?(input)

      prompt "Sorry, invalid input."
    end
    case input
    when '1' then self.current_marker = human.marker
    when '2' then self.current_marker = computer.marker
    end
  end

  def current_player_moves
    if current_marker == human.marker
      human.choose_move(board)
      self.current_marker = computer.marker
    else
      case computer.difficulty
      when 'e' then computer.easy_move(board)
      when 'm' then computer.medium_move(board, human.marker)
      else computer.hard_move(board, computer.marker, human.marker)
      end
      self.current_marker = human.marker
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def players_move
    loop do
      current_player_moves
      break if board.someone_won? || board.tie?

      clear_screen_and_display_board if human_turn?
    end
  end

  def human_turn?
    current_marker == human.marker
  end

  def update_score
    if board.winning_marker == human.marker
      human.increase_score
    elsif board.winning_marker == computer.marker
      computer.increase_score
    end
  end

  def detect_grand_winner
    if human.score == WINNING_ROUNDS
      self.grand_winner = human.name
    elsif computer.score == WINNING_ROUNDS
      self.grand_winner = computer.name
    end
  end

  def play_next_round?
    prompt "Would you like to play the next round? (y/n): "
    input = nil
    loop do
      input = gets.chomp
      break if ['y', 'n'].include?(input)

      prompt "Sorry, invalid input."
    end
    input == 'y'
  end

  def reset_round
    board.reset
    clear
  end

  def play_again?
    prompt "Would you like to play again? (y/n): "
    input = nil
    loop do
      input = gets.chomp
      break if ['y', 'n'].include?(input)

      prompt "Sorry, invalid input."
    end
    input == 'y'
  end

  def reset_game
    board.reset
    human.score = 0
    computer.score = 0
    clear
    display_play_again_message
  end
end

game = TTTGame.new
game.play

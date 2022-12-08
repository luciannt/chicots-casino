class GameChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from "game_channel"
  end

  def unsubscribed
    puts "Unsubscribed"
    ActionCable.server.broadcast "game_channel", { type: "unsubscribe" }.to_json
    stop_all_streams
  end

  def received(data)
    ActionCable.server.broadcast("game_channel", data)
  end

  def game_check(opts)
    ActionCable.server.broadcast("game_channel", { type: "CHECKING GAME", payload: opts })

    if (opts["user_id"])
      user = User.find(opts["user_id"])
    else
      ActionCable.server.broadcast("game_channel", { type: "FAILURE", message: "No user id supplied, please log in" })
    end

    if opts["code"]
      ActionCable.server.broadcast("game_channel", { type: "CHECK_GAME_VIABILITY", payload: Game.can_start_game(opts["code"]) })
    end

    if user && opts["code"]
      game = Game.find_by_game_code(opts["code"])
      gamePlayers = Player.where(game: game)

      playerArr = []
      gamePlayers.each do |player|
        user = User.find(player[:user_id])
        playerArr.append({ **player, username: user[:username] })
      end

      ActionCable.server.broadcast("game_channel", { type: "CURRENT_PLAYERS", payload: playerArr })

      if !(gamePlayers.exists? user[:id])
        Game.join_game(opts["user_id"], opts["code"])
      end
    end
  end

  def start_game(code)
    gamePlayers = Player.where(game: game)
    table = Game.start_game(code, gamePlayers[0], gamePlayers[1])
    ActionCable.server.broadcast("game_channel", { type: "STARTED", payload: table })
  end

  def new_game(opts)
    game = Game.new_game(SecureRandom.urlsafe_base64, opts["user_id"])
    ActionCable.server.broadcast("game_channel", { type: "GAME_CREATED", payload: game[:game_code] })
  end

  private

  def find_user_id
    user = User.find(params[:id])
  end
end

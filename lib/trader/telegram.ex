defmodule Trader.Telegram do

  def send_message(chat_id, text) when is_binary(text) do
    Nadia.send_message(chat_id, text)
  end

  def delete_message(chat_id, id) do
    Nadia.delete_message(chat_id, id)
  end

end
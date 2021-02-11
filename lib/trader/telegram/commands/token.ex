defmodule Trader.Telegram.Commands.Token do
  alias Trader.Telegram
  alias Trader.Contexts.User
  require Logger

  @command "/token"

  @msg """
  Напишите мне токен, который Вы сгенерировали на сайте Тинькофф.Инвестиции, в формате:

  #{@command} MY_TOKEN_HERE

  Можно использовать реальный токен или токен песочницы - с токеном песочницы ваши реальные средства не будут расходоваться
  """

  @token_success_msg """
  Отлично, все работает. Если у Вас не было создано счета для этого токена - он будет создан автоматически или будет выбран первый из списка счетов.
  
  Теперь можно выбрать акции, за которыми бот будет следить

  Используется счет:
  """

  @token_error_msg """
  Токен не валидный, попробуйте позже или попробуйте другой токен.
  """

  def command do
    @command
  end

  def checks, do: [:register]

  def arguments, do: [:token]

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{trader_args: [token: nil], message: %{chat: %{id: chat_id}}}) do
    Telegram.send_message(chat_id, @msg)
  end

  def process(%{trader_args: [token: token], message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    user_id
    |> User.by_telegram()
    |> write_credentials(token, chat_id)
  end

  defp write_credentials(user, token, chat_id) do
    case User.write_credentials(user, token) do
      {:ok, user} -> success(user, chat_id)
      {:error, reason} -> Telegram.send_message(chat_id, "Не удалось создать счет, код ошибки: #{reason}")
    end
  end

  defp success(%{broker_account_id: broker_account_id}, chat_id) do
    Telegram.send_message(chat_id, @token_success_msg <> "\n" <> "#{broker_account_id}")
  end
end

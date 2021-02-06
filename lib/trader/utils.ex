defmodule Trader.Utils do
  def fun_capture({mod, fun, arity}) do
    Function.capture(mod, fun, arity)
  end
end

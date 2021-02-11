# Trader

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `trader` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:trader, "~> 0.1.0"}
  ]
end
```

- [ ] Add cron for checking prices regularly for tracked stocks
- [ ] Add cron for checking algo decision for tracked stocks
- [ ] Add sell
- [ ] Add create limit order to use stop loss
- [ ] Add create limit order to use take profit just in case
- [ ] Add more algos
- [ ] Add last price on order history
- [ ] When buying, use limit order. And if limit order has not succeeded - cancel it.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/trader](https://hexdocs.pm/trader).


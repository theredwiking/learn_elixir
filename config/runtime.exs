import Config
config :kv, :routing_table, [{?a..?z, node()}]

if config_env() == :prod do
  config :kv, :routing_table, [
    {?a..?m, :"foo@middleearth"},
    {?n..?z, :"bar@middleearth"}
  ]
end

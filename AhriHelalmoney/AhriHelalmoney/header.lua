return {
  id = "HelalmoneyAhri",
  name = "Ahri by Helalmoney",
  author = "Helalmoney",
  hprotect = true,
  description = [[
  ]],
  shard_url = "https://raw.githubusercontent.com/Helalmoney/HanBot/master/Ahri%20by%20Helalmoney.shard",
  riot = true,
  shard = {
    "common",
    "main"
  },
  flag = {
    text = "Ahri by Helalmoney",
    color = {
      text = 0xFFFFFFFF,
      background1 = 0xA6A1C3D1,
      background2 = 0xA68F0C47
    }
  },
  load = function()
    return player.charName == "Ahri"
  end
}

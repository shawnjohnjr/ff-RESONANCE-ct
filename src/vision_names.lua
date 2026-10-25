-- Display names extracted from the supported game build.
local VISION_NAMES={
 [13017]={en="Amelia",zh="艾美利亞"},
 [13024]={en="Tronn",zh="托倫"},
 [13027]={en="Victoria",zh="薇多莉亞"},
 [13033]={en="Camille",zh="卡米爾"},
 [13045]={en="Leah",zh="莉亞"},
 [13051]={en="Ayaka",zh="彩花"},
 [13060]={en="Charlotte",zh="夏洛特"},
 [13062]={en="Wilhelm",zh="維魯赫魯姆"},
 [13080]={en="Aileen",zh="艾琳"},
 [13100]={en="Warrior of Light",zh="光之戰士"},
 [13101]={en="Firion",zh="弗利奧尼爾"},
 [13102]={en="Onion Knight",zh="洋蔥劍士"},
 [13103]={en="Cecil",zh="塞西爾"},
 [13105]={en="Bartz",zh="巴茲"},
 [13108]={en="Terra",zh="蒂娜"},
 [13110]={en="Cloud",zh="克勞德"},
 [13113]={en="Sephiroth",zh="賽菲羅斯"},
 [13116]={en="Squall",zh="史克爾"},
 [13118]={en="Zidane",zh="吉坦"},
 [13120]={en="Tidus",zh="提達"},
 [13123]={en="Shantotto",zh="香托托"},
 [13124]={en="Vaan",zh="梵恩"},
 [13125]={en="Lightning",zh="雷光"},
 [13127]={en="Y’shtola",zh="雅·修特拉"},
 [13128]={en="Noctis",zh="諾克提斯"},
 [13130]={en="Clive",zh="克萊夫"},
}
local function visionName(id)
 local n=VISION_NAMES[id];return n and (n.en.." / "..n.zh) or ("Vision ID "..id)
end

local L = LibStub("AceLocale-3.0"):NewLocale("EavesDrop", "zhCN", false)

if L then
    --main
    L["DownTip"] = "点击以向下滚屏，Shift+左键点击直接滚屏到最底端\nCtrl+左键点击直接滚屏到本次战斗结束"
    L["UpTip"] = "点击以向上滚屏，Shift+左键点击直接滚屏到最顶端\nCtrl+左键点击直接滚屏到本次战斗开始"
    L["TabTip"] = "左键点击以拖曳框体。\n右键点击以显示快速设置菜单\nShift+右键点击以显示详细设置菜单"
    L["StartCombat"] = "++进入战斗++"
    L["EndCombat"] = "--离开战斗--"
    L["PlayerLabel"] = "进货"
    L["TargetLabel"] = "传出"
    L["Normal"] = "正常"
    L["Crit"] = "爆击"
    L["Skill"] = "技能"
    L["Reset"] = "重置"
    L["Fades"] = "消失"
    L["Gained"] = "获得"
    L["OutgoingDamage"] = "伤害输出"
    L["OutgoingHeals"] = "治疗输出"
    L["IncomingDamge"] = "伤害承受"
    L["IncomingHeals"] = "治疗承受"
    L["History"] = "显示EavesDrop历史记录"
    L["IncombatSummary"] = "秒战斗"
    L["NewLevel"] = "恭喜! 新关卡 %d"
    L["Vigor"] = "活力"
    L["Essence"] = "本质"

    --events
    L["Events"] = "事件显示开启/关闭"
    L["ECombat"] = "战斗"
    L["ECombatD"] = "显示战斗事件"
    L["EPower"] = "法力获得"
    L["EPowerD"] = "显示你法力值/能量值/怒气值/快乐值的获得"
    L["EBuffs"] = "增益效果"
    L["EBuffsD"] = "显示你获得的增益效果"
    L["EDebuffs"] = "减益效果"
    L["EDebuffsD"] = "显示你获得的减益效果"
    L["EBuffFades"] = "增益消失"
    L["EBuffFadesD"] = "显示你增益效果的消失"
    L["EDebuffFades"] = "减益消失"
    L["EDebuffFadesD"] = "显示你减益效果的消失"
    L["EExperience"] = "经验值"
    L["EExperienceD"] = "显示你经验值的获得"
    L["EHonor"] = "荣誉值"
    L["EHonorD"] = "显示你荣誉值的获得"
    L["EReputation"] = "声望值"
    L["EReputationD"] = "显示你声望值的获得/损失"
    L["ESkill"] = "技能值"
    L["ESkillD"] = "显示你技能值的获得"
    L["EPet"] = "宠物"
    L["EPetD"] = "显示宠物事件"
    L["ESpellcolor"] = "伤害类型代表色"
    L["ESpellcolorD"] = "为不同类型的法术伤害显示不同的字色"
    L["EOverhealing"] = "过量治疗"
    L["EOverhealingD"] = "显示你的过量治疗"
    L["EHealers"] = "治疗者姓名"
    L["EHealersD"] = "显示谁治疗了你与你治疗了谁"
    L["EHealAbsorbs"] = "治疗吸收"
    L["EHealAbsorbsD"] = "显示治疗吸收并相应调整净治疗和过度治疗。"
    L["ESummary"] = "战斗摘要"
    L["ESummaryD"] = "显示每场战斗遭遇的伤害与治疗摘要"

    --colors
    L["Colors"] = "颜色"
    L["IColors"] = "承受类事件颜色"
    L["IColorsD"] = "设定承受类事件的文字颜色"
    L["ICHits"] = "击中"
    L["ICHitsD"] = "设定被近战命中的文字颜色"
    L["ICMiss"] = "未命中"
    L["ICMissD"] = "设定近战未命中的文字颜色（格挡，躲闪等……）"
    L["ICHeals"] = "治疗"
    L["ICHealsD"] = "设定治疗的颜色"
    L["ICSpells"] = "法术"
    L["ICSpellsD"] = "设定法术/技能的颜色"
    L["ICGainsD"] = "设定法力获取的颜色"
    L["ICBuffsD"] = "设定增益获取的颜色"
    L["ICDebuffsD"] = "设定减益获取的颜色"
    L["ICPetD"] = "设定宠物事件的颜色"
    L["OColors"] = "输出类时间颜色"
    L["OColorsD"] = "设定输出类事件的文字颜色"
    L["OCHitsD"] = "设定你的近战命中的颜色"
    L["OCSpellsD"] = "设定你的法术/技能的颜色"
    L["OSColors"] = "法术颜色"
    L["OSColorsD"] = "设定各系法术的颜色"
    L["OCHealsD"] = "设定你的治疗法术的颜色"
    L["OCPetD"] = "设定你宠物伤害的颜色"
    L["MColors"] = "其它颜色"
    L["MColorsD"] = "设定其它事件的颜色"
    L["MCDeath"] = "死亡"
    L["MCDeathD"] = "设定死亡的颜色"
    L["MCMisc"] = "其它"
    L["MCMiscD"] = "设定其它事件的颜色"
    L["MCExperienceD"] = "设定经验值获得的颜色"
    L["MCReputationD"] = "设定声望值获得的颜色"
    L["MCHonorD"] = "设定荣誉值获得的颜色"
    L["MCSkillD"] = "设定技能值获得的颜色"
    L["MCFrame"] = "框体颜色"
    L["MCFrameD"] = "设定框体背景的颜色与透明度"
    L["MCBorder"] = "边框颜色"
    L["MCBorderD"] = "设定框体边框的颜色与透明度"
    L["MCLabel"] = "标签颜色"
    L["MCLabelD"] = "设定框体标签的颜色与透明度"

    --frame
    L["Frame"] = "框体"
    L["FNumber"] = "行数"
    L["FNumberD"] = "总共显示多少事件"
    L["FHeight"] = "行高"
    L["FHeightD"] = "每行事件的高度"
    L["FWidth"] = "行宽"
    L["FWidthD"] = "每行事件的宽度"
    L["FText"] = "字号"
    L["FTextD"] = "事件文字的字号"
    L["FFont"] = "字体"
    L["FFontOutline"] = "字体轮廓"
    L["FFontOutlineD"] = "设置字体轮廓装饰"
    L["FFade"] = "消退时间"
    L["FFadeD"] = "时间发生后多长时间消失"
    L["FFadeFrame"] = "框体消退"
    L["FFadeFrameD"] = "在没有任何事件或动作发生时自动隐藏框体，在事件或动作发生时，或你的鼠标悬浮其上并滚动滚轮时候自动浮现"

    --misc
    L["Misc"] = "其它"
    L["MButtons"] = "隐藏滚动条按钮"
    L["MButtonsD"] = "隐藏滚动条按钮"
    L["MTooltip"] = "显示详细的信息提示框"
    L["MTooltipD"] = "在信息提示框内显示为事件显示详细的信息"
    L["MTooltipAnchor"] = "信息提示框锚点"
    L["MTooltipAnchorD"] = "设定信息提示框的锚点"
    L["MTimestamp"] = "在信息提示框内显示时间"
    L["MTimestampD"] = "在信息提示框内的信息前显示时间"
    L["MFlip"] = "反置事件列"
    L["MFlipD"] = "将承受事件列在框内的右侧，而输出事件列在左侧"
    L["MPlace"] = "显示占位图标"
    L["MPlaceD"] = "在技能或法术的图标未知的时候显示一个占位图标"
    L["MHFilter"] = "治疗过滤"
    L["MHFilterD"] = "设置一个最小值，不显示数额在该值以下的治疗，以避免类似图腾或祝福的效果在EavesDrop中显示得过为频繁"
    L["MDFilter"] = "损坏过滤器"
    L["MDFilterD"] = "控制需要在EAVESDROP中显示的最小伤害量, 适合过滤掉频繁出现的小伤害，如奉献等。"
    L["BWONSAMDI"] = "邦桑迪见到你了！"
    L["BWONSAMDID"] = "在你死后播放邦桑迪的声音"
    L["MBlacklist"] = "黑名单: 要隐藏任何法术，请输入其名称或法术编号（每行一个）"
    L["MBlacklistD"] = "示例：以下任何一行都会将“|cd0ff7d0a判断|r”列入黑名单:\n判断\n275773\n275773 -- 判断"
    L["MMFilter"] = "法力获得过滤"
    L["MMFilterD"] = "设置一个最小值，不显示数额在该值以下的法力获得，以避免类似图腾或祝福的效果在EavesDrop中显示得过为频繁"
    L["MLock"] = "锁定框体"
    L["MLockD"] = "锁定框体"
    L["MHistory"] = "保存历史记录"
    L["MHistoryD"] = "保存全部最大伤害与治疗的输出及承受记录。"
    L["MHideTab"] = "隐藏标签页"
    L["MHideTabD"] = "隐藏EavesDrop的所有标签页。\nAlt+左键点击显示快速设置菜单\nAlt+左键点击显示详细设置菜单\nAlt+中键点击显示历史记录框体"

    --misc buff
    L["MBuffTrunc"] = "增/减益名缩写"
    L["MBuffTruncD"] = "设定增/减益名的名称缩写"
    L["MBuffTruncType"] = "缩写方式"
    L["MBuffTruncTypeD"] = "指定缩写的方式：不缩写，去尾，首字母"
    L["MBuffTruncSize"] = "缩写长度"
    L["MBuffTruncSizeD"] = "长于此设定长度的增/减益效果的名称将按指定缩写方式被缩写"
    L["MBuffTruncNone"] = "无"
    L["MBuffTruncTrunc"] = "去尾"
    L["MBuffTruncShorten"] = "首字母"

    -- Other
    L["YOUDIED"] = "你死了！"
end

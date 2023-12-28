local component = require("component")
local robot = require("robot")
local os = require('os')

local geolyzer = component.geolyzer
local debug = component.debug
local navigation = component.navigation

-- B站视频：https://www.bilibili.com/video/BV1WC4y1B71t
-- lua压缩：https://codebeautify.org/lua-minifier#
-- oc文档：https://ocdoc.cil.li/
-- 用到的lua操作
-- edit main.lua 新建
-- ctrl + s 保存
-- ctrl + w 退出lua编辑
-- 鼠标中间复制到lua文件中

-- _m.lua是压缩过的

-- 1. 电的问题，机器人要有太阳能升级，白天稍微补充点电，一到晚上就睡觉的话电量可能还好。
--    但要是长时间挂机那种，可以插一个发电机升级，烧煤炭补电，视频里会提到👆
--    再不行旁边放个oc的充电器，写个逻辑判断没电自动去充电，这个就留给感兴趣的人吧
-- 2. 稿子的问题，钻石镐打个耐久附魔一般够用了，也可以上匠魂的不毁稿子
-- 3. 感兴趣的也可以写一些代码检测然后从箱子拾取新的稿子，思路可行也有api，看oc文档👆即可
-- 4. 这个机器人需要调试卡，合成不了的东西，主要为了获取机器人坐标，以实现绝对定位的位移
-- 5. 同时机器人需要导航升级，中间的地图需要右键生成一下然后合成导航升级，主要为了获取机器人的朝向
-- 6. 此装置需要按照视频方式👆的样子摆放，朝向无所谓
-- 7. 这个文件过长，需要压缩后再复制到机器人中，代码压缩地址上面有👆
-- 8. 机器人有时会发现gui点不开，名字也在闪，oc老问题了，会正常干活，退存档重进就好了
-- 9. 输入材料最好都是一组一组的，有些边缘场景没测试到，可能会有问题

-- 输出材料标签，有其他的往里添加即可
-- 下面是MBM疯狂多方块中需要的三种材料name
local outputTable = {"thaumcraft:stone_arcane", "botania:livingrock", "botania:livingwood"}

local function includes(value)
    local found = false
    for _, v in ipairs(outputTable) do
        if v == value then
            found = true
            break
        end
    end
    return found
end

-- 输入材料格子，默认1，可选1-16
local inputSlot = 1
-- 输出材料格子，默认2，可选1-16
local outputSlot = 2
-- 每次取/放方块的最大数量，默认32
local maxOutput = 32
-- 组间间隔，默认30秒，一般白雏菊就是30或者60秒，看整合包魔改的内容，是否修改了合成时间
-- 这个操作是为了省电，分析方块一次100电量，机器人带太阳能的顶不住
local sleepSeconds = 30

-- north == 2
-- south == 3
-- west == 4
-- east == 5
-- 获取机器人初始朝向
local initFacing = navigation.getFacing()

-- 获取机器人初始坐标
-- 机器人不是完整方块，xyz都需要减0.5
local initX = tonumber(debug.getX() - 0.5)
local initY = tonumber(debug.getY() - 0.5)
local initZ = tonumber(debug.getZ() - 0.5)

-- flag
local _active = false

-- 获取输入材料位置
-- 根据机器人朝向实现的坐标计算，需要装置按照样板排放
function gip()
    if initFacing == 2 then
        return initX, initY, initZ + 1
    end
    if initFacing == 3 then
        return initX, initY, initZ - 1
    end
    if initFacing == 4 then
        return initX + 1, initY, initZ
    end
    if initFacing == 5 then
        return initX - 1, initY, initZ
    end
end

-- 获取输出材料位置
-- 根据机器人朝向实现的坐标计算，需要装置按照样板排放
function gop()
    if initFacing == 2 then
        return initX + 2, initY, initZ + 1
    end
    if initFacing == 3 then
        return initX - 2, initY, initZ - 1
    end
    if initFacing == 4 then
        return initX + 1, initY, initZ - 2
    end
    if initFacing == 5 then
        return initX - 1, initY, initZ + 2
    end
end

local inputPos = {gip()}
local outputPos = {gop()}

-- north == 2
-- south == 3
-- west == 4
-- east == 5
-- 移动到坐标
local function move(x, y, z)
    local curX = tonumber(debug.getX() - 0.5)
    local curY = tonumber(debug.getY() - 0.5)
    local curZ = tonumber(debug.getZ() - 0.5)

    local curFacing = navigation.getFacing()

    if curX == x and curY == y and curZ == z then
        if initFacing ~= curFacing then
            if initFacing == 2 then
                -- south
                if curFacing == 3 then
                    robot.turnAround()
                end
                -- west
                if curFacing == 4 then
                    robot.turnRight()
                end
                -- east
                if curFacing == 5 then
                    robot.turnLeft()
                end
            end

            if initFacing == 3 then
                -- north
                if curFacing == 2 then
                    robot.turnAround()
                end
                -- west
                if curFacing == 4 then
                    robot.turnRight()
                end
                -- east
                if curFacing == 5 then
                    robot.turnLeft()
                end
            end

            if initFacing == 4 then
                -- north
                if curFacing == 2 then
                    robot.turnLeft()
                end
                -- south
                if curFacing == 3 then
                    robot.turnRight()
                end
                -- east
                if curFacing == 5 then
                    robot.turnAround()
                end
            end

            if initFacing == 5 then
                -- north
                if curFacing == 2 then
                    robot.turnRight()
                end
                -- south
                if curFacing == 3 then
                    robot.turnLeft()
                end
                -- west
                if curFacing == 4 then
                    robot.turnAround()
                end
            end
        end
        return
    end

    if curX > x then
        -- north
        if curFacing == 2 then
            robot.turnLeft()
        end
        -- south
        if curFacing == 3 then
            robot.turnRight()
        end
        -- east
        if curFacing == 5 then
            robot.turnAround()
        end

        robot.forward()
    elseif curX < x then
        -- north
        if curFacing == 2 then
            robot.turnRight()
        end
        -- south
        if curFacing == 3 then
            robot.turnLeft()
        end
        -- west
        if curFacing == 4 then
            robot.turnAround()
        end

        robot.forward()
    elseif curY > y then
        robot.down()
    elseif curY < y then
        robot.up()
    elseif curZ > z then
        -- south
        if curFacing == 3 then
            robot.turnAround()
        end
        -- west
        if curFacing == 4 then
            robot.turnRight()
        end
        -- east
        if curFacing == 5 then
            robot.turnLeft()
        end

        robot.forward()
    elseif curZ < z then
        -- north
        if curFacing == 2 then
            robot.turnAround()
        end
        -- west
        if curFacing == 4 then
            robot.turnLeft()
        end
        -- east
        if curFacing == 5 then
            robot.turnRight()
        end

        robot.forward()
    end

    return move(x, y, z)
end

-- 移动到初始位置
local function moveToInitPosition()
    return move(initX, initY, initZ)
end

-- 移动到输入位置
local function moveToInputPosition()
    return move(inputPos[1], inputPos[2], inputPos[3])
end

-- 移动到输出位置
local function moveToOuputPosition()
    return move(outputPos[1], outputPos[2], outputPos[3])
end

-- 检测挖掘放下操作
local function doAction()
    -- 分析底部方块
    local downBlock = geolyzer.analyze(0)

    if includes(downBlock["name"]) then
        print("分析-成品")
        -- 检测到成品
        -- 切换到输出槽位
        robot.select(outputSlot)
        -- 挖掉成品
        robot.swingDown()
        -- 切换到输出槽位
        robot.select(inputSlot)
        -- 放下输入材料
        robot.placeDown()
    elseif downBlock["name"] == "minecraft:air" then
        print("分析-空")
        -- 底部没有方块
        -- 切换到输入槽位
        robot.select(inputSlot)
        -- 放下输入材料
        robot.placeDown()
    elseif not includes(downBlock["name"]) then
        print("分析-非成品")
        -- 底部还没成型，休眠一定秒数，主要是为了省电
        os.sleep(sleepSeconds)
        doAction()
    end
end

local function inputEmpty()
    return robot.count(inputSlot) == 0
end

local function outputFull()
    return robot.count(outputSlot) >= maxOutput
end

local function outputEmpty()
    return robot.count(outputSlot) == 0
end

-- 主函数
local function main()
    while true do
        if _active == false then
            print('准备中')

            -- 输出满了，放材料
            if outputFull() then
                -- 移动到输出位置
                moveToOuputPosition()
                -- 切到输出位
                robot.select(outputSlot)
                -- 放一组材料
                robot.dropDown(maxOutput)
                -- 输入为0，取材料
                print('准备-放材料完毕')
            elseif inputEmpty() then
                -- 移动到输入位置
                moveToInputPosition()
                -- 切到输入位
                robot.select(inputSlot)
                -- 取一组材料
                robot.suckDown(maxOutput)
                print('准备-取材料完毕')
            elseif robot.count(inputSlot) ~= 0 then
                print('准备-移动到初始点位')

                -- 移动到初始位置
                moveToInitPosition()

                _active = true
            end

        else
            print('运行中')

            -- 输出满了或者没有输入了
            if outputFull() or (inputEmpty() and outputEmpty()) then
                print('运行-到临界点，需要进入准备中')
                _active = false
            else
                print('运行-前进一个边')
                doAction()
                robot.forward()

                doAction()
                robot.forward()

                robot.turnRight()
            end
        end
    end
end

main()

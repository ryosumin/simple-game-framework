##################################################################################
#                            This file is part of                                #
#                                GodotExplorer                                   #
#                       https://github.com/GodotExplorer                         #
##################################################################################
# Copyright (c) 2019 Godot Explorer                                              #
#                                                                                #
# Permission is hereby granted, free of charge, to any person obtaining a copy   #
# of this software and associated documentation files (the "Software"), to deal  #
# in the Software without restriction, including without limitation the rights   #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      #
# copies of the Software, and to permit persons to whom the Software is          #
# furnished to do so, subject to the following conditions:                       #
#                                                                                #
# The above copyright notice and this permission notice shall be included in all #
# copies or substantial portions of the Software.                                #
#                                                                                #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  #
# SOFTWARE.                                                                      #
##################################################################################

# @class `BuffModule`
# BuffModule 类， Buff的调度器
# Buff 模块，用于管理调度游戏中的 Buff 对象
# 添加到此调度器的 Buff 会在被启动（如果未启动过的话），已经停止的 Buff 会在下一帧开始时被移除
# 移除Buff时会强制触发停止（如果该buff正在运行）

tool
extends Module
class_name BuffModule

# Map<Buff, bool>
var buffs = {}

# 添加 Buff
func add_buff(buff: Buff):
	if not buffs.has(buff):
		if not buff.is_running():
			buff.start()
		buff.connect("stopped", self, "remove_buff", [buff])
		buffs[buff] = true

# 删除 Buff
func remove_buff(buff: Buff):
	buff.disconnect("stopped", self, "remove_buff")
	if buffs.has(buff):
		if buffs[buff]:
			buffs[buff] = false
			if buff.is_running():
				buff.stop()

# 移除失效的 buff
func process(dt):
	var removal_buffs = []
	for b in buffs:
		if not buffs[b]:
			removal_buffs.append(b)
	for b in removal_buffs:
		buffs.erase(b)

# 逻辑迭代
func update(dt):
	for b in buffs:
		b.update(dt)

# 通过类型查找 buff , 返回所有该类型的 Buff
func get_buff(type: GDScript) -> Array:
	var ret = []
	for b in buffs:
		if b is type:
			ret.append(b)
	return ret

# 存档
func save() -> Dictionary:
	# Map<GDScript, ID>
	var classes = {}
	# Map<ID, Dictionary>
	var classes_serialized = {}
	# 存档数据
	var buff_list = []
	var idx = 0
	for b in buffs:
		if not buffs[b]:
			# 忽略已经失效的 buff
			continue
		var type = b.get_type()
		if not classes.has(type):
			var dict = inst2dict(b)
			classes[type] = idx
			classes_serialized[idx] = {
				"path": dict["@path"],
				"subpath": dict["@subpath"],
			}
			idx += 1
		var buff_data = {
			"type": classes[type],
			"data": b.save()
		}
		buff_list.append(buff_data)
	return {
		"types": classes_serialized,
		"buffs": buff_list
	}

# 读档
func load(data):
	var classes = {}
	for id in data.types:
		var base = load(data.types[id].path)
		var script = base
		if not data.types[id].subpath.empty():
			script = base.get(data.types[id].subpath)
		classes[id] = script
	for conf in data.buffs:
		var buff = classes[str(conf.type)].new()
		buff.load(conf.data)
		buff._started = true
		add_buff(buff)

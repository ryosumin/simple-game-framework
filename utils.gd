@tool
# 常用工具模块


# Check does an object has all of script methods of target class
# - - - - - - - - - -
# *Parameters*
# * [obj:Object] The object to check
# * [interface:GDScript] The interface to check with
# - - - - - - - - - -
# *Returns* bool
static func implements(obj: Object, _interface:GDScript) -> bool:
	if obj == null or _interface == null:
		return false
	if typeof(obj) != TYPE_OBJECT:
		return false
	if is_instance_of(obj, _interface):
		return true
	var interface_obj = _interface.new()
	var required_methods = []
	for m in interface_obj.get_method_list():
		# if m.flags & METHOD_FLAG_FROM_SCRIPT:
			# required_methods.append(m.name)
		required_methods.append(m.name)
	if not interface_obj is RefCounted:
		interface_obj.free()
	for mid in required_methods:
		if not obj.has_method(mid):
			return false
	return true

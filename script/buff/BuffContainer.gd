class_name BuffContainer

var buffs: Array[IBuff] = []


func add_buff(buff: IBuff) -> void:
	buffs.append(buff)
	pass

func remove_buff(buff: IBuff) -> bool:
	var index := buffs.find(buff)
	if index == -1:
		return false
	buffs.remove_at(index)
	return true

func get_buffs_by_type(buff_type: int) -> Array[IBuff]:
	var result: Array[IBuff] = []
	for buff in buffs:
		if buff_type == buff.type():
			result.append(buff)
	return result

func buff_type_of_size(buff_type: int) -> int:
	var count := 0
	for buff in buffs:
		if buff_type == buff.type():
			count = count + 1
	return count
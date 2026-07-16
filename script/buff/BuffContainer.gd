class_name BuffContainer

var buffs: Array[IBuff] = []


func add_buff(buff: IBuff) -> void:
	buffs.append(buff)
	pass

func get_buffs_by_type(buff_type: int) -> Array[IBuff]:
	var result: Array[IBuff] = []
	for buff in buffs:
		if buff_type == buff.type():
			result.append(buff)
	return result
static func buff_container_add_test() -> void:
	var container := BuffContainer.new()
	assert(container.buffs.is_empty())

	var buff := BulletSizeBuff.new()
	container.add_buff(buff)
	assert(container.buffs.size() == 1)
	assert(container.buffs[0] == buff)
	assert(container.buff_type_of_size(IBuff.BuffType.BULLET_SIZE) == 1)

	var same_type := BulletSizeBuff.new()
	container.add_buff(same_type)
	assert(container.buffs.size() == 2)
	assert(container.buff_type_of_size(IBuff.BuffType.BULLET_SIZE) == 2)

	var speed_buff := BulletSpeedBuff.new()
	container.add_buff(speed_buff)
	assert(container.buff_type_of_size(IBuff.BuffType.BULLET_SPEED) == 1)
	assert(container.buff_type_of_size(IBuff.BuffType.BULLET_SIZE) == 2)

	var size_buffs := container.get_buffs_by_type(IBuff.BuffType.BULLET_SIZE)
	assert(size_buffs.size() == 2)
	assert(size_buffs[0] == buff)
	assert(size_buffs[1] == same_type)


static func buff_container_remove_test() -> void:
	var container := BuffContainer.new()
	var buff1 := BulletSizeBuff.new()
	var buff2 := BulletSizeBuff.new()
	container.add_buff(buff1)
	container.add_buff(buff2)

	assert(container.remove_buff(buff1))
	assert(container.buffs.size() == 1)
	assert(container.buffs[0] == buff2)
	assert(container.buff_type_of_size(IBuff.BuffType.BULLET_SIZE) == 1)

	var size_buffs := container.get_buffs_by_type(IBuff.BuffType.BULLET_SIZE)
	assert(size_buffs.size() == 1)
	assert(size_buffs[0] == buff2)

	assert(container.remove_buff(buff2))
	assert(container.buffs.is_empty())
	assert(container.buff_type_of_size(IBuff.BuffType.BULLET_SIZE) == 0)

	assert(!container.remove_buff(buff2))


static func remove_current_level_buffs_test() -> void:
	BuffManager.buff_map.clear()
	BuffManager.current_level_buff_map.clear()

	var container := BuffContainer.new()
	var previous_level_buff := BulletSizeBuff.new()
	var current_level_buff := BulletSizeBuff.new()
	container.add_buff(previous_level_buff)
	container.add_buff(current_level_buff)
	BuffManager.buff_map[0] = container
	var current_level_container := BuffContainer.new()
	current_level_container.add_buff(current_level_buff)
	BuffManager.current_level_buff_map[0] = current_level_container

	BuffManager.remove_current_level_buffs()

	assert(container.buffs == [previous_level_buff])
	assert(BuffManager.current_level_buff_map.is_empty())
	BuffManager.buff_map.clear()

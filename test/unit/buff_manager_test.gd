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

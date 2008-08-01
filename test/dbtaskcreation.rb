module DBTaskCreation

  def create_timed_db_tasks(old_task, *new_tasks)
    return if Meta.exist?(old_task) && new_tasks.all? { |new_task| File.exist?(new_task) }
    old_time = create_task(old_task)
    new_tasks.each do |new_task|
      while create_task(new_task) <= old_time + 1
        sleep(0.5)
        Meta.find_by_task(new_task.to_s).destroy rescue nil
      end
    end
  end

  def create_task(name)
    meta_record = Meta.find_by_task(name)
    if meta_record.nil?
      meta_record = Meta.new(:task => name.to_s)
      meta_record.save!
    end
    return meta_record.updated_at
  end

  def delete_task(name)
    Meta.find_by_task(name.to_s).destroy rescue nil
  end
end
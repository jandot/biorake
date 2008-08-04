module DataTaskCreation

  def create_timed_data_tasks(old_task, *new_tasks)
    return if Meta.exist?(old_task) && new_tasks.all? { |new_task| File.exist?(new_task) }

    old_time = create_task(old_task)
    new_tasks.each do |new_task|
      while create_task(new_task) <= old_time + 0.00001
        sleep(0.5)
        Meta.first(:task => new_task.to_s).destroy rescue nil
      end
    end
  end

  def create_task(name)
    meta_record = Meta.first(:task => name.to_s)
    if meta_record.nil?
      meta_record = Meta.new(:task => name.to_s)
    end
    meta_record.save
    return meta_record.updated_at
  end

  def delete_task(name)
    Meta.first(:task => name.to_s).destroy rescue nil
  end
end

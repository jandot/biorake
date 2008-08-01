module DBTaskCreation

  def create_timed_db_tasks(old_task, *new_tasks)
    return if Meta.exist?(old_task) && new_tasks.all? { |new_task| File.exist?(new_task) }

#    old_time = create_task(old_task)
#    a = create_task(new_task)
#    while a <= (old_time + 1)
#      sleep(0.5)
#      Meta.first(:task => new_task.to_s).destroy! rescue nil
#    end
    
    old_time = create_task(old_task)
#    STDERR.puts "DEBUG 05: " + old_time.class.to_s
    new_tasks.each do |new_task|
      while create_task(new_task) <= old_time + 1
        sleep(0.5)
        Meta.first(:task => new_task.to_s).destroy! rescue nil
#        STDERR.puts "DEBUG 20: " + a.class.to_s
      end
    end
  end

  def create_task(name)
    meta_record = Meta.first(:task => name.to_s)
    if meta_record.nil?
      meta_record = Meta.new(:task => name.to_s)
    end
    STDERR.puts meta_record.updated_at
    return meta_record.updated_at
  end

  def delete_task(name)
    Meta.first(:task => name.to_s).destroy! rescue nil
  end
end

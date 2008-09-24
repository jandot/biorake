module EventTaskCreation

  def create_timed_event_tasks(old_task, *new_tasks)
    return if File.exist?(".rake/"+old_task.to_s) && new_tasks.all? { |new_task| File.exist?(new_task) }

    old_time = create_task(old_task)
    new_tasks.each do |new_task|
      while create_task(new_task) <= old_time + 0.00001
        sleep(0.5)
        delete_task(new_task.to_s)
      end
    end
  end

  def create_task(name)
    Rake::EventTask.touch(name.to_s)
    return File.mtime(".rake/"+name.to_s)
  end

  def delete_task(name)
    File.delete(".rake/"+name.to_s) rescue nil
  end
end

module TmpDirectory
  def within_tmp_directory(delete_if_exists: false, path: 'tmp', debug: false)
    create_tmp_directory(delete_if_exists: delete_if_exists, path: path)

    Dir.chdir path do
      yield if block_given?
    end

    remove_tmp_directory(path) unless debug
  end

  def create_tmp_directory(delete_if_exists: false, path: 'tmp')
    if path == 'tmp'
      tmp_path = File.join(FileUtils.pwd, path)
    else
      tmp_path = path
    end
    if delete_if_exists
      remove_tmp_directory(tmp_path)
    end

    FileUtils.mkdir_p tmp_path
    tmp_path
  end

  def remove_tmp_directory(tmp_path)
    FileUtils.rm_rf tmp_path
  end
end

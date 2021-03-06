require File.join(File.dirname(__FILE__), '..', 'vcsrepo')

Puppet::Type.type(:vcsrepo).provide(:svn, :parent => Puppet::Provider::Vcsrepo) do
  desc "Supports Subversion repositories"

  commands :svn      => 'svn',
           :svnadmin => 'svnadmin'

  defaultfor :svn => :exists
  has_features :filesystem_types, :reference_tracking, :repo_auth

  def create
    if !@resource.value(:source)
      create_repository(@resource.value(:path))
    else
      checkout_repository(@resource.value(:source),
                          @resource.value(:path),
                          @resource.value(:revision))
    end
  end

  def working_copy_exists?
    File.directory?(File.join(@resource.value(:path), '.svn'))
  end

  def exists?
    working_copy_exists?
  end

  def default_svn_args
    args = ['--non-interactive', '--trust-server-cert']
    if @resource.value(:username)
      args.push('--username', @resource.value(:username))
    end
    if @resource.value(:password)
      args.push('--password', @resource.value(:password))
    end
    args    
  end
  
  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end

  def latest?
    at_path do
      if self.revision < self.latest then
        return false
      else
        return true
      end
    end
  end

  def latest
    at_path do
      args = default_svn_args
      args.push('info', '-r', 'HEAD')
      svn(*args)[/^Revision:\s+(\d+)/m, 1]
    end
  end
  
  def revision
    at_path do
      args = default_svn_args
      args << 'info'
      svn(*args)[/^Revision:\s+(\d+)/m, 1]
    end
  end

  def revision=(desired)
    at_path do
      args = default_svn_args
      args.push('update', '-r', desired)
      svn(*args)
    end
  end

  private

  def checkout_repository(source, path, revision = nil)
    args = default_svn_args
    args << 'checkout'
    if revision
      args.push('-r', revision)
    end
    args.push(source, path)
    svn(*args)
  end

  def create_repository(path)
    args = ['create']
    if @resource.value(:fstype)
      args.push('--fs-type', @resource.value(:fstype))
    end
    args << path
    svnadmin(*args)
  end

end

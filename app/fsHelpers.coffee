fs = require('fs')
path = require('path')
sys = require('sys')
exec = require('child_process').exec
q = require('q')

module.exports =
  # console/shell related, should probably go in their own module
  sysRunConsoleCommand: (options)->
    command = options.command
    dir = options.dir || '.'
    deferred = q.defer()
    
    if command.match /^cd\s/
      newDir = command.replace(/^cd\s/, '')
      resolvedPath = path.resolve(dir, newDir)
      if fs.existsSync(resolvedPath)
        deferred.resolve({stdout: '', dir: resolvedPath})
      else
        deferred.resolve({stdout: '', stderr: "#{resolvedPath} does not exist", err: '', dir: dir})
    else
    exec command, {cwd: dir}, (err, stdout, stderr)->
      deferred.resolve({stdout: stdout, stderr: stderr, err: err, dir: dir})
    
    deferred.promise
  
  # File system
  fsSaveFileBuffer: (options)->
    fs.writeFileSync(options.path, options.contents)
  
  fsReadFile: (filePath)->
    fs.readFileSync(filePath, 'utf-8')
  
  fsGetDirectoryTree: (dir) ->
    fileObj = {}
    files = fs.readdirSync(dir)

    for i of files
      continue  unless files.hasOwnProperty(i)
      name = dir + "/" + files[i]
      fileObj[files[i]] = {};
      fileObj[files[i]].path = name
      fileObj[files[i]].name = files[i]

      if fs.statSync(name).isDirectory()
        fileObj[files[i]].type = 'directory'
        fileObj[files[i]].files = this.fsGetDirectoryTree name
      else
        fileObj[files[i]].type = 'file'
    fileObj
    

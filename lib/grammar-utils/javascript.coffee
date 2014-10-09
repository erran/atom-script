module.exports =
  isJasmineSpec: (filename) ->
    return false unless filename

    filename.match /\.spec\.js$/
